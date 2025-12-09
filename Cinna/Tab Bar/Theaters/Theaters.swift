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
    @ObservedObject private var favorites = FavoriteTheater.shared

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
            // Stable scaffold: always a scroll view with same padding and structure
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header: always visible to stabilize layout/glass sampling
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nearby Theaters")
                            .font(.title.bold())
                            .foregroundStyle(.white)

                        Text(basedOnText)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.top, 8)

                    // Content area: switch only the inner content, not the whole scaffold
                    Group {
                        if !userInfo.useCurrentLocationBool || userInfo.currentLocation == nil {
                            // Location disabled/unknown notice as a glass card
                            InfoCard(
                                icon: "location.slash",
                                title: "Location Needed",
                                message: "Enable \"Use Current Location\" during login to discover theaters near you."
                            )
                        } else {
                            switch viewModel.state {
                            case .idle, .loading:
                                // Skeleton list that matches TheaterCard dimensions to keep layout stable
                                VStack(spacing: 16) {
                                    ForEach(0..<5, id: \.self) { _ in
                                        TheaterCardSkeleton()
                                    }
                                }

                            case .loaded(let theaters):
                                let favs = Set(favorites.favoriteIDs)
                                let sorted = theaters.sorted { lhs, rhs in
                                    let lFav = favs.contains(lhs.id)
                                    let rFav = favs.contains(rhs.id)
                                    if lFav != rFav { return lFav && !rFav }
                                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                                }
                                if theaters.isEmpty {
                                    EmptyStateCard(
                                        title: "No theaters found nearby 😔",
                                        message: "Try expanding your search radius or check location permissions."
                                    )
                                } else {
                                    VStack(spacing: 16) {
                                        ForEach(sorted, id: \.id) { theater in
                                            NavigationLink(
                                                destination: TheaterDetailView(theater: theater)
                                            ) {
                                                TheaterCard(theater: theater)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }

                            case .error(let error):
                                ErrorCard(
                                    message: error.localizedDescription,
                                    retry: {
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
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(BackgroundView())
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

    private var basedOnText: String {
        if !userInfo.useCurrentLocationBool || userInfo.currentLocation == nil {
            return "Based on: Location access disabled"
        }
        if let cityDisplay {
            return "Based on: \(cityDisplay)"
        }
        return isGeocoding ? "Based on: Determining your city…" : "Based on: Current Location"
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

// MARK: - Local helper views to keep layout stable

private struct TheaterCardSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .frame(width: 72, height: 72)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 16)

                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 12)
                    .opacity(0.9)

                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 80, height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 90, height: 12)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.clear)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
        .redacted(reason: .placeholder)
    }
}

private struct InfoCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 42))
                .foregroundStyle(.yellow)
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text(message)
                .multilineTextAlignment(.center)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.clear)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
    }
}

private struct EmptyStateCard: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.clear)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
    }
}

private struct ErrorCard: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚠️ Error")
                .font(.headline)
                .foregroundStyle(.white)
            Text(message)
                .foregroundStyle(.red)
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.clear)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
    }
}

// MARK: - Preview Helpers (Mocks)
#if DEBUG
extension UserInfoData {
    /// Minimal mock for previews. Adjust as needed to match your model init.
    static func mockBlacksburg() -> UserInfoData {
        let mock = UserInfoData()
        mock.useCurrentLocationBool = true
        mock.currentLocation = CLLocationCoordinate2D(
            latitude: 37.2296,
            longitude: -80.4139
        )
        return mock
    }
}
#endif

