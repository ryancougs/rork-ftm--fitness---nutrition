//
//  AppInfo.swift
//  FTMFitnessNutrition
//

import Foundation

/// One place for the app's user-facing name and version, so every screen
/// says the same thing.
enum AppInfo {
    nonisolated static let name = "FTM: Fitness & Nutrition"

    nonisolated static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}
