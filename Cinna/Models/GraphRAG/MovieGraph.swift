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
    private static var didPrintDebugScores = false
    private var nodes: [Int: MovieNode] = [:]
    private var edges: Set<MovieEdge> = []
    private var genreIndex: [Int: Set<Int>] = [:]  // genreID -> Set of movieIDs
    private let animationGenreID = 16
    

    
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
    
    func calculateFilmmakingScores(preferenceEmbeddings: PreferenceEmbeddings) {
        self.preferenceEmbeddings = preferenceEmbeddings

        for (id, node) in nodes {
            guard let movieEmbedding = node.textEmbedding else { continue }
            let R = node.movie.voteAverage   // global rating 0–10

            // --- Acting ---
            if let emb = preferenceEmbeddings.actingEmbedding {
                let T = Double(EmbeddingService.cosineSimilarity(movieEmbedding, emb)) * 10.0
                nodes[id]?.actingScore = 0.4 * R + 0.6 * T
            }

            // --- Directing ---
            if let emb = preferenceEmbeddings.directingEmbedding {
                let T = Double(EmbeddingService.cosineSimilarity(movieEmbedding, emb)) * 10.0
                nodes[id]?.directingScore = 0.5 * R + 0.5 * T
            }

            // --- Writing ---
            if let emb = preferenceEmbeddings.writingEmbedding {
                let T = Double(EmbeddingService.cosineSimilarity(movieEmbedding, emb)) * 10.0
                nodes[id]?.writingScore = 0.4 * R + 0.6 * T
            }

            // --- Cinematography ---
            if let emb = preferenceEmbeddings.cinematographyEmbedding {
                let T = Double(EmbeddingService.cosineSimilarity(movieEmbedding, emb)) * 10.0
                nodes[id]?.cinematographyScore = 0.3 * R + 0.7 * T
            }

            // --- Sound ---
            if let emb = preferenceEmbeddings.soundEmbedding {
                let T = Double(EmbeddingService.cosineSimilarity(movieEmbedding, emb)) * 10.0
                nodes[id]?.soundScore = 0.3 * R + 0.7 * T
            }

            // --- Visual Effects ---
            if let emb = preferenceEmbeddings.visualEffectsEmbedding {
                let T = Double(EmbeddingService.cosineSimilarity(movieEmbedding, emb)) * 10.0
                nodes[id]?.visualEffectsScore = 0.3 * R + 0.7 * T
            }
        }
        // ================= TEST BLOCK A: Final Scores for Top Movies =================

        if !MovieGraph.didPrintDebugScores {
            MovieGraph.didPrintDebugScores = true

            print("\n========== TEST: FINAL FILMMAKING SCORES (Top 5 Movies) ==========\n")

            let sampleMovies = nodes.values.prefix(5)

            for node in sampleMovies {
                let title = node.movie.title
                let R = node.movie.voteAverage

                print("🎬 \(title)")
                print("  Rating (R): \(String(format: "%.2f", R))")
                print("  Acting Score: \(String(format: "%.2f", node.actingScore))")
                print("  Directing Score: \(String(format: "%.2f", node.directingScore))")
                print("  Cinematography Score: \(String(format: "%.2f", node.cinematographyScore))")
                print("  Writing Score: \(String(format: "%.2f", node.writingScore))")
                print("  Sound Score: \(String(format: "%.2f", node.soundScore))")
                print("  VFX Score: \(String(format: "%.2f", node.visualEffectsScore))")
                print("--------------------------------------------\n")
            }

            print("===================================================================\n")
        }


    }


    // MARK: - Calculate Animation Scores
    
    /// Calculate animation quality/style scores using embeddings and TMDb metadata
    func calculateAnimationScores(preferenceEmbeddings: PreferenceEmbeddings) {
        for (id, node) in nodes {
            // Only compute animation scores for animated films
            guard node.genreConnections.contains(animationGenreID) else { continue }
            
            var animQualityScore = node.animationQualityScore
            var twoDScore = node.twoDAnimationScore
            var threeDScore = node.threeDAnimationScore
            var stopMotionScore = node.stopMotionScore
            var animeScore = node.animeScore
            var stylizedArtScore = node.stylizedArtScore
            
            if let movieEmbedding = node.textEmbedding {
                if let qualityEmb = preferenceEmbeddings.animationQualityEmbedding {
                    animQualityScore = max(animQualityScore, Double(EmbeddingService.cosineSimilarity(movieEmbedding, qualityEmb)) * 10.0)
                }
                if let twoDEmb = preferenceEmbeddings.twoDEmbedding {
                    twoDScore = max(twoDScore, Double(EmbeddingService.cosineSimilarity(movieEmbedding, twoDEmb)) * 10.0)
                }
                if let threeDEmb = preferenceEmbeddings.threeDEmbedding {
                    threeDScore = max(threeDScore, Double(EmbeddingService.cosineSimilarity(movieEmbedding, threeDEmb)) * 10.0)
                }
                if let stopMotionEmb = preferenceEmbeddings.stopMotionEmbedding {
                    stopMotionScore = max(stopMotionScore, Double(EmbeddingService.cosineSimilarity(movieEmbedding, stopMotionEmb)) * 10.0)
                }
                if let animeEmb = preferenceEmbeddings.animeEmbedding {
                    animeScore = max(animeScore, Double(EmbeddingService.cosineSimilarity(movieEmbedding, animeEmb)) * 10.0)
                }
                if let stylizedEmb = preferenceEmbeddings.stylizedArtEmbedding {
                    stylizedArtScore = max(stylizedArtScore, Double(EmbeddingService.cosineSimilarity(movieEmbedding, stylizedEmb)) * 10.0)
                }
            }
            
            if node.genreConnections.contains(animationGenreID) {
                animQualityScore += 2.5
                twoDScore += 1.0
                threeDScore += 1.0
            }
            
            if let text = node.sourceText?.lowercased() {
                if text.contains("stop-motion") || text.contains("stop motion") {
                    stopMotionScore += 3.0
                }
                if text.contains("anime") {
                    animeScore += 3.0
                }
                if text.contains("2d") || text.contains("hand-drawn") || text.contains("hand drawn") {
                    twoDScore += 2.0
                }
                if text.contains("cgi") || text.contains("3d") || text.contains("computer generated") {
                    threeDScore += 2.0
                }
                if text.contains("stylized") || text.contains("art style") || text.contains("painterly") {
                    stylizedArtScore += 2.5
                }
                if text.contains("animation") {
                    animQualityScore += 1.0
                }
            }
            
            nodes[id]?.animationQualityScore = animQualityScore
            nodes[id]?.twoDAnimationScore = twoDScore
            nodes[id]?.threeDAnimationScore = threeDScore
            nodes[id]?.stopMotionScore = stopMotionScore
            nodes[id]?.animeScore = animeScore
            nodes[id]?.stylizedArtScore = stylizedArtScore
        }
        
        print("✨ Calculated animation scores for animated films only")
    }
    
    func calculateStudioScores(preferenceEmbeddings: PreferenceEmbeddings) {
        for (id, node) in nodes {
            guard let movieEmbedding = node.textEmbedding else { continue }
            
            if let disneyEmbedding = preferenceEmbeddings.disneyEmbedding {
                let score = EmbeddingService.cosineSimilarity(movieEmbedding, disneyEmbedding)
                nodes[id]?.disneyScore = Double(score) * 10.0
            }
            if let universalEmbedding = preferenceEmbeddings.universalEmbedding {
                let score = EmbeddingService.cosineSimilarity(movieEmbedding, universalEmbedding)
                nodes[id]?.universalScore = Double(score) * 10.0
            }
            if let warnerBrosEmbedding = preferenceEmbeddings.warnerBrosEmbedding {
                let score = EmbeddingService.cosineSimilarity(movieEmbedding, warnerBrosEmbedding)
                nodes[id]?.warnerBrosScore = Double(score) * 10.0
            }
            if let pixarEmbedding = preferenceEmbeddings.pixarEmbedding {
                let score = EmbeddingService.cosineSimilarity(movieEmbedding, pixarEmbedding)
                nodes[id]?.pixarScore = Double(score) * 10.0
            }
            if let illuminationEmbedding = preferenceEmbeddings.illuminationEmbedding {
                let score = EmbeddingService.cosineSimilarity(movieEmbedding, illuminationEmbedding)
                nodes[id]?.illuminationScore = Double(score) * 10.0
            }
            if let marvelEmbedding = preferenceEmbeddings.marvelEmbedding {
                let score = EmbeddingService.cosineSimilarity(movieEmbedding, marvelEmbedding)
                nodes[id]?.marvelScore = Double(score) * 10.0
            }

        }
        
        
        print("🏢 Calculated studio scores for \(nodes.count) movies")
    }

    func calculateThemeScores(preferenceEmbeddings: PreferenceEmbeddings) {
        for (id, node) in nodes {
            guard let movieEmbedding = node.textEmbedding else { continue }
            
            if let emb = preferenceEmbeddings.lightheartedThemeEmbedding {
                let score = EmbeddingService.cosineSimilarity(movieEmbedding, emb)
                nodes[id]?.lightheartedThemeScore = Double(score) * 10.0
            }
            if let emb = preferenceEmbeddings.darkThemeEmbedding {
                let score = EmbeddingService.cosineSimilarity(movieEmbedding, emb)
                nodes[id]?.darkThemeScore = Double(score) * 10.0
            }
            if let emb = preferenceEmbeddings.emotionalThemeEmbedding {
                let score = EmbeddingService.cosineSimilarity(movieEmbedding, emb)
                nodes[id]?.emotionalThemeScore = Double(score) * 10.0
            }
            if let emb = preferenceEmbeddings.comingOfAgeThemeEmbedding {
                let score = EmbeddingService.cosineSimilarity(movieEmbedding, emb)
                nodes[id]?.comingOfAgeThemeScore = Double(score) * 10.0
            }
            if let emb = preferenceEmbeddings.survivalThemeEmbedding {
                let score = EmbeddingService.cosineSimilarity(movieEmbedding, emb)
                nodes[id]?.survivalThemeScore = Double(score) * 10.0
            }
            if let emb = preferenceEmbeddings.relaxingThemeEmbedding {
                let score = EmbeddingService.cosineSimilarity(movieEmbedding, emb)
                nodes[id]?.relaxingThemeScore = Double(score) * 10.0
            }
            if let emb = preferenceEmbeddings.learningThemeEmbedding {
                let score = EmbeddingService.cosineSimilarity(movieEmbedding, emb)
                nodes[id]?.learningThemeScore = Double(score) * 10.0
            }
        }
        
        print("🎭 Calculated theme scores for \(nodes.count) movies")
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
    
    // MARK: Preferences Integration
    
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
    
    /// Apply animation preferences using animation-specific quality/style scores
    func applyAnimationPreferences(_ preferences: Set<AnimationPreferences>) {
        guard !preferences.isEmpty else { return }
        
        var calculatedCount = 0
        
        for (id, node) in nodes {
            // Only apply to animated films (animation genre present)
            guard node.genreConnections.contains(animationGenreID) else { continue }
            
            var boost = 0.0
            
            for preference in preferences {
                let score: Double
                switch preference {
                case .animationQuality:
                    score = node.animationQualityScore
                case .twoD:
                    score = node.twoDAnimationScore
                case .threeD:
                    score = node.threeDAnimationScore
                case .stopMotion:
                    score = node.stopMotionScore
                case .anime:
                    score = node.animeScore
                case .stylizedArt:
                    score = node.stylizedArtScore
                }
                
                if score >= 6.0 {
                    boost += (score - 5.0) * 0.5
                }
            }
            
            let oldScore = nodes[id]?.graphScore ?? 0
            let newScore = oldScore + boost
            nodes[id]?.graphScore = newScore

            if boost > 0 {
                print("""
                🎨 Animation Preference Applied → \(node.movie.title)
                    Scores:
                        quality: \(String(format: "%.2f", node.animationQualityScore))
                        2D: \(String(format: "%.2f", node.twoDAnimationScore))
                        3D: \(String(format: "%.2f", node.threeDAnimationScore))
                        stopMotion: \(String(format: "%.2f", node.stopMotionScore))
                        anime: \(String(format: "%.2f", node.animeScore))
                        stylized: \(String(format: "%.2f", node.stylizedArtScore))
                    Boost Applied: +\(String(format: "%.2f", boost))
                    GraphScore: \(String(format: "%.2f", oldScore)) → \(String(format: "%.2f", newScore))
                """)
            }

        }
        
        
    }
    
    func applyStudioPreferences(_ preferences: Set<StudioPreferences>) {
        guard !preferences.isEmpty else { return }
        
        for (id, node) in nodes {
            var boost = 0.0
            
            for preference in preferences {
                let score: Double
                switch preference {
                case .Disney:
                    score = node.disneyScore
                case .Universal:
                    score = node.universalScore
                case .WarnerBros:
                    score = node.warnerBrosScore
                case .Pixar:
                    score = node.pixarScore
                case .Illumination:
                    score = node.illuminationScore
                case .Marvel:
                    score = node.marvelScore
                }
                
                if score >= 2.0 {
                    boost += (score - 5.0) * 0.5
                }
            }
            
            let oldScore = nodes[id]?.graphScore ?? 0
            let newScore = oldScore + boost
            nodes[id]?.graphScore = newScore

            if boost > 0 {
                print("""
                🏢 Studio Preference Applied → \(node.movie.title)
                    Scores:
                        Disney: \(String(format: "%.2f", node.disneyScore))
                        Pixar: \(String(format: "%.2f", node.pixarScore))
                        Illumination: \(String(format: "%.2f", node.illuminationScore))
                        Universal: \(String(format: "%.2f", node.universalScore))
                        WarnerBros: \(String(format: "%.2f", node.warnerBrosScore))
                        Marvel: \(String(format: "%.2f", node.marvelScore))
                    Boost Applied: +\(String(format: "%.2f", boost))
                    GraphScore: \(String(format: "%.2f", oldScore)) → \(String(format: "%.2f", newScore))
                """)
            }

        }
        
        print("🏢 Applied \(preferences.count) studio preferences")
    }

    func applyThemePreferences(_ preferences: Set<ThemePreferences>) {
        guard !preferences.isEmpty else { return }
        
        for (id, node) in nodes {
            var boost = 0.0
            
            for preference in preferences {
                let score: Double
                switch preference {
                case .Lighthearted:
                    score = node.lightheartedThemeScore
                case .Dark:
                    score = node.darkThemeScore
                case .Emotional:
                    score = node.emotionalThemeScore
                case .ComingOfAge:
                    score = node.comingOfAgeThemeScore
                case .Survival:
                    score = node.survivalThemeScore
                case .Relaxing:
                    score = node.relaxingThemeScore
                case .Learning:
                    score = node.learningThemeScore
                }
                
                if score >= 2.0 {
                    boost += (score - 5.0) * 0.5
                }
            }
            
            let oldScore = nodes[id]?.graphScore ?? 0
            let newScore = oldScore + boost
            nodes[id]?.graphScore = newScore

            if boost > 0 {
                print("""
                🎭 Theme Preference Applied → \(node.movie.title)
                    Scores:
                        lighthearted: \(String(format: "%.2f", node.lightheartedThemeScore))
                        dark: \(String(format: "%.2f", node.darkThemeScore))
                        emotional: \(String(format: "%.2f", node.emotionalThemeScore))
                        comingOfAge: \(String(format: "%.2f", node.comingOfAgeThemeScore))
                        survival: \(String(format: "%.2f", node.survivalThemeScore))
                        relaxing: \(String(format: "%.2f", node.relaxingThemeScore))
                        learning: \(String(format: "%.2f", node.learningThemeScore))
                    Boost Applied: +\(String(format: "%.2f", boost))
                    GraphScore: \(String(format: "%.2f", oldScore)) → \(String(format: "%.2f", newScore))
                """)
            }

        }
        
        print("🎭 Applied \(preferences.count) theme preferences")
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
