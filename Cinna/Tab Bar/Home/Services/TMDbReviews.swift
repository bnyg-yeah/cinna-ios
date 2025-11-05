//
//  TMDbReviews.swift
//  Cinna
//
//  Created by Brighton Young on 11/5/25.
//

import Foundation

extension TMDbService {
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

        enum CodingKeys: String, CodingKey {
            case id, author, content, url
            case createdAt = "created_at"
        }
    }
    
    static func getReviews(movieID: Int, page: Int = 1) async throws -> [TMDbReview] {
        let url = try makeURL("/movie/\(movieID)/reviews",
                              query: [URLQueryItem(name: "page", value: String(page))])
        let res: TMDbReviewsResponse = try await APIClient.getJSON(url)
        return res.results
    }

}
