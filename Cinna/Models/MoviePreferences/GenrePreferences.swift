//
//  GenrePreferences.swift
//  Cinna
//
//  Created by Brighton Young on 10/10/25.
//

import Foundation

enum GenrePreferences: String, CaseIterable, Identifiable, Hashable {
    case action
    case adventure
    case animation
    case comedy
    case crime
    case documentary
    case drama
    case family
    case fantasy
    case history
    case horror
    case music
    case mystery
    case romance
    case scienceFiction
    case thriller
    case tvMovie
    case war
    case western

    var id: String { rawValue }

    var title: String {
        switch self {
        case .action: return "Action"
        case .adventure: return "Adventure"
        case .animation: return "Animation"
        case .comedy: return "Comedy"
        case .crime: return "Crime"
        case .documentary: return "Documentary"
        case .drama: return "Drama"
        case .family: return "Family"
        case .fantasy: return "Fantasy"
        case .history: return "History"
        case .horror: return "Horror"
        case .music: return "Music"
        case .mystery: return "Mystery"
        case .romance: return "Romance"
        case .scienceFiction: return "Science Fiction"
        case .thriller: return "Thriller"
        case .tvMovie: return "TV Movie"
        case .war: return "War"
        case .western: return "Western"
        }
    }

    var symbol: String {
        switch self {
        case .action: return "bolt.fill"
        case .adventure: return "map.fill"
        case .animation: return "film.stack"
        case .comedy: return "face.smiling"
        case .crime: return "magnifyingglass"
        case .documentary: return "doc.text.fill"
        case .drama: return "theatermasks.fill"
        case .family: return "person.3.fill"
        case .fantasy: return "wand.and.stars"
        case .history: return "book.closed.fill"
        case .horror: return "exclamationmark.triangle"
        case .music: return "music.note"
        case .mystery: return "questionmark.circle"
        case .romance: return "heart.fill"
        case .scienceFiction: return "sparkles"
        case .thriller: return "eye"
        case .tvMovie: return "tv.fill"
        case .war: return "shield.fill"
        case .western: return "sun.max.fill"
        }
    }

    var tmdbID: Int {
        switch self {
        case .action: return 28
        case .adventure: return 12
        case .animation: return 16
        case .comedy: return 35
        case .crime: return 80
        case .documentary: return 99
        case .drama: return 18
        case .family: return 10751
        case .fantasy: return 14
        case .history: return 36
        case .horror: return 27
        case .music: return 10402
        case .mystery: return 9648
        case .romance: return 10749
        case .scienceFiction: return 878
        case .thriller: return 53
        case .tvMovie: return 10770
        case .war: return 10752
        case .western: return 37
        }
    }

    static let idToGenre: [Int: GenrePreferences] = {
        var map: [Int: GenrePreferences] = [:]
        for genre in GenrePreferences.allCases {
            map[genre.tmdbID] = genre
        }
        return map
    }()

    static func from(tmdbID: Int) -> GenrePreferences? {
        idToGenre[tmdbID]
    }
}
