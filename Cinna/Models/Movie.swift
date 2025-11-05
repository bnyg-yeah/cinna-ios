//
//  Movie.swift
//  Cinna
//
//  Created by Brighton Young on 11/5/25.
//

import Foundation

// MARK: - TMDb Models used across the app

/// Paged TMDb response for lists like discover/popular/now playing.
struct TMDbResponse: Codable {
    let results: [TMDbMovie]
    let page: Int
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case results, page
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

/// Lightweight movie model compatible with TMDb "list" endpoints.
/// Keep this lean so list fetches remain fast; details can live in a separate model later if needed.
struct TMDbMovie: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let originalTitle: String?
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String
    let genreIds: [Int]
    let voteAverage: Double
    let voteCount: Int
    let popularity: Double

    enum CodingKeys: String, CodingKey {
        case id, title, overview, popularity
        case originalTitle = "original_title"
        case posterPath   = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate  = "release_date"
        case genreIds     = "genre_ids"
        case voteAverage  = "vote_average"
        case voteCount    = "vote_count"
    }

    /// Full poster URL for display
    var posterURL: String? {
        guard let posterPath else { return nil }
        return "https://image.tmdb.org/t/p/w500\(posterPath)"
    }

    /// Year extracted from the release date (e.g., "2025")
    var year: String {
        String(releaseDate.prefix(4))
    }
}

// MARK: - Genre ↔︎ TMDb ID mapping used by discovery/recommendations

extension Genre {
    /// TMDb genre IDs
    var tmdbID: Int {
        switch self {
        case .action:      return 28
        case .comedy:      return 35
        case .drama:       return 18
        case .horror:      return 27
        case .romance:     return 10749
        case .scifi:       return 878
        case .thriller:    return 53
        case .animation:   return 16
        case .documentary: return 99
        case .fantasy:     return 14
        }
    }
}
