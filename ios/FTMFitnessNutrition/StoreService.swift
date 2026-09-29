//
//  StoreService.swift
//  FTMFitnessNutrition
//

import Foundation
import RevenueCat

/// Owns the RevenueCat connection and the three-tier subscription state.
///
/// This is the single source of truth for entitlements — every gated feature
/// reads `tier`/`isPremium`/`isPremiumPlus` from here (the SwiftUI equivalent
/// of a useSubscription() hook; `@Observable` keeps views reactive).
///
/// Entitlements in RevenueCat:
/// - `premium`      → SubscriptionTier.premium
/// - `premium_plus` → SubscriptionTier.premiumPlus (also passes every premium check)
/// - `ftm_pro`      → legacy Prep Team membership, grandfathered to premiumPlus
@MainActor
@Observable
final class StoreService {
    static let shared = StoreService()

    /// RevenueCat public SDK key — safe to embed in the client.
    /// Development builds use the Test Store key; App Store releases use the Apple key.
    static var apiKey: String {
        #if DEBUG
        return Config.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY
        #else
        return Config.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY
        #endif
    }

    // MARK: Entitlement & package identifiers (must match the RevenueCat dashboard)

    static let premiumEntitlementID = "premium"
    static let premiumPlusEntitlementID = "premium_plus"
    /// Pre-restructure single-tier membership. Active subscribers keep everything.
    static let legacyEntitlementID = "ftm_pro"

    static let defaultOfferingID = "default"
    static let premiumMonthlyID = "premium_monthly"
    static let premiumAnnualID = "premium_annual"
    static let plusMonthlyID = "plus_monthly"
    static let plusAnnualID = "plus_annual"

    // MARK: State

    private(set) var tier: SubscriptionTier = .free
    private(set) var currentOffering: Offering?
    private(set) var isLoadingOffering: Bool = false
    /// e.g. "Renews Jun 12" / "Expires Jun 12" — nil on the free tier.
    private(set) var renewalSummary: String?

    var isPremium: Bool { tier != .free }
    var isPremiumPlus: Bool { tier == .premiumPlus }
    var isConfigured: Bool { !Self.apiKey.isEmpty && Purchases.isConfigured }

    /// Unprompted paywalls (e.g. the post-onboarding soft offer) show at most
    /// once per session. Contextual paywalls opened by gated taps are unlimited.
    private(set) var hasShownAutoPaywallThisSession: Bool = false
    var canShowAutoPaywall: Bool { isConfigured && !isPremium && !hasShownAutoPaywallThisSession }
    func markAutoPaywallShown() { hasShownAutoPaywallThisSession = true }

    private var infoStreamTask: Task<Void, Never>?

    private init() {}

    // MARK: Lifecycle

    /// Call once at app launch. No-op until an API key is set.
    func configure() {
        guard !Self.apiKey.isEmpty, !Purchases.isConfigured else { return }
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: Self.apiKey)
        // Live entitlement stream: unlocks (and downgrades/cancellations) apply
        // instantly after a purchase, restore, or renewal — no manual refresh.
        infoStreamTask = Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                self?.apply(info)
            }
        }
        Task { await refreshEntitlements() }
    }

    /// Manual refresh, exposed like useSubscription()'s refresh().
    func refresh() async {
        await refreshEntitlements()
    }

    /// Fetches the "default" offering from RevenueCat.
    func loadOffering() async {
        guard Purchases.isConfigured else { return }
        isLoadingOffering = true
        defer { isLoadingOffering = false }
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current ?? offerings.offering(identifier: Self.defaultOfferingID)
        } catch {
            print("Offerings load failed: \(error.localizedDescription)")
        }
    }

    // MARK: Packages

    private func package(withIdentifier id: String) -> Package? {
        guard let offering = currentOffering else { return nil }
        return offering.package(identifier: id)
            ?? offering.availablePackages.first { $0.identifier == id }
    }

    /// First identifier wins; standard RevenueCat package types are the
    /// fallback so the paywall still works before custom packages are wired up.
    private func package(identifiers: [String], fallbackTypes: [PackageType] = []) -> Package? {
        for id in identifiers {
            if let p = package(withIdentifier: id) { return p }
        }
        for type in fallbackTypes {
            if let p = currentOffering?.availablePackages.first(where: { $0.packageType == type }) {
                return p
            }
        }
        return nil
    }

    var premiumMonthlyPackage: Package? {
        package(identifiers: [Self.premiumMonthlyID], fallbackTypes: [.monthly])
    }

    var premiumAnnualPackage: Package? {
        package(identifiers: [Self.premiumAnnualID], fallbackTypes: [.annual])
    }

    var plusMonthlyPackage: Package? {
        package(identifiers: [Self.plusMonthlyID])
    }

    var plusAnnualPackage: Package? {
        package(identifiers: [Self.plusAnnualID])
    }

    /// Premium+ cards only render when its packages exist in the offering.
    var hasPlusPackages: Bool { plusMonthlyPackage != nil || plusAnnualPackage != nil }

    // MARK: Purchase / restore

    /// Starts a purchase. Returns true when the purchase completed (not cancelled).
    @discardableResult
    func purchase(_ package: Package) async -> Bool {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            apply(result.customerInfo)
            return !result.userCancelled
        } catch {
            print("Purchase failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Restores previous purchases on this Apple ID.
    @discardableResult
    func restore() async -> Bool {
        do {
            let info = try await Purchases.shared.restorePurchases()
            apply(info)
            return true
        } catch {
            print("Restore failed: \(error.localizedDescription)")
            return false
        }
    }

    func refreshEntitlements() async {
        guard Purchases.isConfigured else { return }
        do {
            apply(try await Purchases.shared.customerInfo())
        } catch {
            print("CustomerInfo fetch failed: \(error.localizedDescription)")
        }
    }

    // MARK: Entitlement mapping

    private func apply(_ info: CustomerInfo) {
        if info.entitlements[Self.premiumPlusEntitlementID]?.isActive == true {
            tier = .premiumPlus
        } else if info.entitlements[Self.premiumEntitlementID]?.isActive == true {
            tier = .premium
        } else if info.entitlements[Self.legacyEntitlementID]?.isActive == true {
            // Legacy Prep Team members keep full Premium+ access.
            tier = .premiumPlus
        } else {
            tier = .free
        }
        updateRenewalSummary(from: info)
    }

    private func updateRenewalSummary(from info: CustomerInfo) {
        guard tier != .free else {
            renewalSummary = nil
            return
        }
        let active = info.entitlements.active.values
        let willRenew = active.contains { $0.willRenew }
        let latest = active
            .compactMap { $0.expirationDate }
            .max()
        guard let latest else {
            renewalSummary = nil
            return
        }
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        renewalSummary = willRenew ? "Renews \(df.string(from: latest))" : "Expires \(df.string(from: latest))"
    }
}
