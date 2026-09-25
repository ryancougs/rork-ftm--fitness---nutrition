//
//  MainTabView.swift
//  FTMFitnessNutrition
//

import SwiftUI
import UIKit

/// Bottom navigation across Home, Train, Nutrition, Community, Coach, and
/// Prep Team. A custom bar keeps all six tabs visible on every screen size
/// (the system bar would collapse the 6th into "More"). Selection lives in
/// AppModel so screens can deep-link between tabs; all tab views stay alive
/// so scroll position and state survive switching.
struct MainTabView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        ZStack {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabContent(tab)
                    .opacity(app.selectedTab == tab ? 1 : 0)
                    .allowsHitTesting(app.selectedTab == tab)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TF.bg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) { tabBar }
        .tint(TF.blue)
        .animation(.easeInOut(duration: 0.15), value: app.selectedTab)
    }

    @ViewBuilder
    private func tabContent(_ tab: AppTab) -> some View {
        switch tab {
        case .home: HomeView()
        case .train: TrainView()
        case .eat: NutritionView()
        case .community: CommunityView()
        case .coach: CoachView()
        case .prep: PrepView()
        }
    }

    // MARK: Custom tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(
            TF.card
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(TF.border)
                        .frame(height: 0.5)
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
            VStack(spacing: 3) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 19, weight: .semibold))
                    .frame(height: 22)
                Text(tab.label)
                    .font(.system(size: 9, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 5)
            .foregroundStyle(isSelected ? TF.blue : TF.textSecondary)
            .overlay(alignment: .top) {
                Capsule()
                    .fill(isSelected ? TF.blue : Color.clear)
                    .frame(width: 28, height: 3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    MainTabView().environment(AppModel())
}
