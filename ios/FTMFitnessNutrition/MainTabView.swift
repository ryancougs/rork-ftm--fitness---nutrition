//
//  MainTabView.swift
//  FTMFitnessNutrition
//

import SwiftUI
import UIKit

/// Bottom navigation across Home, Train, Nutrition, Community, and Profile.
/// A custom bar keeps all five tabs visible on every screen size. Selection
/// lives in AppModel so screens can deep-link between tabs; all tab views
/// stay alive so scroll position and state survive switching.
struct MainTabView: View {
    @Environment(AppModel.self) private var app
    @Environment(StoreService.self) private var store

    var body: some View {
        @Bindable var app = app
        // The tab content and the custom bar are stacked, not overlaid: a
        // safeAreaInset on the TabView doesn't reach the scroll views inside
        // each tab's NavigationStack, so the last card on every screen used
        // to scroll in behind the bar. Stacking gives each tab a frame that
        // ends exactly at the top of the bar.
        VStack(spacing: 0) {
            TabView(selection: $app.selectedTab) {
                // The custom bar below replaces the system one; hide the system
                // bar so an empty strip doesn't sit under it on device.
                HomeView().tag(AppTab.home).toolbar(.hidden, for: .tabBar)
                TrainView().tag(AppTab.train).toolbar(.hidden, for: .tabBar)
                NutritionView().tag(AppTab.eat).toolbar(.hidden, for: .tabBar)
                CommunityView().tag(AppTab.community).toolbar(.hidden, for: .tabBar)
                ProfileView().tag(AppTab.profile).toolbar(.hidden, for: .tabBar)
            }
            tabBar
        }
        .background(TF.bg.ignoresSafeArea())
        .tint(TF.blue)
        // Dismissible soft offer right after onboarding completes — shown at
        // most once per session (the store caps unprompted paywalls).
        .sheet(isPresented: $app.showPostOnboardingPaywall) {
            PaywallView(context: .postOnboarding)
                .onAppear { store.markAutoPaywallShown() }
        }
        // Ask for notification permission once the user is in the app and
        // no paywall is covering it, instead of on the launch splash.
        .task(id: app.showPostOnboardingPaywall) {
            guard !app.showPostOnboardingPaywall, app.checkInRemindersOn else { return }
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            await CheckInReminder.requestAndSchedule()
        }
    }

    // MARK: Custom tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            TF.bg
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(TF.input)
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = app.selectedTab == tab
        return Button {
            guard app.selectedTab != tab else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.15)) { app.selectedTab = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(height: 24)
                Text(tab.label)
                    .font(.system(size: 11, weight: isSelected ? .bold : .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
            .contentShape(Rectangle())
            .foregroundStyle(isSelected ? TF.text : TF.textSecondary.opacity(0.8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    MainTabView()
        .environment(AppModel())
        .environment(StoreService.shared)
}
