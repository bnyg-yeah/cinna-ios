//
//  TMDbService_Enhanced.swift
//  Cinna
//
//  Enhanced version with additional data fields for better movie tailoring
//
import Foundation

/// Service for The Movie Database (TMDb) API
/// Enhanced with additional fields for comprehensive movie data
struct TMDbService {
    private static let baseURL = "https://api.themoviedb.org/3"
    private static let apiKey = "b3c3d5efe257f9cfefeaeeeb851ee431"
    
    // MARK: - Discover Movies (Best for Recommendations)
    
    /// Discover movies by genre with popularity sorting
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
            URLQueryItem(name: "sort_by", value: "popularity.desc"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "vote_count.gte", value: "10")
        ]
        
        guard let url = components?.url else {
            throw APIError.badURL
        }
        
        #if DEBUG
        print("🔗 Discover URL: \(url)")
        #endif
        
        let response: TMDbResponse = try await APIClient.getJSON(url)
        
        #if DEBUG
        print("📊 Discover API returned \(response.results.count) movies")
        #endif
        
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
    
    /// Fetch ENHANCED detailed information for a specific movie
    /// Now includes additional fields for better tailoring
    static func getMovieDetails(
        movieID: Int,
        appendFields: [String] = [
            "keywords",           // Themes and topics
            "credits",           // Cast and crew for acting quality
            "release_dates",     // Ratings and certifications
            "watch/providers",   // Streaming availability
            "videos",           // Trailers (can indicate tone/style)
            "similar",          // Similar movies
            "recommendations",  // Recommended movies
            "images"           // Visual style indicators
        ]
    ) async throws -> TMDbMovieDetails {
        var queryItems: [URLQueryItem] = []
        if !appendFields.isEmpty {
            let appendValue = appendFields.joined(separator: ",")
            queryItems.append(URLQueryItem(name: "append_to_response", value: appendValue))
        }

        let url = try makeURL("/movie/\(movieID)", query: queryItems)
        
        #if DEBUG
        print("🎬 Fetching movie details from: \(url)")
        #endif
        
        let details: TMDbMovieDetails = try await APIClient.getJSON(url)
        
        #if DEBUG
        print("✅ Movie details fetched successfully for: \(movieID)")
        if details.runtime != nil {
            print("  - Has runtime data: ✓")
        }
        if details.credits != nil {
            print("  - Has credits data: ✓")
        }
        if details.keywords != nil {
            print("  - Has keywords data: ✓")
        }
        if details.watchProviders != nil {
            print("  - Has watch providers data: ✓")
        }
        #endif
        
        return details
    }
    
    /// Fetch reviews with pagination support
    static func getReviews(movieID: Int, page: Int = 1, maxPages: Int = 2) async throws -> [TMDbReview] {
        var allReviews: [TMDbReview] = []
        
        for currentPage in 1...maxPages {
            let url = try makeURL("/movie/\(movieID)/reviews",
                                  query: [URLQueryItem(name: "page", value: String(currentPage))])
            
            #if DEBUG
            print("📝 Fetching reviews page \(currentPage) from: \(url)")
            #endif
            
            let res: TMDbReviewsResponse = try await APIClient.getJSON(url)
            
            #if DEBUG
            print("  - Page \(currentPage): Got \(res.results.count) reviews")
            #endif
            
            allReviews.append(contentsOf: res.results)
            
            // Stop if we've got enough reviews or if this is the last page
            if res.page >= res.totalPages || allReviews.count >= 10 {
                break
            }
        }
        
        #if DEBUG
        print("📚 Total reviews collected: \(allReviews.count)")
        #endif
        
        return allReviews
    }
    
    // Helper method
    static func makeURL(_ path: String, query: [URLQueryItem] = []) throws -> URL {
        var components = URLComponents(string: "\(baseURL)\(path)")
        var items = query
        items.append(URLQueryItem(name: "api_key", value: apiKey))
        components?.queryItems = items
        guard let url = components?.url else { throw APIError.badURL }
        return url
    }
}

// MARK: - Response Types for Enhanced Data

struct TMDbReviewsResponse: Codable {
    let results: [TMDbReview]
    let page: Int
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case results, page
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct TMDbReview: Codable, Identifiable, Hashable {
    let id: String
    let author: String
    let content: String
    let url: String?
    let createdAt: String?
    let rating: Double? // Some reviews include ratings

    enum CodingKeys: String, CodingKey {
        case id, author, content, url, rating
        case createdAt = "created_at"
    }
}

// MARK: - TMDbService Extension

extension TMDbService {
    // Add any additional TMDbService extensions here if needed
}
