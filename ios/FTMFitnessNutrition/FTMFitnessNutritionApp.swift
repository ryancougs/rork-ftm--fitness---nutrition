//
//  FTMFitnessNutritionApp.swift
//  FTMFitnessNutrition
//
//  Created by Rork on July 28, 2026.
//

import SwiftUI

@main
struct FTMFitnessNutritionApp: App {
    @State private var app = AppModel()
    @State private var store = StoreService.shared

    init() {
        store.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .environment(store)
                .tint(TF.blue)
        }
    }
}
