//
//  Theaters.swift
//  Cinna
//
//  Created by Subhan Shrestha on 10/9/25.
//

import CoreLocation
import SwiftUI

struct Theaters: View {
    @EnvironmentObject private var userInfo: UserInfoData
    @StateObject private var viewModel = TheatersViewModel()

    @State private var cityDisplay: String?
    @State private var isGeocoding = false

    /// Include both the toggle and coordinate so `.task(id:)` refires when either changes.
    private var locationIdentifier: String {
        let locPart: String
        if let c = userInfo.currentLocation {
            locPart = "\(c.latitude)-\(c.longitude)"
        } else {
            locPart = "nil"
        }
        return "\(userInfo.useCurrentLocationBool)-\(locPart)"
    }

    var body: some View {
        NavigationStack {
            VStack {
                if !userInfo.useCurrentLocationBool || userInfo.currentLocation == nil {
                    VStack(spacing: 12) {
                        Image(systemName: "location.slash")
                            .font(.system(size: 42))
                            .foregroundStyle(.yellow)
                        Text("Location Needed")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                        Text("Enable \"Use Current Location\" during login to discover theaters near you.")
                            .multilineTextAlignment(.center)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    switch viewModel.state {
                    case .idle, .loading:
                        VStack(spacing: 12) {
                            ProgressView("Finding theaters near you…")
                                .progressViewStyle(.circular)
                                .tint(.yellow)
                                .padding()
                            Text("Please ensure location access is allowed.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxHeight: .infinity)

                    case .loaded(let theaters):
                        if theaters.isEmpty {
                            VStack {
                                Text("No theaters found nearby 😔")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .padding(.top, 20)
                            }
                            .frame(maxHeight: .infinity)
                        } else {
                            ScrollView {
                                VStack(spacing: 14) {
                                    Text("Nearby Theaters")
                                        .font(.title.bold())
                                        .foregroundStyle(.primary)

                                    // Left-aligned "Based on:" line (replaces HStack+Spacer)
                                    Text("Based on: " + (cityDisplay ?? (isGeocoding ? "Determining your city…" : "Current Location")))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    ForEach(theaters, id: \.id) { theater in
                                        NavigationLink(
                                            destination: TheaterDetailView(theater: theater)
                                        ) {
                                            TheaterCard(theater: theater)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical)
                                .padding(.horizontal, 20) // owns horizontal inset; card no longer adds its own
                            }
                        }

                    case .error(let error):
                        VStack(spacing: 12) {
                            Text("⚠️ Error: \(error.localizedDescription)")
                                .foregroundStyle(.red)
                            Button("Retry") {
                                Task {
                                    if userInfo.useCurrentLocationBool,
                                       let coordinate = userInfo.currentLocation {
                                        await viewModel.loadNearbyTheaters(at: coordinate)
                                        await geocodeCity(for: coordinate)
                                    } else {
                                        viewModel.reset()
                                        cityDisplay = nil
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Theaters")
            .navigationBarTitleDisplayMode(.inline)
            // Refire when toggle OR coordinates change
            .task(id: locationIdentifier) {
                guard userInfo.useCurrentLocationBool,
                      let coordinate = userInfo.currentLocation
                else {
                    viewModel.reset()
                    cityDisplay = nil
                    return
                }
                await viewModel.loadNearbyTheaters(at: coordinate)
                await geocodeCity(for: coordinate)
            }
        }
    }

    // MARK: - Geocode helper
    private func geocodeCity(for coordinate: CLLocationCoordinate2D) async {
        isGeocoding = true
        let value = await CityGeocoder.shared.cityString(for: coordinate)
        // Update on main actor
        await MainActor.run {
            cityDisplay = value
            isGeocoding = false
        }
    }
}

#Preview {
    // Blacksburg, VA: 37.2296° N, 80.4139° W
    Theaters()
        .environmentObject(UserInfoData.mockBlacksburg())
}

// MARK: - Preview Helpers (Mocks)
#if DEBUG
extension UserInfoData {
    /// Minimal mock for previews. Adjust as needed to match your model init.
    static func mockBlacksburg() -> UserInfoData {
        let mock = UserInfoData()
        mock.useCurrentLocationBool = true
        mock.currentLocation = CLLocationCoordinate2D(latitude: 37.2296, longitude: -80.4139)
        return mock
    }
}
#endif
