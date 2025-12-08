//
//  MovieNode.swift
//  Cinna
//  Created by Subhan Shrestha on 11/29/25.
//

import Foundation

struct MovieNode: Identifiable, Hashable {
    let movie: TMDbMovie
    var id: Int { movie.id }
    var connectedMovieIDs: Set<Int> = []
    var genreConnections: Set<Int> = []
    var graphScore: Double = 0.0
    
    // NEW: Embedding data
    var textEmbedding: [Float]? = nil  // Semantic vector from reviews/description
    var sourceText: String? = nil       // Text used to generate embedding
    
    // NEW: Filmmaking quality scores (derived from embeddings)
    var actingScore: Double = 0.0
    var directingScore: Double = 0.0
    var cinematographyScore: Double = 0.0
    var writingScore: Double = 0.0
    var soundScore: Double = 0.0
    var visualEffectsScore: Double = 0.0
    
    //Animation quality scores
    var animationQualityScore: Double = 0.0
    var twoDAnimationScore: Double = 0.0
    var threeDAnimationScore: Double = 0.0
    var stopMotionScore: Double = 0.0
    var animeScore: Double = 0.0
    var stylizedArtScore: Double = 0.0

    init(movie: TMDbMovie) {
        self.movie = movie
        if let ids = movie.genreIDs {
            self.genreConnections = Set(ids)
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MovieNode, rhs: MovieNode) -> Bool {
        lhs.id == rhs.id
    }
}

struct MovieEdge: Hashable {
    let sourceID: Int
    let targetID: Int
    let weight: Double
    let type: EdgeType
    
    enum EdgeType {
        case sharedGenre
        case similarRating
        case semanticSimilarity  // NEW: Based on embedding similarity
        case combined
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(sourceID)
        hasher.combine(targetID)
    }
    
    static func == (lhs: MovieEdge, rhs: MovieEdge) -> Bool {
        (lhs.sourceID == rhs.sourceID && lhs.targetID == rhs.targetID) ||
        (lhs.sourceID == rhs.targetID && lhs.targetID == rhs.sourceID)
    }
}
