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
                Text("*Cinna*")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 24)

                List {
                    // MARK: Name
                    Section("Your Name") {
                        SwiftUI.TextField("e.g., Demetrius Ja'Quallin", text: $userInfo.name)
                            .textContentType(.name)
                            .contentShape(Rectangle())
                    }

                    // MARK: Location (native)
                    Section("Location") {
                        VStack(alignment: .leading, spacing: 12) {
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


                            Group {
                                if let locationStatusMessage {
                                    Text(locationStatusMessage)
                                } else if let locationErrorMessage {
                                    Text(locationErrorMessage).foregroundStyle(.red)
                                } else if userInfo.currentLocation != nil {
                                    Text("Location saved and ready to use for nearby theaters.")
                                } else {
                                    Text("Share your location so we can find nearby theaters.")
                                }
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 2)
                        }
                    }

                    // MARK: Genres
                    Section("What do you like to watch?") {
                        ForEach(Genre.allCases, id: \.self) { genre in
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
            }
            .background(Color(.systemBackground))
            .safeAreaInset(edge: .bottom) {
                Button(action: next) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.loginPrimary) // keep your existing style
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
            .navigationBarTitleDisplayMode(.inline)
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
