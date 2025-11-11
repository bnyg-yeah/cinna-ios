//
//  TMDbImages.swift
//  Cinna
//
//  Created by Brighton Young on 11/10/25.
//


import Foundation

extension TMDbService {
    struct TMDbImagesResponse: Codable {
        let backdrops: [TMDbImage]
        let logos: [TMDbImage]
    }

    struct TMDbImage: Codable, Identifiable, Hashable {
        let aspectRatio: Double
        let height: Int
        let iso_639_1: String?
        let filePath: String
        let voteAverage: Double
        let voteCount: Int
        let width: Int
        let numericID: Int?

        var id: Int { numericID ?? filePath.hashValue }

        enum CodingKeys: String, CodingKey {
            case aspectRatio = "aspect_ratio"
            case height
            case iso_639_1 = "iso_639_1"
            case filePath = "file_path"
            case voteAverage = "vote_average"
            case voteCount = "vote_count"
            case width
            case numericID = "id"
        }
    }

    static func getImages(movieID: Int) async throws -> TMDbImagesResponse {
        let url = try makeURL("/movie/\(movieID)/images")
        let res: TMDbImagesResponse = try await APIClient.getJSON(url)
        return res
    }

    static func imageURL(path: String, size: String) -> URL? {
        URL(string: "https://image.tmdb.org/t/p/\(size)\(path)")
    }
}
