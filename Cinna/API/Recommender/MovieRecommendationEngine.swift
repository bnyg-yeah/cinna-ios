//
//  MovieRecommendationEngine.swift
//  Cinna
//
//  Created by Chao Chen on 10/27/25.
//  Updated with GraphRAG by Team Cinna on 11/30/25.
//

import Foundation

/// Smart recommendation engine that uses GraphRAG and user preferences
class MovieRecommendationEngine {
    static let shared = MovieRecommendationEngine()
    
    private let graphRAG = GraphRAGEngine.shared
    private var useGraphRAG = true  // Toggle for GraphRAG vs traditional
    
    private init() {}
    
    // MARK: - Main Recommendation Method
    
    /// Get personalized movie recommendations based on user's genre preferences
    /// Now powered by GraphRAG!
    func getPersonalizedRecommendations(
        selectedGenres: Set<GenrePreferences>,
        page: Int = 1
    ) async throws -> [TMDbMovie] {
        // If user hasn't selected any genres, return popular movies
        guard !selectedGenres.isEmpty else {
            return try await getPopularMovies(page: page)
        }
        
        // Convert genres to TMDb genre IDs
        let genreIDs = selectedGenres.map { $0.tmdbID }
        
        // Step 1: Fetch movies from TMDb (get more for better graph)
        let fetchedMovies = try await fetchMoviesForGraph(genreIDs: genreIDs, pages: 3)
        
        // Step 2: Build genre mapping (which genres each movie has)
        let genreMapping = await fetchGenreMappings(for: fetchedMovies)
        
        // Step 3: Build GraphRAG knowledge graph
        graphRAG.buildGraph(from: fetchedMovies, genreMapping: genreMapping)
        
        // Step 4: Get recommendations using GraphRAG
        if useGraphRAG && graphRAG.isReady() {
            let recommendations = graphRAG.getRecommendations(for: genreIDs, limit: 20)
            print("✅ Using GraphRAG: \(recommendations.count) recommendations")
            return recommendations
        } else {
            // Fallback to traditional sorting
            print("⚠️ Using traditional recommendations")
            return fetchedMovies.sorted { $0.voteAverage > $1.voteAverage }
        }
    }
    
    // MARK: - Fetch Movies for Graph
    
    /// Fetch multiple pages of movies to build a rich knowledge graph
    /// Fetches movies for EACH genre separately to get more results
    private func fetchMoviesForGraph(genreIDs: [Int], pages: Int = 2) async throws -> [TMDbMovie] {
        var allMovies: [TMDbMovie] = []
        
        // Fetch movies for EACH genre separately (OR logic, not AND)
        for genreID in genreIDs {
            for page in 1...pages {
                let movies = try await TMDbService.discoverMovies(genreIDs: [genreID], page: page)
                allMovies.append(contentsOf: movies)
                
                // Small delay to respect rate limits
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }
        
        // Remove duplicates
        let uniqueMovies = Dictionary(grouping: allMovies, by: { $0.id })
            .compactMap { $0.value.first }
        
        print("📥 Fetched \(uniqueMovies.count) unique movies for graph")
        return uniqueMovies
    }
    
    // MARK: - Fetch Genre Mappings
    
    /// Fetch detailed info for each movie to get their actual genre lists
    /// This is important for accurate graph connections
    private func fetchGenreMappings(for movies: [TMDbMovie]) async -> [Int: [Int]] {
        let movieIDs = movies.map { $0.id }
        
        print("🔍 Fetching genre mappings for \(movieIDs.count) movies...")
        let genreMapping = await TMDbService.batchFetchGenres(for: movieIDs)
        
        return genreMapping
    }
    
    // MARK: - Similar Movies (GraphRAG Feature)
    
    /// Get movies similar to a given movie using GraphRAG
    func getSimilarMovies(to movieID: Int, limit: Int = 10) -> [TMDbMovie] {
        guard graphRAG.isReady() else {
            print("⚠️ Graph not ready for similar movies")
            return []
        }
        
        return graphRAG.getSimilarMovies(to: movieID, limit: limit)
    }
    
    // MARK: - Popular Movies (Fallback)
    
    /// Get popular movies (fallback when no preferences)
    func getPopularMovies(page: Int = 1) async throws -> [TMDbMovie] {
        return try await TMDbService.getPopularMovies(page: page)
    }
    
    // MARK: - GraphRAG Settings
    
    /// Toggle GraphRAG on/off (for testing/comparison)
    func setUseGraphRAG(_ enabled: Bool) {
        useGraphRAG = enabled
        print(enabled ? "✅ GraphRAG enabled" : "⚠️ GraphRAG disabled")
    }
    
    /// Check if GraphRAG is ready
    func isGraphRAGReady() -> Bool {
        return graphRAG.isReady()
    }
    
    /// Get graph statistics
    func getGraphStats() -> GraphStats? {
        return graphRAG.getGraphStats()
    }
    
    /// Reset the graph (useful for testing)
    func resetGraph() {
        graphRAG.reset()
    }
}
