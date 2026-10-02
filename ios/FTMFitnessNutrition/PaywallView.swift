//
//  PaywallView.swift
//  FTMFitnessNutrition
//

import SwiftUI
import RevenueCat

/// Two-tier paywall (Free / Premium).
///
/// - Monthly/Annual toggle with annual preselected and a computed savings badge
/// - One Premium card using premium_monthly / premium_annual
/// - Every price comes from RevenueCat package data (localized) — never hardcoded
/// - Trial copy from the package's introductory offer ("7 days free, then …")
/// - Restore Purchases + Terms/Privacy links (App Store requirement)
/// - Optional `context` headline so gated taps open the paywall mid-story
struct PaywallView: View {
    var context: PaywallContext? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                PaywallContentView(context: context, onPurchased: { dismiss() })
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
            }
            .background(TF.bg.ignoresSafeArea())
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TF.blue)
                }
            }
        }
    }
}

/// The paywall body, shared by the sheet and the post-onboarding offer.
struct PaywallContentView: View {
    var context: PaywallContext? = nil
    var onPurchased: () -> Void = {}

    @Environment(StoreService.self) private var store

    private enum Period { case monthly, annual }

    @State private var period: Period = .annual
    @State private var isPurchasing: Bool = false
    @State private var isRestoring: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    @State private var showRestoreResult: Bool = false

    // MARK: Package resolution

    private var selectedPackage: Package? {
        switch period {
        case .monthly: return store.premiumMonthlyPackage
        case .annual: return store.premiumAnnualPackage
        }
    }

    private var hasAnyPackages: Bool {
        store.premiumMonthlyPackage != nil || store.premiumAnnualPackage != nil
    }

    /// Annual savings vs 12 × monthly, from live RevenueCat prices.
    private var annualSavingsPercent: Int? {
        guard let monthlyPackage = store.premiumMonthlyPackage?.storeProduct.price,
              let annualPackage = store.premiumAnnualPackage?.storeProduct.price else { return nil }
        let monthly = NSDecimalNumber(decimal: monthlyPackage).doubleValue
        let annual = NSDecimalNumber(decimal: annualPackage).doubleValue
        let full = monthly * 12
        guard full > 0, annual > 0, annual < full else { return nil }
        return Int(((1 - annual / full) * 100).rounded())
    }

    /// "7 days free, then $49.99/year. Cancel anytime." — built from the
    /// package's introductory offer so wording always matches the store data.
    private var trialLine: String? {
        guard let package = selectedPackage else { return nil }
        let product = package.storeProduct
        guard let intro = product.introductoryDiscount,
              intro.paymentMode == .freeTrial else { return nil }
        let value = intro.subscriptionPeriod.value
        let unitWord: String
        switch intro.subscriptionPeriod.unit {
        case .day: unitWord = value == 1 ? "day" : "days"
        case .week: unitWord = value == 1 ? "week" : "weeks"
        case .month: unitWord = value == 1 ? "month" : "months"
        case .year: unitWord = value == 1 ? "year" : "years"
        @unknown default: unitWord = "days"
        }
        let cycleWord = product.subscriptionPeriod?.unit == .year ? "year" : "month"
        return "\(value) \(unitWord) free, then \(product.localizedPriceString)/\(cycleWord). Cancel anytime."
    }

