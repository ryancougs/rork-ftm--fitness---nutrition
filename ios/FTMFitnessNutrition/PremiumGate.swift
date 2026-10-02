//
//  PremiumGate.swift
//  FTMFitnessNutrition
//

import SwiftUI

/// The two subscription tiers. Free users get logging and three AI meal
/// scans a week; Premium unlocks everything else.
enum SubscriptionTier: Int, Comparable, CaseIterable {
    case free = 0
    case premium = 1

    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .free: "Free"
        case .premium: "Premium"
        }
    }

    var icon: String {
        switch self {
        case .free: "person.crop.circle"
        case .premium: "star.fill"
        }
    }
}

/// Why the paywall is opening — shown as the paywall's headline so upgrades
/// always feel contextual ("you've used your scans") rather than random.
struct PaywallContext: Equatable {
    var headline: String
    var message: String

    init(headline: String, message: String = "") {
        self.headline = headline
        self.message = message
    }
}

/// SwiftUI equivalent of `<PremiumGate requiredTier="premium">`: renders
/// `unlocked` when the user's tier qualifies, otherwise `locked`.
struct PremiumGate<Unlocked: View, Locked: View>: View {
    @Environment(StoreService.self) private var store

    let requiredTier: SubscriptionTier
    @ViewBuilder var unlocked: () -> Unlocked
    @ViewBuilder var locked: () -> Locked

    var body: some View {
        if store.tier >= requiredTier {
            unlocked()
        } else {
            locked()
        }
    }
}

/// Button that runs the gated action when the tier qualifies, or opens the
/// paywall (with context) when it doesn't. Keeps entitlement decisions out of
/// feature code — no view checks `store.tier` directly.
struct GatedButton<Label: View>: View {
    @Environment(StoreService.self) private var store

    let requiredTier: SubscriptionTier
    let context: PaywallContext
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var showingPaywall = false

    var body: some View {
        Button {
            if store.tier >= requiredTier {
                action()
            } else {
                showingPaywall = true
            }
        } label: {
            label()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(context: context)
        }
    }
}

/// Locked-state card shown in place of gated content: icon, copy, and an
/// upgrade button that opens the paywall with this feature's context.
struct LockedFeatureCard: View {
    var icon: String = "lock.fill"
    let title: String
    let message: String
    var buttonTitle: String = "Upgrade to Premium"
    let context: PaywallContext

    @State private var showingPaywall = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(TF.blue.opacity(0.14))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(TF.blue)
            }
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(TF.text)
            Text(message)
                .font(.footnote)
                .foregroundStyle(TF.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            TFButton(title: buttonTitle, systemImage: "lock.open.fill", style: .primary) {
                showingPaywall = true
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: TF.cornerM).fill(TF.card))
        .overlay(
            RoundedRectangle(cornerRadius: TF.cornerM)
                .strokeBorder(TF.border, lineWidth: 1)
        )
        .sheet(isPresented: $showingPaywall) {
            PaywallView(context: context)
        }
    }
}

// MARK: - Paywall contexts (copy shown when each feature's gate opens the paywall)

extension PaywallContext {
    static let barcodeScanner = PaywallContext(
        headline: "The barcode scanner is part of Premium",
        message: "Scan any packaged food and log it in seconds — unlimited.")
    static let quickAdd = PaywallContext(
        headline: "Quick add is part of Premium",
        message: "Log calories and macros directly, no food lookup needed.")
    static let customGoals = PaywallContext(
        headline: "Custom goals are part of Premium",
        message: "Set your own calorie and macro targets.")
    static let programs = PaywallContext(
        headline: "Programs are part of Premium",
        message: "Unlock every workout program and routine.")
    static let fullHistory = PaywallContext(
        headline: "Full history is part of Premium",
        message: "See every trend — weight, macros, and strength — with unlimited lookback.")
    static let scanLimit = PaywallContext(
        headline: "You've used your free scans this week",
        message: "Go unlimited with Premium — plus the barcode scanner and custom goals.")
    static let postOnboarding = PaywallContext(
        headline: "You're all set up",
        message: "Premium unlocks unlimited AI meal scans, the barcode scanner, and custom goals. Free logging stays free — no ads, ever.")
    static let coachUpdates = PaywallContext(
        headline: "Mason's premium updates are part of Premium",
        message: "Unlock every locked coach update, plus unlimited AI meal scans and the barcode scanner.")
}
