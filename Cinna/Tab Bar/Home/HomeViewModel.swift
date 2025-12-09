//
//  HomeViewModel.swift
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

    // Cache of last loaded preferences (all categories)
    private var lastLoadedPreferences: (
        genres: Set<GenrePreferences>,
        filmmaking: Set<FilmmakingPreferences>,
        animation: Set<AnimationPreferences>,
        studios: Set<StudioPreferences>,
        themes: Set<ThemePreferences>
    )?

    /// Load personalized movies based on the user's preferences
    func loadMovies(with preferences: MoviePreferencesData) async {

        let currentPrefs = (
            genres: preferences.selectedGenres,
            filmmaking: preferences.selectedFilmmakingPreferences,
            animation: preferences.selectedAnimationPreferences,
            studios: preferences.selectedStudioPreferences,
            themes: preferences.selectedThemePreferences
        )


        // Smart caching: only reload when something actually changed
        if let last = lastLoadedPreferences,
           last.genres == currentPrefs.genres,
           last.filmmaking == currentPrefs.filmmaking,
           last.animation == currentPrefs.animation,
           last.studios == currentPrefs.studios,
           last.themes == currentPrefs.themes,
           !movies.isEmpty {
            return
        }


        // Begin loading
        isLoading = true
        errorMessage = nil
        loadingProgress = 0.0
        simulateProgress()

        do {
            let engine = MovieRecommendationEngine.shared

            movies = try await engine.getPersonalizedRecommendations(
                selectedGenres: currentPrefs.0,
                selectedFilmmakingPreferences: currentPrefs.1,
                selectedAnimationPreferences: currentPrefs.2,
                selectedStudioPreferences: currentPrefs.3,
                selectedThemePreferences: currentPrefs.4
            )

            loadingProgress = 1.0
            lastLoadedPreferences = currentPrefs   // update cache

        } catch {
            errorMessage = "Failed to load movies. Please try again."
            print("Error loading movies: \(error)")
        }

        isLoading = false
    }

    // Fake loading animation (pure UI feel)
    private func simulateProgress() {
        Task {
            for i in 1...20 {
                guard isLoading else { return }
                loadingProgress = Double(i) / 20.0
                try? await Task.sleep(nanoseconds: 120_000_000)
            }
        }
    }
}
