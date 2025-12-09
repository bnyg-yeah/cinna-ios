//
//  TheaterCard.swift
//  Cinna
//
//  Created by Brighton Young on 11/4/25.
//

import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct TheaterCard: View {
    let theater: Theater
    @ObservedObject private var favorites = FavoriteTheater.shared

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Leading visual: brand logo if available, else default logo
            Group {
                let imageName = logoAssetName ?? "logo_default"
                if let ui = UIImage(named: imageName) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.clear)
                                .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .accessibilityHidden(true)
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [Color(.systemTeal), Color(.systemIndigo)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "theatermasks")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityHidden(true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(theater.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 8)
                    Button {
                        favorites.toggleFavorite(id: theater.id)
                    } label: {
                        Image(systemName: favorites.isFavorite(id: theater.id) ? "star.fill" : "star")
                            .font(.headline) // Increased star size a bit
                            .foregroundStyle(favorites.isFavorite(id: theater.id) ? .yellow : .secondary)
                            .accessibilityLabel(favorites.isFavorite(id: theater.id) ? "Unfavorite" : "Mark as Favorite")
                    }
                    .buttonStyle(.plain)
                }

                if let address = theater.address, !address.isEmpty {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    if let rating = theater.rating {
                        RatingBadge(text: String(format: "⭐️ %.1f", rating))
                    } else {
                        Text("No rating")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Label("Directions", systemImage: "map")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(theater.name), \(theater.address ?? "Address unavailable")\(theater.rating != nil ? ", rated \(String(format: "%.1f", theater.rating!))" : "")")
    }

    // MARK: - Branding
    private var logoAssetName: String? {
        switch theater.chain {
        case .amc: return "logo_amc"
        case .regal: return "logo_regal"
        case .cinemark: return "logo_cinemark"
        case .alamo: return "logo_alamo"
        case .other: return nil
        }
    }
}

