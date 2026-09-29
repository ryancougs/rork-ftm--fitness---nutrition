//
//  PrepView.swift
//  FTMFitnessNutrition
//

import SwiftUI
import StoreKit

/// The Prep Team tab: the membership paywall for free users, and a
/// members-only hub (premium coach updates, subscription management)
/// once the `ftm_pro` entitlement is active.
struct PrepView: View {
    @Environment(AppModel.self) private var app
    @Environment(StoreService.self) private var store
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            Group {
                if store.isPremiumPlus {
                    memberHub
                } else {
                    ScrollView {
                        PaywallContentView(context: .prepTeam)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                    }
                }
            }
            .background(TF.bg.ignoresSafeArea())
            .navigationTitle("Prep Team")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Member hub

    private var memberHub: some View {
        ScrollView {
            VStack(spacing: 18) {
                welcomeCard
                perksCard
                if !premiumUpdates.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        TFSectionHeader(title: "Members-only updates", subtitle: "From Mason, for the Prep Team")
                        ForEach(premiumUpdates) { update in
                            premiumUpdateCard(update)
                        }
                    }
                }
                manageCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .refreshable {
            await store.refreshEntitlements()
        }
    }

    private var premiumUpdates: [CoachUpdate] {
        app.coachUpdates.filter { $0.isPremium }
    }

    private var welcomeCard: some View {
        TFHeroBanner {
            VStack(spacing: 10) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                Text("You're on the Prep Team")
                    .font(.title2.weight(.bold))
                Text("Everything members-only is unlocked across the app — including Mason's locked updates in the Coach tab.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var perksCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            TFSectionHeader(title: "Your membership")
            VStack(alignment: .leading, spacing: 10) {
                perkRow("checkmark.seal.fill", "All members-only coach updates, unlocked")
                perkRow("calendar.badge.checkmark", "Full 12-month contest prep programming")
                perkRow("person.2.wave.2.fill", "White-glove coaching and check-in reviews")
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: TF.cornerM).fill(TF.card))
        }
    }

    private func perkRow(_ icon: String, _ text: String) -> some View {
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

    private func premiumUpdateCard(_ update: CoachUpdate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(update.category.emoji) \(update.category.rawValue)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(TF.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(TF.blue.opacity(0.14)))
                Spacer()
                Text(update.date.relativeDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(update.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(TF.text)
            Text(update.body)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: TF.cornerM).fill(TF.card))
    }

    private var manageCard: some View {
        VStack(spacing: 12) {
            Button {
                openURL(URL(string: "itms-apps://apps.apple.com/account/subscriptions")!)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                    Text("Manage subscription")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(TF.blue)

            Link(destination: URL(string: "https://2gxfo9qxolcyjgbzbeaoj-web.rork.live/support")!) {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle.fill")
                    Text("Support")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(TF.blue)

            Text("Payment is charged to your Apple ID. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: TF.cornerM).fill(TF.card))
    }
}
