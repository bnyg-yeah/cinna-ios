//
//  OMDbService.swift
//  Cinna
//
//  Created by Chao Chen on 10/27/25.
//

import Foundation

// Service for interacting with the OMDb (Open Movie Database) API
struct OMDbService {
    private static let baseURL = "https://www.omdbapi.com/"
    private static let apiKey = "d8a3c187"
    
    static func searchMovies(
            query: String,
            type: String? = nil,
            year: String? = nil,
            page: Int = 1
        ) async throws -> OMDbSearchResult {
            var components = URLComponents(string: baseURL)
            var queryItems = [
                URLQueryItem(name: "apikey", value: apiKey),
                URLQueryItem(name: "s", value: query),
                URLQueryItem(name: "page", value: String(page))
            ]
            
            if let type = type {
                queryItems.append(URLQueryItem(name: "type", value: type))
            }
            if let year = year {
                queryItems.append(URLQueryItem(name: "y", value: year))
            }
            
            components?.queryItems = queryItems
            
            guard let url = components?.url else {
                throw APIError.badURL
            }
            
            return try await APIClient.getJSON(url)
        }
        
        // MARK: - Detail Methods
        
        /// Get detailed movie information by IMDb ID
        /// - Parameters:
        ///   - imdbID: IMDb ID (e.g., "tt1285016")
        ///   - plot: Plot length ("short" or "full")
        static func getMovieDetails(
            imdbID: String,
            plot: String = "short"
        ) async throws -> OMDbMovie {
            var components = URLComponents(string: baseURL)
            components?.queryItems = [
                URLQueryItem(name: "apikey", value: apiKey),
                URLQueryItem(name: "i", value: imdbID),
                URLQueryItem(name: "plot", value: plot)
            ]
            
            guard let url = components?.url else {
                throw APIError.badURL
            }
            
            return try await APIClient.getJSON(url)
        }
        
        /// Get movie information by title
        /// - Parameters:
        ///   - title: Movie title
        ///   - year: Optional year
        ///   - plot: Plot length ("short" or "full")
        static func getMovieByTitle(
            title: String,
            year: String? = nil,
            plot: String = "short"
        ) async throws -> OMDbMovie {
            var components = URLComponents(string: baseURL)
            var queryItems = [
                URLQueryItem(name: "apikey", value: apiKey),
                URLQueryItem(name: "t", value: title),
                URLQueryItem(name: "plot", value: plot)
            ]
            
            if let year = year {
                queryItems.append(URLQueryItem(name: "y", value: year))
            }
            
            components?.queryItems = queryItems
            
            guard let url = components?.url else {
                throw APIError.badURL
            }
            
            return try await APIClient.getJSON(url)
        }
        
        // MARK: - Convenience Methods
        
        /// Search specifically for movies (not series or episodes)
        static func searchOnlyMovies(query: String, page: Int = 1) async throws -> OMDbSearchResult {
            return try await searchMovies(query: query, type: "movie", page: page)
        }
        
        /// Search for currently playing movies (generic search)
        static func getNowPlaying(page: Int = 1) async throws -> OMDbSearchResult {
            // Note: OMDb doesn't have a "now playing" endpoint
            // This searches for recent popular movies as a workaround
            let currentYear = String(Calendar.current.component(.year, from: Date()))
            return try await searchMovies(query: "movie", year: currentYear, page: page)
        }
    }

