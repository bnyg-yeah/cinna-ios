//
//  Home.swift
//  Cinna
//
//  Created by Brighton Young on 9/26/25.
//

import SwiftUI

struct Home: View {
    @EnvironmentObject private var moviePreferences: MoviePreferencesData
    @State private var movies: [TMDbMovie] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading movies…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 40)
                } else if let errorMessage {
                    ErrorStateView(message: errorMessage) {
                        Task { await loadMovies() }
                    }
                    .padding(.horizontal, 24)
                } else if movies.isEmpty {
                    EmptyStateView(title: "No movies found", systemImage: "film.stack")
                        .padding(.horizontal, 24)
                } else {
                    ScrollView {
                        VStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recommended Movies")
                                    .font(.title.bold())
                                    .foregroundStyle(Color(.label))

                                if !moviePreferences.selectedGenres.isEmpty {
                                    Text("Based on: \(moviePreferences.sortedSelectedGenresString)")
                                        .font(.subheadline)
                                        .foregroundStyle(Color(.secondaryLabel))
                                }
                            }

                            VStack(spacing: 16) {
                                ForEach(movies) { movie in
                                    NavigationLink(value: movie) {
                                        MovieCard(movie: movie)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: TMDbMovie.self) { movie in
                MovieDetailView(movie: movie)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadMovies() }
            .refreshable { await loadMovies() }
        }
    }

    // MARK: - Load

    private func loadMovies() async {
        isLoading = true
        errorMessage = nil

        do {
            let engine = MovieRecommendationEngine.shared

            if !moviePreferences.selectedGenres.isEmpty {
                // Fetch GraphRAG recommendations
                movies = try await engine.getGraphRAGRecommendations(
                    selectedGenres: moviePreferences.selectedGenres
                )
                print("✅ Loaded \(movies.count) GraphRAG movies")
            } else {
                // Fallback to TMDb-based recommendations
                movies = try await engine.getPersonalizedRecommendations(
                    selectedGenres: moviePreferences.selectedGenres,
                    page: 1
                )
            }
        } catch {
            errorMessage = "Failed to load movies. Please try again."
            print("❌ Error loading movies:", error)
        }

        isLoading = false
    }

}

// MARK: - Local simple states

private struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(Color(.systemOrange))
                .accessibilityHidden(true)

            Text(message)
                .font(.body)
                .foregroundStyle(Color(.secondaryLabel))
                .multilineTextAlignment(.center)

            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

private struct EmptyStateView: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(Color(.secondaryLabel))
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .foregroundStyle(Color(.label))
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    Home()
        .environmentObject(MoviePreferencesData())
}
