//
//  Movie.swift
//  Cinna
//
//  Created by Team Cinna on 11/5/25.
//

import Foundation

// MARK: - List responses

struct TMDbResponse: Decodable {
    let results: [TMDbMovie]
}

// MARK: - Basic movie used by lists

struct TMDbMovie: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String
    let overview: String
    let releaseDate: String?
    let posterPath: String?

    // Handy computed year for prompts/UI
    var year: String {
        guard let releaseDate, releaseDate.count >= 4 else { return "" }
        return String(releaseDate.prefix(4))
    }

    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case releaseDate = "release_date"
        case posterPath = "poster_path"
    }
}

// MARK: - Detailed movie payload (for /movie/{id}?append_to_response=...)

struct TMDbMovieDetails: Decodable {
    let id: Int
    let runtime: Int?
    let tagline: String?
    let genres: [Genre]

    let credits: Credits?
    let keywords: Keywords?
    let productionCountries: [ProductionCountry]
    let spokenLanguages: [SpokenLanguage]

    let voteAverage: Double
    let voteCount: Int

    let releaseDates: ReleaseDates?
    let watchProviders: WatchProvidersResponse?

    enum CodingKeys: String, CodingKey {
        case id, runtime, tagline, genres, credits, keywords
        case productionCountries = "production_countries"
        case spokenLanguages = "spoken_languages"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case releaseDates = "release_dates"
        case watchProviders = "watch/providers"
    }

    // MARK: - Nested types

    struct Genre: Decodable, Hashable {
        let id: Int
        let name: String
    }

    struct Credits: Decodable {
        let cast: [CastMember]?
        let crew: [CrewMember]?
    }

    struct CastMember: Decodable, Hashable {
        let id: Int
        let name: String
        let character: String?
        let order: Int?

        enum CodingKeys: String, CodingKey {
            case id, name, character, order
        }
    }

    struct CrewMember: Decodable, Hashable {
        let id: Int
        let name: String
        let job: String?
        let department: String?
    }

    struct Keywords: Decodable {
        let keywords: [Keyword]?

        struct Keyword: Decodable, Hashable {
            let id: Int
            let name: String
        }
    }

    struct ProductionCountry: Decodable, Hashable {
        let iso3166_1: String
        let name: String

        enum CodingKeys: String, CodingKey {
            case iso3166_1 = "iso_3166_1"
            case name
        }
    }

    struct SpokenLanguage: Decodable, Hashable {
        let englishName: String
        let name: String

        enum CodingKeys: String, CodingKey {
            case englishName = "english_name"
            case name
        }
    }

    struct ReleaseDates: Decodable {
        let results: [CountryRelease]

        struct CountryRelease: Decodable {
            let iso3166_1: String
            let releaseDates: [ReleaseDateItem]

            enum CodingKeys: String, CodingKey {
                case iso3166_1 = "iso_3166_1"
                case releaseDates = "release_dates"
            }
        }

        struct ReleaseDateItem: Decodable {
            let certification: String?
            let releaseDate: String?

            enum CodingKeys: String, CodingKey {
                case certification
                case releaseDate = "release_date"
            }
        }
    }

    // Optional: watch/providers (you’re appending it in API)
    struct WatchProvidersResponse: Decodable {
        let results: [String: WatchProviderCountry]?
    }

    struct WatchProviderCountry: Decodable {
        let link: String?
        let flatrate: [WatchProvider]?
        let rent: [WatchProvider]?
        let buy: [WatchProvider]?
    }

    struct WatchProvider: Decodable, Hashable {
        let providerId: Int
        let providerName: String
        let logoPath: String?

        enum CodingKeys: String, CodingKey {
            case providerId = "provider_id"
            case providerName = "provider_name"
            case logoPath = "logo_path"
        }
    }
}
