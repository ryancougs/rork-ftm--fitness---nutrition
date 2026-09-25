//
//  PaywallView.swift
//  FTMFitnessNutrition
//

import SwiftUI
import RevenueCat

/// Paywall for the Prep Team bodybuilding membership.
///
/// Renders the packages of the RevenueCat "default" (current) offering —
/// monthly and yearly — with purchase, restore, and graceful states for
/// store setup in progress. The shared content is also embedded in the
/// Prep Team tab (see `PrepView`).
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                PaywallContentView(onPurchased: { dismiss() })
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
            }
            .background(TF.bg.ignoresSafeArea())
            .navigationTitle("Prep Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

/// The paywall body shared by the Coach sheet and the Prep Team tab.
/// Calls `onPurchased` after a successful activation (the sheet dismisses;
/// the tab just re-renders into the member hub).
struct PaywallContentView: View {
    var onPurchased: () -> Void = {}

    @Environment(StoreService.self) private var store

    @State private var selectedPackage: Package?
    @State private var isPurchasing: Bool = false
    @State private var isRestoring: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    @State private var showRestoreResult: Bool = false

    private let order: [PackageType] = [.monthly, .annual]

    private var packages: [Package] {
        guard let offering = store.currentOffering else { return [] }
        return offering.availablePackages
            .filter { order.contains($0.packageType) }
            .sorted {
                (order.firstIndex(of: $0.packageType) ?? .max) < (order.firstIndex(of: $1.packageType) ?? .max)
            }
    }

    var body: some View {
        VStack(spacing: 16) {
            header
            featureList
            if store.isPremium {
                memberState
            } else if !store.isConfigured {
                setupState
            } else if store.isLoadingOffering || packages.isEmpty {
                loadingState
            } else {
                packageCards
                purchaseButton
            }
            restoreButton
            legalFooter
        }
        .task {
            if store.currentOffering == nil { await store.loadOffering() }
            await store.refreshEntitlements()
            selectDefaultPackageIfNeeded()
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
                 ? "Welcome back — your Prep Team access is active."
                 : "No previous membership was found on this Apple ID.")
        }
    }

    // MARK: Header

    private var header: some View {
        TFHeroBanner {
            VStack(spacing: 10) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                Text("TransFit Prep Team")
                    .font(.title2.weight(.bold))
                Text("Your complete 12-month bodybuilding prep — coach programming, members-only updates, and white-glove support from Mason.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            TFSectionHeader(title: "What's included")
            VStack(alignment: .leading, spacing: 10) {
                featureRow("calendar.badge.checkmark", "Full 12-month contest prep programming")
                featureRow("person.2.wave.2.fill", "White-glove coaching and check-in reviews")
                featureRow("lock.open.fill", "All members-only coach updates, unlocked")
                featureRow("fork.knife", "Prep and off-season nutrition guidance")
                featureRow("figure.strengthtraining.traditional", "Training built for trans masculine bodies")
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: TF.cornerM).fill(TF.card))
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(TF.blue)
                .frame(width: 22)
            Text(text)
                .font(.footnote)
                .foregroundStyle(TF.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Packages

    private var packageCards: some View {
        VStack(spacing: 10) {
            ForEach(packages, id: \.identifier) { package in
                packageCard(package)
            }
        }
    }

    private func packageCard(_ package: Package) -> some View {
        let isSelected = selectedPackage?.identifier == package.identifier
        return Button {
            withAnimation(.spring(response: 0.25)) { selectedPackage = package }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? TF.blue : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title(for: package))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(TF.text)
                        if package.packageType == .annual {
                            badge("Best value", color: TF.blue)
                        }
                    }
                    Text(caption(for: package))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(package.storeProduct.localizedPriceString)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TF.text)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: TF.cornerM).fill(isSelected ? TF.blue.opacity(0.12) : TF.card))
            .overlay(
                RoundedRectangle(cornerRadius: TF.cornerM)
                    .strokeBorder(isSelected ? TF.blue : TF.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.14)))
    }

    private func title(for package: Package) -> String {
        switch package.packageType {
        case .monthly: return "Monthly"
        case .annual: return "Yearly"
        default: return package.storeProduct.localizedTitle
        }
    }

    private func caption(for package: Package) -> String {
        switch package.packageType {
        case .monthly:
            return "Flexible — cancel anytime"
        case .annual:
            if let perMonth = perMonthPrice(package.storeProduct) {
                return "12 months of full prep — that's \(perMonth)/month"
            }
            return "12 months of full prep"
        default:
            return package.storeProduct.localizedDescription
        }
    }

    /// Approximate per-month price shown on the yearly option.
    private func perMonthPrice(_ product: StoreProduct) -> String? {
        guard product.subscriptionPeriod?.unit == .year else { return nil }
        return product.localizedPricePerMonth
    }

    // MARK: Purchase / restore

    private var purchaseButton: some View {
        Button {
            purchaseSelected()
        } label: {
            HStack(spacing: 8) {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "lock.open.fill")
                }
                Text(isPurchasing ? "Processing…" : "Join the Prep Team")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(TF.blue)
        .disabled(selectedPackage == nil || isPurchasing)
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
                    errorMessage = "The purchase went through but your membership hasn't activated yet. Try \"Restore purchases\" — if it still doesn't show, contact support."
                    showError = true
                }
            }
        }
    }

    private func selectDefaultPackageIfNeeded() {
        guard selectedPackage == nil, !packages.isEmpty else { return }
        selectedPackage = packages.first { $0.packageType == .annual } ?? packages.first
    }

    // MARK: States

    private var memberState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 32))
                .foregroundStyle(TF.blue)
            Text("You're a Prep Team member")
                .font(.headline)
                .foregroundStyle(TF.text)
            Text("All members-only coach updates and the bodybuilding prep section are unlocked. Thank you for backing the team.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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
            Text("Membership launching soon")
                .font(.headline)
                .foregroundStyle(TF.text)
            Text("We're finishing App Store setup for the Prep Team. Check back shortly — your free access stays untouched in the meantime.")
                .font(.footnote)
                .foregroundStyle(.secondary)
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
            Text(store.isLoadingOffering ? "Loading membership options…" : "Membership options aren't available right now. Pull to reopen this page in a moment.")
                .font(.footnote)
                .foregroundStyle(.secondary)
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
                .foregroundStyle(.secondary)
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
