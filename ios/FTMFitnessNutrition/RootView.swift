//
//  RootView.swift
//  FTMFitnessNutrition
//

import SwiftUI

/// Top-level view that gates between auth, intake, and the main app.
struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var app = app
        ZStack {
            if app.isRestoringSession {
                splashView
            } else {
                switch app.session {
                case .unauthenticated:
                    AuthView()
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                case .needsIntake:
                    IntakeView()
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                case .ready:
                    MainTabView()
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: app.isRestoringSession)
        .task { await app.handleAppLaunch() }
    }

    /// Brief branded splash while the cloud session restores at launch.
    private var splashView: some View {
        VStack(spacing: 18) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
            ProgressView()
                .tint(TF.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TF.bg.ignoresSafeArea())
    }
}

#Preview {
    RootView().environment(AppModel())
}
