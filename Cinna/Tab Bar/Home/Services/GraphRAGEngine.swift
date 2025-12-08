//
//  GraphRAGEngine.swift
//  Cinna
//
//  Created by Subhan Shrestha
//

import Foundation

class GraphRAGEngine {
    static let shared = GraphRAGEngine()  // ADD THIS LINE
    
    private var graph = MovieGraph()
    private var cachedMovies: [TMDbMovie] = []
    private var preferenceEmbeddings: PreferenceEmbeddings?
    
    private init() {}  // Private initializer for singleton
    
    // MARK: - Build Graph
    
    func buildGraph(
        from movies: [TMDbMovie],
        genreMapping: [Int: [Int]],
        movieTexts: [Int: String],
        movieEmbeddings: [Int: [Float]]
    ) async {
        cachedMovies = movies
        
        
        // Load preference embeddings from cache (or generate if first time)
        if preferenceEmbeddings == nil {
            do {
                preferenceEmbeddings = try await PreferenceEmbeddings.loadOrGenerate()
            } catch {
                print("❌ Failed to load preference embeddings: \(error)")
            }
        }
        
        // Build graph
        graph.buildGraph(
            from: movies,
            genreMapping: genreMapping,
            movieTexts: movieTexts,
            movieEmbeddings: movieEmbeddings
        )
        
        // Calculate filmmaking scores
        if let prefEmb = preferenceEmbeddings {
            graph.calculateFilmmakingScores(preferenceEmbeddings: prefEmb)
            graph.calculateAnimationScores(preferenceEmbeddings: prefEmb)
        }
    }
    
    // MARK: - Apply User Ratings
    
    func applyUserRatings(_ ratings: [Int: Int]) {
        graph.applyUserRatings(ratings)
    }
    
    // MARK: - Apply Filmmaking Preferences
    
    func applyFilmmakingPreferences(_ preferences: Set<FilmmakingPreferences>) {
        graph.applyFilmmakingPreferences(preferences)
    }
    
    // MARK: - Apply Animation Preferences
    func applyAnimationPreferences(_ preferences: Set<AnimationPreferences>) {
        graph.applyAnimationPreferences(preferences)
    }
    
    // MARK: - Get Recommendations
    
    func getRecommendations(for genreIDs: [Int], limit: Int = 20) -> [TMDbMovie] {
        let nodes = graph.getRecommendations(for: genreIDs, limit: limit)
        
        // Convert nodes back to TMDbMovie
        return nodes.compactMap { node in
            cachedMovies.first { $0.id == node.id }
        }
    }
    
    // MARK: - Similar Movies
    
    func getSimilarMovies(to movieID: Int, limit: Int = 10) -> [TMDbMovie] {
        let nodes = graph.getSimilarMovies(to: movieID, limit: limit)
        
        return nodes.compactMap { node in
            cachedMovies.first { $0.id == node.id }
        }
    }
    
    // MARK: - Status Methods
    
    func isReady() -> Bool {
        return !cachedMovies.isEmpty
    }
    
    func getGraphStats() -> GraphStats? {
        guard isReady() else { return nil }
        return graph.getStats()
    }
    
    func reset() {
        cachedMovies.removeAll()
        preferenceEmbeddings = nil
        print("🔄 GraphRAG reset")
    }
}
