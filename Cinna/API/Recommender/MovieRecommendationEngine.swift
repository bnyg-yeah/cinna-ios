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
    /// Now powered by GraphRAG with user ratings and embeddings!
    func getPersonalizedRecommendations(
        selectedGenres: Set<GenrePreferences>,
        selectedFilmmakingPreferences: Set<FilmmakingPreferences> = [],
        selectedAnimationPreferences: Set<AnimationPreferences> = [],
        page: Int = 1
    ) async throws -> [TMDbMovie] {
        // If user hasn't selected any genres, return popular movies
        guard !selectedGenres.isEmpty else {
            return try await getPopularMovies(page: page)
        }
        
        // Convert genres to TMDb genre IDs
        let genreIDs = selectedGenres.map { $0.tmdbID }
        
        // Step 1: Fetch movies from TMDb (get more for better graph)
        let fetchedMovies = try await fetchMoviesForGraph(genreIDs: genreIDs, pages: 2)
        
        // Step 2: Build genre mapping (which genres each movie has)
        let genreMapping = await fetchGenreMappings(for: fetchedMovies)
        
        // Step 3: Generate embeddings for semantic understanding
        let (movieTexts, movieEmbeddings) = await generateMovieEmbeddings(for: fetchedMovies)
        
        // Step 4: Build GraphRAG knowledge graph with embeddings
        await graphRAG.buildGraph(
            from: fetchedMovies,
            genreMapping: genreMapping,
            movieTexts: movieTexts,
            movieEmbeddings: movieEmbeddings
        )
        
        // Step 5: Apply user ratings to personalize
        let userRatings = UserRatings.shared.snapshot()
        if !userRatings.isEmpty {
            graphRAG.applyUserRatings(userRatings)
            print("⭐ Applied \(userRatings.count) user ratings")
        }
        
        // Step 6: Apply movie preferences (embedding-based)
        if !selectedFilmmakingPreferences.isEmpty {
            graphRAG.applyFilmmakingPreferences(selectedFilmmakingPreferences)
        }
        if !selectedAnimationPreferences.isEmpty {
            graphRAG.applyAnimationPreferences(selectedAnimationPreferences)
        }
        
        // Step 7: Get recommendations using GraphRAG
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
    
    // MARK: - Generate Movie Embeddings
    
    // MARK: - Generate Movie Embeddings (BATCH MODE - FAST!)
    
    /// Generate embeddings for movies using batch processing
    private func generateMovieEmbeddings(
        for movies: [TMDbMovie]
    ) async -> (texts: [Int: String], embeddings: [Int: [Float]]) {
        var texts: [Int: String] = [:]
        var embeddings: [Int: [Float]] = [:]
        
        print("🎬 Generating embeddings for \(movies.count) movies...")
        
        // Step 1: Fetch all reviews/details concurrently
        var movieData: [(id: Int, text: String)] = []
        
        await withTaskGroup(of: (Int, String)?.self) { group in
            for movie in movies {
                group.addTask {
                    do {
                        async let reviewsTask = TMDbService.getReviews(movieID: movie.id, page: 1, maxPages: 1)
                        async let detailsTask = TMDbService.getMovieDetails(movieID: movie.id, appendFields: ["keywords"])
                        
                        let reviews = try await reviewsTask
                        let details = try await detailsTask
                        
                        let combinedText = self.buildCombinedText(
                            movie: movie,
                            details: details,
                            reviews: reviews
                        )
                        
                        return (movie.id, combinedText)
                    } catch {
                        print("  ✗ Failed to fetch data for \(movie.title): \(error)")
                        return nil
                    }
                }
            }
            
            for await result in group {
                if let (id, text) = result {
                    movieData.append((id, text))
                }
            }
        }
        
        // Store texts
        for (id, text) in movieData {
            texts[id] = text
        }
        
        // Step 2: BATCH generate all embeddings in ONE request
        let textsOnly = movieData.map { $0.text }
        
        guard !textsOnly.isEmpty else {
            print("⚠️ No texts to embed")
            return (texts, embeddings)
        }
        
        do {
            let startTime = Date()
            let generatedEmbeddings = try await EmbeddingService.shared.batchGenerateEmbeddings(for: textsOnly)
            let elapsed = Date().timeIntervalSince(startTime)
            
            // Map embeddings back to movie IDs
            for (index, (id, _)) in movieData.enumerated() {
                if index < generatedEmbeddings.count {
                    embeddings[id] = generatedEmbeddings[index]
                }
            }
            
            print("✅ Generated \(embeddings.count)/\(movies.count) embeddings in \(String(format: "%.2f", elapsed))s")
        } catch {
            print("❌ Batch embedding failed: \(error)")
        }
        
        return (texts, embeddings)
    }
    
    
    /// Build combined text from multiple sources for embedding
    private func buildCombinedText(
        movie: TMDbMovie,
        details: TMDbMovieDetails,
        reviews: [TMDbService.TMDbReview]
    ) -> String {
        var parts: [String] = []
        
        // Add overview
        if !movie.overview.isEmpty {
            parts.append("Overview: \(movie.overview)")
        }
        
        // Add tagline
        if let tagline = details.tagline, !tagline.isEmpty {
            parts.append("Tagline: \(tagline)")
        }
        
        // Add keywords
        if let keywords = details.keywords?.keywords {
            let keywordText = keywords.map { $0.name }.joined(separator: ", ")
            parts.append("Themes: \(keywordText)")
        }
        
        // Add reviews (limit to 3 for token efficiency)
        let reviewTexts = reviews.prefix(3).map { review in
            String(review.content.prefix(300))  // Limit each review
        }
        if !reviewTexts.isEmpty {
            parts.append("Audience Reviews: " + reviewTexts.joined(separator: " | "))
        }
        
        return parts.joined(separator: "\n\n")
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
