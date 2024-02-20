//
//  HalcyonWatchApp.swift
//  HalcyonWatch Watch App
//
//  Created by Michel Lapointe on 2024-02-20.
//

import SwiftUI

@main
struct Halcyon_2_0_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ClimateViewModel.shared)
        }
    }
}
