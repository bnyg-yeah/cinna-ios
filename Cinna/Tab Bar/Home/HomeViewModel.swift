//
//  HomeModel.swift
//  Cinna
//
//  Created by Subhan Shrestha on 12/8/25.
//

import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var movies: [TMDbMovie] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var loadingProgress: Double = 0.0

    // Smart caching moved from Home.swift
    private var lastLoadedPreferences: (genres: Set<GenrePreferences>, filmmaking: Set<FilmmakingPreferences>)?

    func loadMovies(with preferences: MoviePreferencesData) async {
        let currentPrefs = (preferences.selectedGenres, preferences.selectedFilmmakingPreferences)

        // Smart caching — skip reload if nothing changed
        if let last = lastLoadedPreferences,
           last.genres == currentPrefs.0,
           last.filmmaking == currentPrefs.1,
           !movies.isEmpty {
            return
        }

        isLoading = true
        errorMessage = nil
        loadingProgress = 0.0

        simulateProgress()

        do {
            let engine = MovieRecommendationEngine.shared
            
            movies = try await engine.getPersonalizedRecommendations(
                selectedGenres: preferences.selectedGenres,
                selectedFilmmakingPreferences: preferences.selectedFilmmakingPreferences
            )
            
            loadingProgress = 1.0
            lastLoadedPreferences = currentPrefs
        } catch {
            errorMessage = "Failed to load movies. Please try again."
            print("Error loading movies: \(error)")
        }

        isLoading = false
    }

    private func simulateProgress() {
        Task {
            for i in 1...20 {
                if isLoading {
                    loadingProgress = Double(i) / 20.0
                    try? await Task.sleep(nanoseconds: 250_000_000)
                }
            }
        }
    }
}
