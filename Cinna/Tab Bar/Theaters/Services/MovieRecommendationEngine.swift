//
//  MovieRecommendationEngine.swift
//  Cinna
//
//  Created by Chao Chen on 10/27/25.
//
import Foundation

/// Smart recommendation engine that uses user preferences and movie data
class MovieRecommendationEngine {
    static let shared = MovieRecommendationEngine()
    
    private init() {}
    
    // MARK: - Recommendation Logic
    
    /// Get personalized movie recommendations based on user's genre preferences
    func getPersonalizedRecommendations(
        selectedGenres: Set<Genre>,
        page: Int = 1
    ) async throws -> [TMDbMovie] {
        // If user hasn't selected any genres, return popular movies
        guard !selectedGenres.isEmpty else {
            return try await TMDbService.getPopularMovies(page: page)
        }
        
        // Convert genres to TMDb genre IDs
        let genreIDs = selectedGenres.map { $0.tmdbID }
        
        // Discover movies matching user's genres, sorted by popularity
        let movies = try await TMDbService.discoverMovies(genreIDs: genreIDs, page: page)
        
        return movies
    }
    
    /// Get popular movies (fallback when no preferences)
    func getPopularMovies(page: Int = 1) async throws -> [TMDbMovie] {
        return try await TMDbService.getPopularMovies(page: page)
    }
}
