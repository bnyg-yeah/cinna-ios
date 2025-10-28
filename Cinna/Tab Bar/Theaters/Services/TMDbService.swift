//
//  TMDbService.swift
//  Cinna
//
//  Created by Chao Chen on 10/27/25.
//
import Foundation

/// Service for The Movie Database (TMDb) API
/// Provides proper genre filtering and popularity sorting
struct TMDbService {
    private static let baseURL = "https://api.themoviedb.org/3"
    private static let apiKey = "b3c3d5efe257f9cfefeaeeeb851ee431"
    
    // MARK: - Discover Movies (Best for Recommendations)
    
    /// Discover movies by genre with popularity sorting
    /// - Parameters:
    ///   - genreIDs: Array of TMDb genre IDs
    ///   - page: Page number
    /// - Returns: Array of movies
    static func discoverMovies(
        genreIDs: [Int],
        page: Int = 1
    ) async throws -> [TMDbMovie] {
        var components = URLComponents(string: "\(baseURL)/discover/movie")
        
        let genreString = genreIDs.map { String($0) }.joined(separator: ",")
        let currentYear = Calendar.current.component(.year, from: Date())
        
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "with_genres", value: genreString),
            URLQueryItem(name: "primary_release_year", value: String(currentYear)),
            URLQueryItem(name: "sort_by", value: "popularity.desc"),  // Sort by popularity!
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "vote_count.gte", value: "10")  // At least 10 votes (filters obscure movies)
        ]
        
        guard let url = components?.url else {
            throw APIError.badURL
        }
        
        let response: TMDbResponse = try await APIClient.getJSON(url)
        return response.results
    }
    
    /// Get popular movies (no genre filter)
    static func getPopularMovies(page: Int = 1) async throws -> [TMDbMovie] {
        var components = URLComponents(string: "\(baseURL)/movie/popular")
        
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "page", value: String(page))
        ]
        
        guard let url = components?.url else {
            throw APIError.badURL
        }
        
        let response: TMDbResponse = try await APIClient.getJSON(url)
        return response.results
    }
    
    /// Get now playing movies in theaters
    static func getNowPlaying(page: Int = 1) async throws -> [TMDbMovie] {
        var components = URLComponents(string: "\(baseURL)/movie/now_playing")
        
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "page", value: String(page))
        ]
        
        guard let url = components?.url else {
            throw APIError.badURL
        }
        
        let response: TMDbResponse = try await APIClient.getJSON(url)
        return response.results
    }
}

// MARK: - TMDb Models

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
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case genreIds = "genre_ids"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
    
    /// Full poster URL
    var posterURL: String? {
        guard let posterPath = posterPath else { return nil }
        return "https://image.tmdb.org/t/p/w500\(posterPath)"
    }
    
    /// Year from release date
    var year: String {
        String(releaseDate.prefix(4))
    }
}

// MARK: - Genre ID Mapping

extension Genre {
    /// TMDb genre IDs
    var tmdbID: Int {
        switch self {
        case .action: return 28
        case .comedy: return 35
        case .drama: return 18
        case .horror: return 27
        case .romance: return 10749
        case .scifi: return 878
        case .thriller: return 53
        case .animation: return 16
        case .documentary: return 99
        case .fantasy: return 14
        }
    }
}
