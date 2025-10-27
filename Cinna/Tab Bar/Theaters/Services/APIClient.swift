//
//  APIClient.swift
//  Cinna
//
//  Created by Subhan Shrestha on 10/9/25.
//

import Foundation

/// Simple generic API client for making JSON requests.
public enum APIError: Error {
    case badURL
    case requestFailed(Int)
    case decodeFailed
    case missingKey
}

struct APIClient {
    /// Fetch and decode JSON from the given URL.
    static func getJSON<T: Decodable>(_ url: URL, headers: [String:String] = [:]) async throws -> T {
        var request = URLRequest(url: url)
        headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.requestFailed(-1)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.requestFailed(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodeFailed
        }
    }
}
