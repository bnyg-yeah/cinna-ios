//
//  Movie.swift
//  Cinna
//
//  Created by Chao Chen on 10/27/25.
//

import Foundation

struct OMDbMovie: Codable {
    let title: String
    let year: String
    let rated: String
    let released: String?
    let runtime: String
    let genre: String
    let director: String
    let actors: String
    let plot: String
    let language: String
    let poster: String
    let ratings: [OMDbRating]?
    let imdbRating: String?
    let imdbVotes: String?
    let imdbID: String
    
    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case year = "Year"
        case rated = "Rated"
        case released = "Released"
        case runtime = "Runtime"
        case genre = "Genre"
        case director = "Director"
        case actors = "Actors"
        case plot = "Plot"
        case language = "Language"
        case poster = "Poster"
        case ratings = "Ratings"
        case imdbRating
        case imdbVotes
        case imdbID
    }
}

// Rating from different sources (IMDb, Rotten Tomatoes, etc.)
struct OMDbRating: Codable {
    let source: String
    let value: String
    
    enum CodingKeys: String, CodingKey {
        case source = "Source"
        case value = "Value"
    }
}

// Search results from OMDb API
struct OMDbSearchResult: Codable {
    let search: [OMDbSearchItem]?
    let totalResults: String?
    let response: String
    
    enum CodingKeys: String, CodingKey {
        case search = "Search"
        case totalResults
        case response = "Response"
    }
}

// Individual search result item
struct OMDbSearchItem: Codable, Identifiable, Hashable {
    var id: String { imdbID }
    let title: String
    let year: String
    let imdbID: String
    let type: String
    let poster: String
    
    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case year = "Year"
        case imdbID
        case type = "Type"
        case poster = "Poster"
    }
}

// Error response from OMDb API
struct OMDbError: Codable {
    let response: String
    let error: String
    
    enum CodingKeys: String, CodingKey {
        case response = "Response"
        case error = "Error"
    }
}
