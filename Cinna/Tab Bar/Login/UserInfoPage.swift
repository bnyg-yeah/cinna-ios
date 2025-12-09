//
//  UserInfoPage.swift
//  Cinna
//
//  Created by Brighton Young on 10/9/25.
//

import SwiftUI
import CoreLocation
import CoreLocationUI   // for the native LocationButton

struct UserInfoView: View {
    
    @EnvironmentObject private var userInfo: UserInfoData
    @EnvironmentObject private var moviePreferences: MoviePreferencesData
    
    private let locationManager = LocationManager()
    
    @State private var isRequestingLocation = false
    @State private var locationStatusMessage: String?
    @State private var locationErrorMessage: String?
    
    var next: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("*Cinna* User Info")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 24)
                
                List {
                    // MARK: Name
                    Section("Your Name") {
                        SwiftUI.TextField("e.g., Chadwick Boseman", text: $userInfo.name)
                            .textContentType(.name)
                            .contentShape(Rectangle())
                    }
                    
                    // MARK: Location (native)
                    Section("Location") {
                        VStack(alignment: .leading, spacing: 12) {
                            
                            // Dynamic label + icon to signal saved state clearly
                            let isSaved = (userInfo.currentLocation != nil)
                            
                            Button {
                                Task { await requestLocationFlow() }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: isSaved ? "checkmark.circle.fill" : "location.fill")
                                        .font(.headline.weight(.semibold))
                                    
                                    Text(isSaved ? "Location Saved" : "Locate Me")
                                        .font(.headline.weight(.semibold))
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .buttonStyle(.glassProminent)
                            .controlSize(.regular)
                            .disabled(isSaved || isRequestingLocation)
                            .opacity(isSaved ? 0.55 : 1)          // Visually disabled
                            .animation(.easeInOut(duration: 0.2), value: isSaved)
                            
                            Group {
                                if let locationStatusMessage {
                                    Text(locationStatusMessage)
                                } else if let locationErrorMessage {
                                    Text(locationErrorMessage).foregroundStyle(.red)
                                } else if isSaved {
                                    Text("Location is stored and will be used to find nearby theaters.")
                                } else {
                                    Text("Share your location so we can find nearby theaters.")
                                }
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 0)
                            .padding(.bottom, -4)
                        }
                    }
                    
                    
                    // MARK: Genres
                    Section("What do you like to watch?") {
                        ForEach(GenrePreferences.allCases, id: \.self) { genre in
                            Button {
                                moviePreferences.toggleGenre(genre)
                            } label: {
                                HStack {
                                    Image(systemName: genre.symbol).frame(width: 24)
                                    Text(genre.title)
                                    Spacer()
                                    if moviePreferences.selectedGenres.contains(genre) {
                                        Image(systemName: "checkmark")
                                            .font(.body.weight(.semibold))
                                            .accessibilityHidden(true)
                                    }
                                }
                                .contentShape(Rectangle()) // full-row tap
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .gesture(
                    TapGesture().onEnded { UIApplication.shared.endEditing() }
                )
                .scrollDismissesKeyboard(.immediately)


            }
            .background(Color(.systemBackground))
            .safeAreaInset(edge: .bottom) {
                Button(action: next) {
                    Text("Continue")
                        .font(.title3.weight(.semibold))
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    UserInfoView(next: { })
        .environmentObject(UserInfoData())
        .environmentObject(MoviePreferencesData())
}

// MARK: - Location flow
extension UserInfoView {
    @MainActor
    private func requestLocationFlow() async {
        guard !isRequestingLocation else { return }
        
        isRequestingLocation = true
        locationStatusMessage = nil
        locationErrorMessage = nil
        
        do {
            // This uses your existing LocationManager which ensures auth + requests one-shot location.
            let coordinate = try await locationManager.requestLocation()
            
            // Treat this as “while using” semantics for persistence.
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

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
