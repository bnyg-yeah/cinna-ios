//
//  GraphRAGEngine.swift
//  Cinna
//
//  Created by Subhan Shrestha on 11/29/25.
//

import Foundation

/// GraphRAG-powered recommendation engine
class GraphRAGEngine {
    static let shared = GraphRAGEngine()
    
    private var graph = MovieGraph()
    private var isGraphBuilt = false
    private var cachedMovies: [TMDbMovie] = []
    
    private init() {}
    
    // MARK: - Build Graph
    
    /// Build the knowledge graph from fetched movies
    /// Call this after fetching movies from TMDb
    func buildGraph(from movies: [TMDbMovie], genreMapping: [Int: [Int]]) {
        guard !movies.isEmpty else {
            print("⚠️ No movies to build graph from")
            return
        }
        
        cachedMovies = movies
        graph.buildGraph(from: movies, genreMapping: genreMapping)
        isGraphBuilt = true
        
        let stats = graph.getStats()
        print("✅ GraphRAG built: \(stats.totalMovies) movies, \(stats.totalConnections) connections")
    }
    
    // MARK: - Get Recommendations
    
    /// Get GraphRAG-powered recommendations based on selected genres
    func getRecommendations(
        for genreIDs: [Int],
        limit: Int = 20
    ) -> [TMDbMovie] {
        guard isGraphBuilt else {
            print("⚠️ Graph not built yet, returning cached movies")
            return Array(cachedMovies.prefix(limit))
        }
        
        // Get recommendations from graph
        let nodes = graph.getRecommendations(for: genreIDs, limit: limit)
        
        // Convert nodes back to TMDbMovie
        return nodes.compactMap { node in
            cachedMovies.first { $0.id == node.id }
        }
    }
    
    /// Get movies similar to a given movie
    func getSimilarMovies(to movieID: Int, limit: Int = 10) -> [TMDbMovie] {
        guard isGraphBuilt else { return [] }
        
        let nodes = graph.getSimilarMovies(to: movieID, limit: limit)
        
        return nodes.compactMap { node in
            cachedMovies.first { $0.id == node.id }
        }
    }
    
    /// Get diverse recommendations using multi-hop graph traversal
    func getDiverseRecommendations(
        startingFrom movieID: Int,
        limit: Int = 20
    ) -> [TMDbMovie] {
        guard isGraphBuilt else { return [] }
        
        let nodes = graph.multiHopRecommendations(from: movieID, hops: 2, limit: limit)
        
        return nodes.compactMap { node in
            cachedMovies.first { $0.id == node.id }
        }
    }
    
    // MARK: - Graph Info
    
    func getGraphStats() -> GraphStats? {
        guard isGraphBuilt else { return nil }
        return graph.getStats()
    }
    
    func isReady() -> Bool {
        return isGraphBuilt
    }
    
    func reset() {
        graph = MovieGraph()
        isGraphBuilt = false
        cachedMovies = []
        print("🔄 GraphRAG reset")
    }
}
