//
//  StoreService.swift
//  FTMFitnessNutrition
//

import Foundation
import RevenueCat

/// Owns the RevenueCat connection and Prep Team membership state.
///
/// The paywall renders the RevenueCat "default" (current) offering.
/// Purchases unlock the `ftm_pro` entitlement, which reveals premium
/// Coach updates and the bodybuilding prep section.
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

    /// Entitlement id in RevenueCat that unlocks Prep Team content.
    static let entitlementID = "ftm_pro"

    /// Offering identifier used as a fallback when no "current" offering is set.
    static let defaultOfferingID = "default"

    private(set) var isPremium: Bool = false
    private(set) var currentOffering: Offering?
    private(set) var isLoadingOffering: Bool = false

    var isConfigured: Bool { !Self.apiKey.isEmpty && Purchases.isConfigured }

    private init() {}

    /// Call once at app launch. No-op until an API key is set.
    func configure() {
        guard !Self.apiKey.isEmpty, !Purchases.isConfigured else { return }
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: Self.apiKey)
        Task { await refreshEntitlements() }
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

    private func apply(_ info: CustomerInfo) {
        isPremium = info.entitlements[Self.entitlementID]?.isActive == true
    }
}
