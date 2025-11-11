//
//  MovieRecommendationEngine.swift
//  Cinna
//
//  Created by Chao Chen on 10/27/25.
//
//  Modified by Subhan Shrestha on 11/11/25.
//

import Foundation

struct GraphRAGResponse: Decodable {
    let query: [String]
    let response: [TMDbMovie]
}

// MARK: - MovieRecommendationEngine

final class MovieRecommendationEngine {
    static let shared = MovieRecommendationEngine()
    private init() {}

    // MARK: - GraphRAG Integration
    func getGraphRAGRecommendations(selectedGenres: Set<Genre>) async throws -> [TMDbMovie] {
        guard let url = URL(string: "http://127.0.0.1:8000/recommendations") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let genreStrings = selectedGenres.map(\.title)
        let body = ["genres": genreStrings]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(GraphRAGResponse.self, from: data)
        return decoded.response
    }

    // MARK: - Fallback TMDb Recommendations
    func getPersonalizedRecommendations(
        selectedGenres: Set<Genre>,
        page: Int = 1
    ) async throws -> [TMDbMovie] {
        // Temporary fallback for now
        return [
            TMDbMovie(
                id: 9999,
                title: "Fallback Recommendation",
                overview: "Placeholder result from TMDb fallback.",
                releaseDate: "2025-01-01",
                posterPath: nil,
                voteAverage: 7.5
            )
        ]
    }
}
