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
    
    // Keep this in TMDbService.swift so it can access the private constants.
    static func makeURL(_ path: String, query: [URLQueryItem] = []) throws -> URL {
        var components = URLComponents(string: "\(baseURL)\(path)")
        var items = query
        items.append(URLQueryItem(name: "api_key", value: apiKey))
        components?.queryItems = items
        guard let url = components?.url else { throw APIError.badURL }
        return url
    }

    
}
