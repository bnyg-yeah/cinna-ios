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
        case sameYear
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
