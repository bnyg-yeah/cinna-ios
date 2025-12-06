//
//  MovieGraph.swift
//  Cinna
//
//  Created by Subhan Shrestha on 11/29/25.
//

import Foundation

/// Knowledge graph that stores movies and their relationships
class MovieGraph {
    private var nodes: [Int: MovieNode] = [:]
    private var edges: Set<MovieEdge> = []
    private var genreIndex: [Int: Set<Int>] = [:]  // genreID -> Set of movieIDs
    
    // MARK: - Build Graph
    
    /// Build the graph from an array of TMDb movies
    func buildGraph(from movies: [TMDbMovie], genreMapping: [Int: [Int]]) {
        nodes.removeAll()
        edges.removeAll()
        genreIndex.removeAll()
        
        // Step 1: Create nodes
        for movie in movies {
            let genreIDs = genreMapping[movie.id] ?? []
            var node = MovieNode(movie: movie)
            
            // Set genre connections
            node.genreConnections = Set(genreIDs)
            nodes[movie.id] = node
            
            // Index by genre
            for genreID in genreIDs {
                genreIndex[genreID, default: []].insert(movie.id)
            }
        }
        
        // Step 2: Create edges (relationships)
        createEdges()
        
        // Step 3: Calculate graph scores (centrality)
        calculateGraphScores()
        
        print("📊 Graph built: \(nodes.count) movies, \(edges.count) connections")
    }
    
    // MARK: - Create Relationships
    
    private func createEdges() {
        let nodeArray = Array(nodes.values)
        
        for i in 0..<nodeArray.count {
            for j in (i+1)..<nodeArray.count {
                let node1 = nodeArray[i]
                let node2 = nodeArray[j]
                
                // Calculate connection weight
                if let weight = calculateConnectionWeight(node1, node2) {
                    let edge = MovieEdge(
                        sourceID: node1.id,
                        targetID: node2.id,
                        weight: weight,
                        type: .combined
                    )
                    edges.insert(edge)
                    
                    // Update node connections
                    nodes[node1.id]?.connectedMovieIDs.insert(node2.id)
                    nodes[node2.id]?.connectedMovieIDs.insert(node1.id)
                }
            }
        }
    }
    
    /// Calculate how strongly two movies are connected
    private func calculateConnectionWeight(_ node1: MovieNode, _ node2: MovieNode) -> Double? {
        var weight: Double = 0.0

        // shared genres
        let sharedGenres = node1.genreConnections.intersection(node2.genreConnections)
        if !sharedGenres.isEmpty {
            weight += 0.5 * (
                Double(sharedGenres.count) /
                Double(max(node1.genreConnections.count, node2.genreConnections.count))
            )
        }

        // rating similarity
        let ratingDiff = abs(node1.movie.voteAverage - node2.movie.voteAverage)
        if ratingDiff < 2.0 {
            weight += 0.3 * (1.0 - ratingDiff / 2.0)
        }

        return weight > 0.3 ? weight : nil
    }

    
    // MARK: - Graph Scores (Centrality)
    
    /// Calculate how "central" or "important" each movie is in the graph
    private func calculateGraphScores() {
        for (id, node) in nodes {
            let degree = Double(node.connectedMovieIDs.count)
            
            let weightedScore = edges
                .filter { $0.sourceID == id || $0.targetID == id }
                .reduce(0.0) { $0 + $1.weight }
            
            let centralityScore = (degree / 10.0) + (weightedScore / 5.0) + (node.movie.voteAverage / 10.0)
            
            nodes[id]?.graphScore = centralityScore
        }
    }
    
    // MARK: - User Ratings Integration
    
    /// Apply user ratings to boost graph scores (1-4 star scale)
    func applyUserRatings(_ ratings: [Int: Int]) {
        guard !ratings.isEmpty else { return }
        
        for (movieID, userRating) in ratings {
            guard var node = nodes[movieID] else { continue }
            
            // Direct boost based on user rating (1-4 scale)
            let directBoost = Double(userRating) * 2.0  // 1→2.0, 2→4.0, 3→6.0, 4→8.0
            node.graphScore += directBoost
            
            // Also boost connected movies (spread the preference)
            if userRating >= 3 {  // High rating (3-4 stars)
                let connectionBoost = Double(userRating - 2) * 1.5  // 3→1.5, 4→3.0
                
                for connectedID in node.connectedMovieIDs {
                    nodes[connectedID]?.graphScore += connectionBoost
                }
            }
            
            // Penalize connected movies for low ratings
            if userRating <= 2 {  // Low rating (1-2 stars)
                let penalty = Double(3 - userRating) * 0.5  // 1→-1.0, 2→-0.5
                
                for connectedID in node.connectedMovieIDs {
                    nodes[connectedID]?.graphScore -= penalty
                }
            }
            
            nodes[movieID] = node
        }
        
        print("⭐ Applied \(ratings.count) user ratings to graph")
    }

    
    // MARK: - Query Interface
    
    /// Get movies connected to any of the given genre IDs
    func getMoviesForGenres(_ genreIDs: [Int]) -> [MovieNode] {
        var movieIDs: Set<Int> = []
        
        for genreID in genreIDs {
            if let ids = genreIndex[genreID] {
                movieIDs.formUnion(ids)
            }
        }
        
        return movieIDs.compactMap { nodes[$0] }
    }
    
    /// Get movies similar to a given movie (connected in graph)
    func getSimilarMovies(to movieID: Int, limit: Int = 10) -> [MovieNode] {
        guard let node = nodes[movieID] else { return [] }
        
        return node.connectedMovieIDs
            .compactMap { nodes[$0] }
            .sorted { $0.graphScore > $1.graphScore }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Multi-hop traversal: find movies N steps away
    func multiHopRecommendations(from movieID: Int, hops: Int = 2, limit: Int = 20) -> [MovieNode] {
        var visited: Set<Int> = [movieID]
        var currentLevel: Set<Int> = [movieID]
        
        for _ in 0..<hops {
            var nextLevel: Set<Int> = []
            
            for id in currentLevel {
                if let node = nodes[id] {
                    for connectedID in node.connectedMovieIDs where !visited.contains(connectedID) {
                        nextLevel.insert(connectedID)
                        visited.insert(connectedID)
                    }
                }
            }
            
            currentLevel = nextLevel
        }
        
        // Remove original movie from results
        visited.remove(movieID)
        
        return visited
            .compactMap { nodes[$0] }
            .sorted { $0.graphScore > $1.graphScore }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Get top recommended movies based on graph structure and genres
    func getRecommendations(for genreIDs: [Int], limit: Int = 20) -> [MovieNode] {
        // Get all movies matching genres
        var candidates = getMoviesForGenres(genreIDs)
        
        // Sort by graph score (combines centrality + rating)
        candidates.sort { $0.graphScore > $1.graphScore }
        
        return Array(candidates.prefix(limit))
    }
    
    // MARK: - Stats
    
    func getStats() -> GraphStats {
        GraphStats(
            totalMovies: nodes.count,
            totalConnections: edges.count,
            averageConnections: Double(edges.count) / Double(max(nodes.count, 1)),
            genresIndexed: genreIndex.count
        )
    }
}

// MARK: - Graph Statistics

struct GraphStats {
    let totalMovies: Int
    let totalConnections: Int
    let averageConnections: Double
    let genresIndexed: Int
}
