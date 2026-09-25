//
//  Theme.swift
//  FTMFitnessNutrition
//

import SwiftUI

/// Centralized design tokens for FTMFitnessNutrition.
/// Near-black canvas (#0B0B0F) with the trans light blue (#5BCEFA) as the
/// single action color. The trans pink (#F5A9B8) appears only as small
/// highlights and — together with blue — only in the logo and the one
/// subtle home-header gradient. Every color in the app resolves here.
enum TF {
    // MARK: Surfaces
    static let bg = Color(red: 0.043, green: 0.043, blue: 0.059)        // #0B0B0F canvas
    static let card = Color(red: 0.086, green: 0.086, blue: 0.114)      // #16161D elevated card
    static let input = Color(red: 0.122, green: 0.122, blue: 0.157)     // #1F1F28 fields, chips, rows
    static let border = Color(red: 0.165, green: 0.165, blue: 0.208)    // #2A2A35 hairlines & strokes

    // MARK: Accents
    static let blue = Color(red: 0.357, green: 0.808, blue: 0.980)      // #5BCEFA primary action
    static let pink = Color(red: 0.961, green: 0.663, blue: 0.722)      // #F5A9B8 small highlights only

    // MARK: Text
    static let text = Color.white
    static let textSecondary = Color(red: 0.627, green: 0.627, blue: 0.690) // #A0A0B0

    // MARK: Status
    static let success = Color(red: 0.290, green: 0.871, blue: 0.502)   // #4ADE80
    static let warning = Color(red: 0.984, green: 0.749, blue: 0.141)   // #FBBF24
    static let danger = Color(red: 0.973, green: 0.443, blue: 0.443)    // #F87171

    // MARK: Semantic aliases
    static let hunger = warning
    static let protein = success
    static let carbs = warning
    static let fat = pink
    static let cal = blue

    /// The single blue+pink gradient — used only on the home header (with the logo).
    static let accentGradient = LinearGradient(
        colors: [blue.opacity(0.16), pink.opacity(0.09)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Spacing scale (4 / 8 / 12 / 16 / 24 / 32)
    static let space1: CGFloat = 4
    static let space2: CGFloat = 8
    static let space3: CGFloat = 12
    static let space4: CGFloat = 16
    static let space5: CGFloat = 24
    static let space6: CGFloat = 32

    // MARK: Corners (12–16)
    static let cornerL: CGFloat = 16
    static let cornerM: CGFloat = 14
    static let cornerS: CGFloat = 12
}
