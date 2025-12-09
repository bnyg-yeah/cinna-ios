//
//  MovieGraph.swift
//  Cinna
//
//  Created by Subhan Shrestha on 11/29/25.
//  Enhanced with embedding-based semantic similarity
//

import Foundation

/// Knowledge graph that stores movies and their relationships with semantic understanding
class MovieGraph {
    private var nodes: [Int: MovieNode] = [:]
    private var edges: Set<MovieEdge> = []
    private var genreIndex: [Int: Set<Int>] = [:]  // genreID -> Set of movieIDs
    
    // Store preference embeddings for quality score calculation
    private var preferenceEmbeddings: PreferenceEmbeddings?
    
    // MARK: - Build Graph with Embeddings
    
    /// Build the graph from an array of TMDb movies with semantic embeddings
    func buildGraph(
        from movies: [TMDbMovie],
        genreMapping: [Int: [Int]],
        movieTexts: [Int: String],
        movieEmbeddings: [Int: [Float]]
    ) {
        nodes.removeAll()
        edges.removeAll()
        genreIndex.removeAll()
        
        // Step 1: Create nodes with embeddings
        for movie in movies {
            let genreIDs = genreMapping[movie.id] ?? []
            var node = MovieNode(movie: movie)
            
            // Set genre connections
            node.genreConnections = Set(genreIDs)
            
            // Set embedding data
            node.sourceText = movieTexts[movie.id]
            node.textEmbedding = movieEmbeddings[movie.id]
            
            nodes[movie.id] = node
            
            // Index by genre
            for genreID in genreIDs {
                genreIndex[genreID, default: []].insert(movie.id)
            }
        }
        
        // Step 2: Create edges (relationships) with semantic similarity
        createEdges()
        
        // Step 3: Calculate graph scores (centrality)
        calculateGraphScores()
        
        print("📊 Graph built: \(nodes.count) movies, \(edges.count) connections")
    }
    
    // MARK: - Create Relationships with Semantic Similarity
    
