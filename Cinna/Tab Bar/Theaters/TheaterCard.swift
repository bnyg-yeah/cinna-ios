//
//  TheaterCard.swift
//  Cinna
//
//  Created by Brighton Young on 11/4/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct TheaterCard: View {
    let theater: Theater

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Leading visual: small map snapshot placeholder to mirror Movie poster
            ZStack {
                LinearGradient(
                    colors: [Color(.systemOrange), Color(.systemPink)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "popcorn.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(theater.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)

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
}

