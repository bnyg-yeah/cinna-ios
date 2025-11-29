//
//  MovieNode.swift
//  Cinna
//  Created by Subhan Shrestha on 11/29/25.
//

import Foundation

// MARK: - Movie Node (Graph Vertex)

/// Represents a movie as a node in the knowledge graph
struct MovieNode: Identifiable, Hashable {
    let id: Int
    let title: String
    let overview: String
    let releaseDate: String?
    let voteAverage: Double
    let genreIDs: [Int]
    
    // Graph-specific properties
    var connectedMovieIDs: Set<Int> = []  // IDs of movies this is connected to
    var genreConnections: Set<Int> = []   // Genre IDs for quick lookup
    var graphScore: Double = 0.0          // Centrality score (how well-connected)
    
    // Create from TMDbMovie
    init(from movie: TMDbMovie, genreIDs: [Int]) {
        self.id = movie.id
        self.title = movie.title
        self.overview = movie.overview
        self.releaseDate = movie.releaseDate
        self.voteAverage = movie.voteAverage
        self.genreIDs = genreIDs
        self.genreConnections = Set(genreIDs)
    }
    
    // Extract year as Int for comparisons
    var year: Int? {
        guard let releaseDate, releaseDate.count >= 4 else { return nil }
        return Int(releaseDate.prefix(4))
    }
    
    // Hash and equality based on ID only
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MovieNode, rhs: MovieNode) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Graph Edge (Connection)

/// Represents a relationship between two movies
struct MovieEdge: Hashable {
    let sourceID: Int
    let targetID: Int
    let weight: Double  // Strength of connection (0.0 to 1.0)
    let type: EdgeType
    
    enum EdgeType {
        case sharedGenre      // Movies share one or more genres
        case similarRating    // Movies have similar ratings
        case sameYear         // Released in same year
        case combined         // Multiple connection types
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
