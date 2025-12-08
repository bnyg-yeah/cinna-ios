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
    @State private var loadingProgress: Double = 0.0
    @State private var lastLoadedPreferences: (genres: Set<GenrePreferences>, filmmaking: Set<FilmmakingPreferences>)?

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if isLoading {
                        Color.clear
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
                                        .foregroundStyle(.white)

                                    if !moviePreferences.selectedGenres.isEmpty {
                                        Text("Based on: \(moviePreferences.sortedSelectedGenresString)")
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.8))
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
                .background(BackgroundView())
                
                // Loading overlay with progress bar
                if isLoading {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        Image(systemName: "popcorn.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        
                        Text("Finding perfect movies...")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        // Progress bar
                        VStack(spacing: 8) {
                            ProgressView(value: loadingProgress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                                .frame(width: 200)
                            
                            Text("\(Int(loadingProgress * 100))%")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                                .monospacedDigit()
                        }
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.85))
                    )
                    .shadow(radius: 20)
                }
            }
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
        // Check if preferences have changed
        let currentPreferences = (moviePreferences.selectedGenres, moviePreferences.selectedFilmmakingPreferences)
        
        if let last = lastLoadedPreferences,
           last.genres == currentPreferences.0,
           last.filmmaking == currentPreferences.1,
           !movies.isEmpty {
            // Preferences unchanged and we have movies - skip reload
            return
        }
        
        isLoading = true
        loadingProgress = 0.0
        errorMessage = nil
        
        // Simulate progress
        Task {
            for i in 1...20 {
                if isLoading {
                    loadingProgress = Double(i) / 20.0
                    try? await Task.sleep(nanoseconds: 250_000_000)
                }
            }
        }
        
        do {
            // Use your existing engine as-is
            let engine = MovieRecommendationEngine.shared
            movies = try await engine.getPersonalizedRecommendations(
                selectedGenres: moviePreferences.selectedGenres,
                selectedFilmmakingPreferences: moviePreferences.selectedFilmmakingPreferences,
                page: 1
            )
            loadingProgress = 1.0
            lastLoadedPreferences = currentPreferences  // Save current preferences
        } catch {
            errorMessage = "Failed to load movies. Please try again."
            #if DEBUG
            print("Error loading movies: \(error)")
            #endif
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
                .foregroundStyle(.white)
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
                .foregroundStyle(.white.opacity(0.7))
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    Home()
        .environmentObject(UserInfoData())
        .environmentObject(MoviePreferencesData())
}
