//
//  AppInfo.swift
//  FTMFitnessNutrition
//

import Foundation

/// One place for the app's user-facing name and version, so every screen
/// says the same thing.
enum AppInfo {
    nonisolated static let name = "FTM: Fitness & Nutrition"

    nonisolated static let termsURL = URL(string: "https://2gxfo9qxolcyjgbzbeaoj-web.rork.live/terms")!
    nonisolated static let privacyURL = URL(string: "https://2gxfo9qxolcyjgbzbeaoj-web.rork.live/privacy")!

    /// Where people locked out of their account can reach a person.
    nonisolated static let supportEmail = "ryan.coughlin@hotmail.com"

    /// Off until Supabase has a custom email sender (custom SMTP on a real
    /// domain). Without one, Supabase can't put the reset code in the email
    /// and only delivers to the project team, so testers would never get it.
    /// While off, "Forgot password" asks people to email support instead.
    /// Flip to true once SMTP is set up and the Reset Password template
    /// includes {{ .Token }}.
    nonisolated static let selfServePasswordReset = false

    nonisolated static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}
