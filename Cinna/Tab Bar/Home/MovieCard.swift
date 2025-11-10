//
//  MovieCard.swift
//  Cinna
//
//  Created by Brighton Young on 11/4/25.
//


import SwiftUI

struct MovieCard: View {
    let movie: TMDbMovie

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            poster
                .frame(width: 72, height: 108)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(movie.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)

                if !movie.overview.isEmpty {
                    Text(movie.overview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    if let year = movie.year.nonEmpty {
                        Label(year, systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    RatingBadge(text: String(format: "⭐️ %.1f", movie.voteAverage))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(.quaternarySystemFill), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(movie.title), \(movie.year.nonEmpty ?? ""), rated \(String(format: "%.1f", movie.voteAverage))")
    }

    @ViewBuilder
    private var poster: some View {
        if let urlString = movie.posterURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFill()
                default:
                    ZStack {
                        LinearGradient(
                            colors: [Color(.systemOrange), Color(.systemPink)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "film.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    }
                }
            }
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemFill))
                .overlay(Image(systemName: "film.fill"))
        }
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
