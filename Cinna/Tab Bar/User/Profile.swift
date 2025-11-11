//
//  Profile.swift
//  Cinna
//
//  Created by Brighton Young on 10/4/25.
//

import SwiftUI
import CoreLocation
import CoreLocationUI // ⬅️ native location button

struct Profile: View {
    @EnvironmentObject private var userInfo: UserInfoData
    private let locationManager = LocationManager()
    
    @State private var isRequestingLocation = false
    @State private var locationStatusMessage: String?
    @State private var locationErrorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Name
                Section("*Cinna* Profile Details") {
                    HStack(spacing: 12) {
                        Text("Name")
                            .bold()
                            .frame(minWidth: 60, alignment: .leading)
                        
                        SwiftUI.TextField("Your name", text: $userInfo.name)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .contentShape(Rectangle())
                    }
                }
                
                // MARK: - Location
                Section("Location") {
                    VStack(alignment: .leading, spacing: 12) {
                        
                        // Native Apple-styled button → shows system prompt as needed
                        LocationButton(.currentLocation) {
                            Task { await requestLocationFlow() }
                        }
                        .labelStyle(.titleAndIcon)
                        .controlSize(.large)
                        .buttonBorderShape(.roundedRectangle)
                        .tint(.accentColor)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .disabled(isRequestingLocation)
                        
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        
                        
                        // Stop using current location
                        if userInfo.useCurrentLocationBool, userInfo.currentLocation != nil {
                            Button("Stop Using Current Location") {
                                userInfo.clearLocation()
                                locationStatusMessage = "Current location disabled."
                                locationErrorMessage = nil
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .buttonBorderShape(.roundedRectangle)
                            .tint(.red)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .disabled(isRequestingLocation)
                        }
                        
                        // Status / guidance
                        Group {
                            if isRequestingLocation {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Updating location…")
                                }
                                .foregroundStyle(.secondary)
                                
                            } else if let locationStatusMessage {
                                Text(locationStatusMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                
                            } else if let locationErrorMessage {
                                Text(locationErrorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                                
                            } else if userInfo.useCurrentLocationBool,
                                      userInfo.currentLocation != nil {
                                Text("Location saved and ready to use for nearby theaters.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                
                            } else {
                                Text("Share your location to find nearby theaters.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(BackgroundView())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    Profile()
        .environmentObject(UserInfoData())
}

// MARK: - Location flow
extension Profile {
    @MainActor
    private func requestLocationFlow() async {
        guard !isRequestingLocation else { return }
        
        isRequestingLocation = true
        locationStatusMessage = nil
        locationErrorMessage = nil
        
        do {
            // Uses your existing manager: ensures auth + one-shot location
            let coordinate = try await locationManager.requestLocation()
            
            // Persist with “while using” semantics
            userInfo.updateLocation(coordinate, preference: .allowWhileUsing)
            locationStatusMessage = "Location saved for nearby theaters."
        } catch {
            userInfo.clearLocation()
            locationErrorMessage = (error as? LocalizedError)?.errorDescription
            ?? error.localizedDescription
        }
        
        isRequestingLocation = false
    }
}