    private func createEdges() {
        let nodeArray = Array(nodes.values)
        
        for i in 0..<nodeArray.count {
            for j in (i+1)..<nodeArray.count {
                let node1 = nodeArray[i]
                let node2 = nodeArray[j]
                
                // Calculate connection weight (includes semantic similarity)
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
    
    /// Calculate how strongly two movies are connected (including semantic similarity)
    private func calculateConnectionWeight(_ node1: MovieNode, _ node2: MovieNode) -> Double? {
        var weight: Double = 0.0

        // 1. Shared genres (20% weight)
        let sharedGenres = node1.genreConnections.intersection(node2.genreConnections)
        if !sharedGenres.isEmpty {
            weight += 0.2 * (
                Double(sharedGenres.count) /
                Double(max(node1.genreConnections.count, node2.genreConnections.count))
            )
        }

        // 2. Rating similarity (15% weight)
        let ratingDiff = abs(node1.movie.voteAverage - node2.movie.voteAverage)
        if ratingDiff < 2.0 {
            weight += 0.15 * (1.0 - ratingDiff / 2.0)
        }
        
        // 3. Semantic similarity (65% weight) - NEW!
        if let emb1 = node1.textEmbedding, let emb2 = node2.textEmbedding {
            let similarity = EmbeddingService.cosineSimilarity(emb1, emb2)
            weight += 0.65 * Double(similarity)
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
    
    // MARK: - Calculate Filmmaking Quality Scores
    
    /// Calculate filmmaking quality scores by comparing movie embeddings to preference embeddings
    func calculateFilmmakingScores(preferenceEmbeddings: PreferenceEmbeddings) {
        self.preferenceEmbeddings = preferenceEmbeddings
        
        var debugCount = 0
        
        for (id, node) in nodes {
            guard let movieEmbedding = node.textEmbedding else { continue }
            
            // Calculate similarity to each preference dimension
            if let actingEmb = preferenceEmbeddings.actingEmbedding {
                let similarity = EmbeddingService.cosineSimilarity(movieEmbedding, actingEmb)
                // Simple linear scaling: 0.0 → 0, 0.5 → 5.0, 1.0 → 10.0
                nodes[id]?.actingScore = Double(similarity) * 10.0
            }

            if let directingEmb = preferenceEmbeddings.directingEmbedding {
                let similarity = EmbeddingService.cosineSimilarity(movieEmbedding, directingEmb)
                nodes[id]?.directingScore = Double(similarity) * 10.0
            }

            if let cinematographyEmb = preferenceEmbeddings.cinematographyEmbedding {
                let similarity = EmbeddingService.cosineSimilarity(movieEmbedding, cinematographyEmb)
                nodes[id]?.cinematographyScore = Double(similarity) * 10.0
                
                // DEBUG: Print first 5 movies
                if debugCount < 5 {
                    print("🔍 Movie: \(node.movie.title)")
                    print("   Similarity: \(String(format: "%.3f", similarity))")
                    print("   Score: \(String(format: "%.2f", Double(similarity) * 10.0))/10")
                    debugCount += 1
                }
            }

            if let writingEmb = preferenceEmbeddings.writingEmbedding {
                let similarity = EmbeddingService.cosineSimilarity(movieEmbedding, writingEmb)
                nodes[id]?.writingScore = Double(similarity) * 10.0
            }

            if let soundEmb = preferenceEmbeddings.soundEmbedding {
                let similarity = EmbeddingService.cosineSimilarity(movieEmbedding, soundEmb)
                nodes[id]?.soundScore = Double(similarity) * 10.0
            }

            if let vfxEmb = preferenceEmbeddings.visualEffectsEmbedding {
                let similarity = EmbeddingService.cosineSimilarity(movieEmbedding, vfxEmb)
                nodes[id]?.visualEffectsScore = Double(similarity) * 10.0
            }
            // Debug: print full scores for first movie (updated values)
            if id == nodes.keys.first {
                if let updated = nodes[id] {
                    print("\n🎬 FULL SCORES FOR: \(updated.movie.title)")
                    print("   Acting: \(String(format: "%.2f", updated.actingScore))")
                    print("   Directing: \(String(format: "%.2f", updated.directingScore))")
                    print("   Cinematography: \(String(format: "%.2f", updated.cinematographyScore))")
                    print("   Writing: \(String(format: "%.2f", updated.writingScore))")
                    print("   Sound: \(String(format: "%.2f", updated.soundScore))")
                    print("   VFX: \(String(format: "%.2f", updated.visualEffectsScore))")
                }
            }

        }
        
        print("✅ Calculated filmmaking scores for \(nodes.count) movies")
    }
    
    // MARK: - User Ratings Integration
    
    /// Apply user ratings to boost graph scores (1-4 star scale)
    func applyUserRatings(_ ratings: [Int: Int]) {
        guard !ratings.isEmpty else { return }
        
        for (movieID, userRating) in ratings {
            guard var node = nodes[movieID] else { continue }
            
            if userRating >= 3 {
                // HIGH RATING (3-4 stars) → BOOST
                let directBoost = Double(userRating) * 2.0  // 3→6.0, 4→8.0
                node.graphScore += directBoost
                
                // Boost connected movies
                let connectionBoost = Double(userRating - 2) * 1.5  // 3→1.5, 4→3.0
                for connectedID in node.connectedMovieIDs {
                    nodes[connectedID]?.graphScore += connectionBoost
                }
                
            } else {
                // LOW RATING (1-2 stars) → PENALTY
                let directPenalty = Double(3 - userRating) * 2.0  // 2→-2.0, 1→-4.0
                node.graphScore -= directPenalty
                
                // Penalize connected movies
                let connectionPenalty = Double(3 - userRating) * 0.5  // 2→-0.5, 1→-1.0
                for connectedID in node.connectedMovieIDs {
                    nodes[connectedID]?.graphScore -= connectionPenalty
                }
            }
            
            nodes[movieID] = node
        }
        
        print("⭐ Applied \(ratings.count) user ratings to graph")
    }
    
    // MARK: - Filmmaking Preferences Integration
    
    /// Apply filmmaking preferences using embedding-based quality scores
    func applyFilmmakingPreferences(_ preferences: Set<FilmmakingPreferences>) {
        guard !preferences.isEmpty else { return }
        
        // Calculate average score for each preference to use as baseline
        var avgScores: [FilmmakingPreferences: Double] = [:]
        for preference in preferences {
            var total = 0.0
            var count = 0
            for node in nodes.values {
                let score: Double
                switch preference {
                case .acting: score = node.actingScore
                case .directing: score = node.directingScore
                case .cinematography: score = node.cinematographyScore
                case .writing: score = node.writingScore
                case .sound: score = node.soundScore
                case .visualEffects: score = node.visualEffectsScore
                }
                total += score
                count += 1
            }
            avgScores[preference] = total / Double(max(count, 1))
        }
        
        // Track which movies got boosted
        var boostedMovies: [(title: String, score: Double, boost: Double)] = []
        
        for (id, node) in nodes {
            var boost = 0.0
            
            for preference in preferences {
                let score: Double
                switch preference {
                case .acting: score = node.actingScore
                case .directing: score = node.directingScore
                case .cinematography: score = node.cinematographyScore
                case .writing: score = node.writingScore
                case .sound: score = node.soundScore
                case .visualEffects: score = node.visualEffectsScore
                }
                
                let avg = avgScores[preference] ?? 0
                
                // Boost movies that score above average
                if score > avg {
                    let individualBoost = (score - avg) * 2.0  // 2x multiplier for above-average
                    boost += individualBoost
                    
                    // Track for debugging
                    if preference == .cinematography {
                        boostedMovies.append((node.movie.title, score, individualBoost))
                    }
                }
            }
            
            nodes[id]?.graphScore += boost
        }
        
        // Print top 10 boosted movies for cinematography
        if preferences.contains(.cinematography) {
            let avg = avgScores[.cinematography] ?? 0
            boostedMovies.sort { $0.score > $1.score }
            print("📊 CINEMATOGRAPHY SCORES (Average: \(String(format: "%.2f", avg))):")
            for (index, movie) in boostedMovies.prefix(10).enumerated() {
                print("  \(index + 1). \(movie.title): \(String(format: "%.2f", movie.score))/10 (boost: +\(String(format: "%.2f", movie.boost)))")
            }
            print("📊 Total movies boosted: \(boostedMovies.count)")
        }
        
        print("🎬 Applied \(preferences.count) filmmaking preferences")
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
    
    /// Get movies similar to a given movie (connected in graph by semantic similarity)
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
        
        // Sort by graph score (combines centrality + rating + user preferences)
        candidates.sort { $0.graphScore > $1.graphScore }
        
        return Array(candidates.prefix(limit))
    }
    
    // MARK: - Get Filmmaking Scores
    
    /// Get filmmaking scores for a specific movie
    func getFilmmakingScores(for movieID: Int) -> FilmmakingScoresSummary? {
        guard let node = nodes[movieID] else { return nil }
        
        return FilmmakingScoresSummary(
            movieID: movieID,
            movieTitle: node.movie.title,
            actingScore: node.actingScore,
            directingScore: node.directingScore,
            cinematographyScore: node.cinematographyScore,
            writingScore: node.writingScore,
            soundScore: node.soundScore,
            visualEffectsScore: node.visualEffectsScore
        )
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

struct FilmmakingScoresSummary {
    let movieID: Int
    let movieTitle: String
    let actingScore: Double
    let directingScore: Double
    let cinematographyScore: Double
    let writingScore: Double
    let soundScore: Double
    let visualEffectsScore: Double
}
