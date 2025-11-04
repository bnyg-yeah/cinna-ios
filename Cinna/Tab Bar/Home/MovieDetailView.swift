//
//  MovieDetailView.swift
//  Cinna
//
//  Created by Brighton Young on 11/4/25.
//


import SwiftUI

struct MovieDetailView: View {
    let movie: TMDbMovie

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let urlString = movie.posterURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 400)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(.tertiarySystemFill))
                                .frame(height: 220)
                                .overlay(Image(systemName: "film.fill"))
                                .accessibilityHidden(true)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(movie.title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color(.label))

                    HStack(spacing: 12) {
                        if !movie.releaseDate.isEmpty { Text(movie.releaseDate) }
                        Text("⭐️ \(String(format: "%.1f", movie.voteAverage))")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color(.secondaryLabel))

                    Text("Popularity: \(String(format: "%.0f", movie.popularity))")
                        .font(.caption)
                        .foregroundStyle(Color(.tertiaryLabel))
                }

                SectionBlock(title: "Overview") {
                    Text(movie.overview.isEmpty ? "No synopsis available." : movie.overview)
                }
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(movie.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