    var body: some View {
        VStack(spacing: 16) {
            if let context {
                contextCard(context)
            }
            header
            if store.isPremium {
                memberState
            } else if !store.isConfigured {
                setupState
            } else if !hasAnyPackages {
                loadingState
            } else {
                periodToggle
                planCard
                if let trialLine {
                    Text(trialLine)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(TF.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
                purchaseButton
            }
            restoreButton
            legalFooter
        }
        .task {
            if store.currentOffering == nil { await store.loadOffering() }
            await store.refreshEntitlements()
            pickDefaultsIfNeeded()
        }
        .alert("Something went wrong", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
        .alert("Restore complete", isPresented: $showRestoreResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.isPremium
                 ? "Welcome back — \(store.tier.displayName) is active on this Apple ID."
                 : "No previous subscription was found on this Apple ID.")
        }
    }

    private func pickDefaultsIfNeeded() {
        if store.premiumAnnualPackage == nil { period = .monthly }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 6) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
            Text("TransFit Premium")
                .font(.title2.weight(.bold))
            Text("No ads, ever. Your data stays yours. Upgrade when you're ready for more.")
                .font(.subheadline)
                .foregroundStyle(TF.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func contextCard(_ context: PaywallContext) -> some View {
        TFCard(background: TF.blue.opacity(0.12)) {
            VStack(spacing: 4) {
                Text(context.headline)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(TF.text)
                    .multilineTextAlignment(.center)
                if !context.message.isEmpty {
                    Text(context.message)
                        .font(.footnote)
                        .foregroundStyle(TF.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Period toggle

    private var periodToggle: some View {
        HStack(spacing: 8) {
            periodButton(.monthly, title: "Monthly", badge: nil)
            periodButton(.annual, title: "Annual", badge: annualSavingsPercent.map { "Save \($0)%" })
        }
    }

    private func periodButton(_ value: Period, title: String, badge: String?) -> some View {
        let isSelected = period == value
        return Button {
            withAnimation(.spring(response: 0.25)) { period = value }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                if let badge {
                    Text(badge)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(isSelected ? TF.bg.opacity(0.25) : TF.blue.opacity(0.16)))
                }
            }
            .foregroundStyle(isSelected ? TF.bg : TF.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Capsule().fill(isSelected ? TF.blue : TF.input))
            .overlay(Capsule().strokeBorder(isSelected ? TF.blue : TF.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Plan card

    private var planCard: some View {
        let package = selectedPackage
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "star.fill")
                    .foregroundStyle(TF.blue)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Premium")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(TF.text)
                    Text("Core tools to train and fuel consistently")
                        .font(.caption)
                        .foregroundStyle(TF.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(package.map { $0.storeProduct.localizedPriceString } ?? "—")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(TF.text)
                    Text(period == .annual ? "per year" : "per month")
                        .font(.caption2)
                        .foregroundStyle(TF.textSecondary)
                }
            }
            if period == .annual, let package {
                Text(perMonthCaption(package))
                    .font(.caption2)
                    .foregroundStyle(TF.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(alignment: .leading, spacing: 7) {
                ForEach(featureList, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(TF.blue)
                            .padding(.top, 2)
                        Text(feature)
                            .font(.footnote)
                            .foregroundStyle(TF.text)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: TF.cornerM).fill(TF.card))
        .overlay(
            RoundedRectangle(cornerRadius: TF.cornerM)
                .strokeBorder(TF.border, lineWidth: 1)
        )
    }

    private func perMonthCaption(_ package: Package) -> String {
        let product = package.storeProduct
        if product.subscriptionPeriod?.unit == .year {
            return "That's \(product.localizedPricePerMonth)/month"
        }
        return ""
    }

    private var featureList: [String] {
        [
            "Unlimited AI meal scans",
            "Barcode scanner + quick-add macros",
            "Custom calorie & macro goals",
            "Full history & progress analytics",
            "All workout programs & routines",
        ]
    }

    // MARK: Purchase / restore

    private var purchaseButton: some View {
        Button {
            purchaseSelected()
        } label: {
            HStack(spacing: 8) {
                if isPurchasing {
                    ProgressView()
                        .tint(TF.bg)
                } else {
                    Image(systemName: "lock.open.fill")
                }
                Text(ctaTitle)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(TF.blue)
        .foregroundStyle(TF.bg)
        .disabled(selectedPackage == nil || isPurchasing)
    }

    private var ctaTitle: String {
        guard let package = selectedPackage else { return "Continue" }
        if trialLine != nil { return "Start my free trial" }
        let word = package.storeProduct.subscriptionPeriod?.unit == .year ? "year" : "month"
        return "Subscribe — \(package.storeProduct.localizedPriceString)/\(word)"
    }

    private var restoreButton: some View {
        Button {
            isRestoring = true
            Task { @MainActor in
                await store.restore()
                isRestoring = false
                showRestoreResult = true
            }
        } label: {
            HStack(spacing: 6) {
                if isRestoring {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                Text("Restore purchases")
            }
            .font(.footnote.weight(.semibold))
        }
        .buttonStyle(.plain)
        .tint(TF.blue)
        .disabled(isRestoring)
        .padding(.top, 4)
    }

    private func purchaseSelected() {
        guard let package = selectedPackage else { return }
        isPurchasing = true
        Task { @MainActor in
            defer { isPurchasing = false }
            let completed = await store.purchase(package)
            if completed {
                if store.isPremium {
                    onPurchased()
                } else {
                    errorMessage = "The purchase went through but your plan hasn't activated yet. Try \"Restore purchases\" — if it still doesn't show, contact support."
                    showError = true
                }
            }
        }
    }

    // MARK: States

    private var memberState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 32))
                .foregroundStyle(TF.blue)
            Text("You're on \(store.tier.displayName)")
                .font(.headline)
                .foregroundStyle(TF.text)
            Text("Everything in your plan is unlocked. Thank you for backing TransFit.")
                .font(.footnote)
                .foregroundStyle(TF.textSecondary)
                .multilineTextAlignment(.center)
            if let renewal = store.renewalSummary {
                Text(renewal)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TF.blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 14)
        .background(RoundedRectangle(cornerRadius: TF.cornerM).fill(TF.card))
    }

    private var setupState: some View {
        VStack(spacing: 8) {
            Image(systemName: "hourglass")
                .font(.system(size: 28))
                .foregroundStyle(TF.blue)
            Text("Premium launching soon")
                .font(.headline)
                .foregroundStyle(TF.text)
            Text("We're finishing App Store setup for the new plans. Your free access stays untouched in the meantime.")
                .font(.footnote)
                .foregroundStyle(TF.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 14)
        .background(RoundedRectangle(cornerRadius: TF.cornerM).fill(TF.card))
    }

    private var loadingState: some View {
        VStack(spacing: 10) {
            ProgressView()
                .tint(TF.blue)
            Text(store.isLoadingOffering ? "Loading plans…" : "Plans aren't available right now. Reopen this page in a moment.")
                .font(.footnote)
                .foregroundStyle(TF.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 14)
        .background(RoundedRectangle(cornerRadius: TF.cornerM).fill(TF.card))
    }

    private var legalFooter: some View {
        VStack(spacing: 8) {
            Text("Payment is charged to your Apple ID. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period — manage or cancel anytime in your App Store settings.")
                .font(.caption2)
                .foregroundStyle(TF.textSecondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://2gxfo9qxolcyjgbzbeaoj-web.rork.live/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://2gxfo9qxolcyjgbzbeaoj-web.rork.live/privacy")!)
            }
            .font(.caption2.weight(.semibold))
            .tint(TF.blue)
        }
        .padding(.top, 6)
    }
}
