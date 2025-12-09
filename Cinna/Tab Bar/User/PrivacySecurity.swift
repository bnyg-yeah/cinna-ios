//
//  PrivacySecurity.swift
//  Cinna
//
//  Created by Brighton Young on 10/4/25.
//

import SwiftUI
import Foundation

struct PrivacySecurity: View {
    @State private var didClear = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Photos") {
                    VStack(alignment: .leading, spacing: 12) {

                        Button("Clear all photos") {
                            UserPhotosManager.shared.clearAllPhotos()
                            didClear = true
                        }
                        .buttonStyle(.glass)
                        .foregroundColor(.red)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, alignment: .center)

                        if didClear {
                            Text("All photos cleared.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("Remove your saved profile photo and user photos from this device.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                Section("User Data") {
                    VStack(alignment: .leading, spacing: 12) {

                        Button("Delete all data") {
                            PrivacySecurityWiper.wipeAll()
                            didClear = true
                        }
                        .buttonStyle(.glass)
                        .foregroundColor(.red)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, alignment: .center)

                        if didClear {
                            Text("All data deleted.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("Removes your name, location, preferences, photos, ratings, and all settings.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

            }
            .scrollContentBackground(.hidden)
            .background(BackgroundView())
            .navigationTitle("Privacy & Security")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


enum PrivacySecurityWiper {
    static func wipeAll() {
        let defaults = UserDefaults.standard
        if let domain = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: domain)
        }
        defaults.synchronize()

        UserPhotosManager.shared.clearAllPhotos()
        URLCache.shared.removeAllCachedResponses()
    }
}



#Preview {
    NavigationStack {
        PrivacySecurity()
    }
}

