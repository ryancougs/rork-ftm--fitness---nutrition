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
    /// Tap anywhere outside a text field to dismiss the keyboard. The gesture
    /// is simultaneous, so buttons and list rows still receive their taps.
    func dismissKeyboardOnTap() -> some View {
        simultaneousGesture(TapGesture().onEnded { dismissKeyboard() })
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
