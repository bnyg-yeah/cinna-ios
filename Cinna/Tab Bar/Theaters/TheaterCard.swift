//
//  TheaterCard.swift
//  Cinna
//
//  Created by Brighton Young on 11/4/25.
//


//
//  TheaterCard.swift
//  Cinna
//
//  Created by Subhan Shrestha on 10/9/25.
//

import SwiftUI

struct TheaterCard: View {
    let theater: Theater

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // ⭐️ Rating (only if available)
            if let rating = theater.rating {
                VStack(alignment: .center, spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 22))
                    Text(String(format: "%.1f", rating))
                        .foregroundStyle(.yellow)
                        .font(.headline)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Rating \(String(format: "%.1f", rating)) out of 5")
            }

            // 🎭 Theater Info
            VStack(alignment: .leading, spacing: 6) {
                Text(theater.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(theater.address ?? "Address not available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))   // was systemBackground
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(.quaternarySystemFill), lineWidth: 1)
        )
//        .shadow(radius: 3, y: 2)
        // NOTE: Horizontal padding removed here; Theaters.swift owns outer horizontal insets.
    }
}
