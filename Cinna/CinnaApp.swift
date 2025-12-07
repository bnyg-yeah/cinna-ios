//
//  CinnaApp.swift
//  Cinna
//
//  Created by Subhan Shrestha on 9/25/25.
//

import SwiftUI

@main
struct CinnaApp: App {
    @StateObject private var userInfo = UserInfoData()
    @StateObject private var moviePreferences = MoviePreferencesData()
    
    // Optional: perform setup work here (e.g., reading API keys, initializing services)
    init() {
        // 🔍 Quick check — confirm the Google Places API key is accessible from Info.plist
        if let key = Bundle.main.object(forInfoDictionaryKey: "G_PLACES_API_KEY") as? String,
           !key.isEmpty {
            print("✅ Google Places API key loaded successfully: \(key.prefix(8))…")
        } else {
            print("⚠️ Warning: G_PLACES_API_KEY not found in Info.plist.")
        }
    }

    var body: some Scene {
        WindowGroup {
            // The root of your app’s navigation
            ContentView()
                .environmentObject(userInfo)
                .environmentObject(moviePreferences)
                .preferredColorScheme(.dark)
        }
    }
}
