//
//  Keyboard.swift
//  FTMFitnessNutrition
//

import SwiftUI
import UIKit

/// Dismisses the keyboard from anywhere in the app.
@MainActor
func dismissKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil, from: nil, for: nil
    )
}

extension View {
    /// Tap anywhere outside a text field to dismiss the keyboard.
    ///
    /// The gesture lives on a transparent layer BEHIND the screen's content,
    /// so it can only receive taps on empty space — buttons, cards, and list
    /// rows are always hit-tested first and never lose their taps. (An
    /// earlier implementation attached a simultaneous TapGesture to the
    /// ScrollView itself, which made buttons feel unresponsive and scrolling
    /// sticky.)
    func dismissKeyboardOnTap() -> some View {
        background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { dismissKeyboard() }
        )
    }

    /// Adds a Done key above pads that have no return key (decimal/number pads).
    /// Apply once per screen; requires a NavigationStack ancestor.
    func keyboardDoneBar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { dismissKeyboard() }
                    .fontWeight(.semibold)
            }
        }
    }
}
