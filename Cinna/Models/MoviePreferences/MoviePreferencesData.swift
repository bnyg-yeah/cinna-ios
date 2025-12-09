//
//  MoviePreferencesData.swift
//  Cinna
//
//  Created by Brighton Young on 10/10/25.
//

import Combine
import Foundation

final class MoviePreferencesData: ObservableObject {
    
    // MARK: Genres
    @Published var selectedGenres: Set<GenrePreferences> {
        didSet {
            let rawValues = selectedGenres.map(\.rawValue).sorted()
            defaults.set(rawValues, forKey: Keys.genres)
        }
    }

    var sortedSelectedGenresArray: [GenrePreferences] {
        selectedGenres.sorted { $0.title < $1.title }
    }

    var sortedSelectedGenresString: String {
        sortedSelectedGenresArray.map(\.title).joined(separator: ", ")
    }

    func toggleGenre(_ genre: GenrePreferences) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else {
            selectedGenres.insert(genre)
        }
    }
    
    // MARK: Animation - Quality/Style
    @Published var selectedAnimationPreferences: Set<AnimationPreferences> {
        didSet {
            let rawValues = selectedAnimationPreferences.map(\.rawValue).sorted()
            defaults.set(rawValues, forKey: Keys.animation)
        }
    }
    
    var sortedSelectedAnimationArray: [AnimationPreferences] {
        selectedAnimationPreferences.sorted { $0.title < $1.title }
    }
    
    var sortedSelectedAnimationString: String {
        sortedSelectedAnimationArray.map(\.title).joined(separator: ", ")
    }
    
    func toggleAnimationPreference(_ preference: AnimationPreferences) {
        if selectedAnimationPreferences.contains(preference) {
            selectedAnimationPreferences.remove(preference)
        } else {
            selectedAnimationPreferences.insert(preference)
        }
    }
    
    // MARK: Filmmaking - Acting, Writing, Directing, etc.
    @Published var selectedFilmmakingPreferences: Set<FilmmakingPreferences> {
        didSet {
            let rawValues = selectedFilmmakingPreferences.map(\.rawValue).sorted()
            defaults.set(rawValues, forKey: Keys.filmmaking)
        }
    }
    
    var sortedSelectedFilmmakingArray: [FilmmakingPreferences] {
        selectedFilmmakingPreferences.sorted { $0.title < $1.title }
    }
    
    var sortedSelectedFilmmakingString: String {
        sortedSelectedFilmmakingArray.map(\.title).joined(separator: ", ")
    }
    
    func toggleFilmmakingPreference(_ preference: FilmmakingPreferences) {
        if selectedFilmmakingPreferences.contains(preference) {
            selectedFilmmakingPreferences.remove(preference)
        } else {
            selectedFilmmakingPreferences.insert(preference)
        }
    }

    // MARK: Studios
    @Published var selectedStudioPreferences: Set<StudioPreferences> {
        didSet {
            let rawValues = selectedStudioPreferences.map(\.rawValue).sorted()
            defaults.set(rawValues, forKey: Keys.studios)
        }
    }
    
    var sortedSelectedStudiosArray: [StudioPreferences] {
        selectedStudioPreferences.sorted { $0.title < $1.title }
    }
    
    var sortedSelectedStudiosString: String {
        sortedSelectedStudiosArray.map(\.title).joined(separator: ", ")
    }
    
    func toggleStudioPreference(_ preference: StudioPreferences) {
        if selectedStudioPreferences.contains(preference) {
            selectedStudioPreferences.remove(preference)
        } else {
            selectedStudioPreferences.insert(preference)
        }
    }

    // MARK: Themes
    @Published var selectedThemePreferences: Set<ThemePreferences> {
        didSet {
            let rawValues = selectedThemePreferences.map(\.rawValue).sorted()
            defaults.set(rawValues, forKey: Keys.themes)
        }
    }
    
    var sortedSelectedThemesArray: [ThemePreferences] {
        selectedThemePreferences.sorted { $0.title < $1.title }
    }
    
    var sortedSelectedThemesString: String {
        sortedSelectedThemesArray.map(\.title).joined(separator: ", ")
    }
    
    func toggleThemePreference(_ preference: ThemePreferences) {
        if selectedThemePreferences.contains(preference) {
            selectedThemePreferences.remove(preference)
        } else {
            selectedThemePreferences.insert(preference)
        }
    }

    private enum Keys {
        static let genres = "moviePreferences.genres"
        static let animation = "moviePreferences.animation"
        static let filmmaking = "moviePreferences.filmmaking"
        static let studios = "moviePreferences.studios"
        static let themes = "moviePreferences.themes"
    }
    
    // MARK: Defaults
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Genres
        if let storedGenres = defaults.array(forKey: Keys.genres) as? [String] {
            let genres = storedGenres.compactMap(GenrePreferences.init(rawValue:))
            selectedGenres = Set(genres)
        } else {
            selectedGenres = []
        }
        
        // Animation
        if let storedAnimation = defaults.array(forKey: Keys.animation) as? [String] {
            let prefs = storedAnimation.compactMap(AnimationPreferences.init(rawValue:))
            selectedAnimationPreferences = Set(prefs)
        } else {
            selectedAnimationPreferences = []
        }
        
        // Filmmaking
        if let storedFilmmaking = defaults.array(forKey: Keys.filmmaking) as? [String] {
            let prefs = storedFilmmaking.compactMap(FilmmakingPreferences.init(rawValue:))
            selectedFilmmakingPreferences = Set(prefs)
        } else {
            selectedFilmmakingPreferences = []
        }

        // Studios
        if let storedStudios = defaults.array(forKey: Keys.studios) as? [String] {
            let prefs = storedStudios.compactMap(StudioPreferences.init(rawValue:))
            selectedStudioPreferences = Set(prefs)
        } else {
            selectedStudioPreferences = []
        }

        // Themes
        if let storedThemes = defaults.array(forKey: Keys.themes) as? [String] {
            let prefs = storedThemes.compactMap(ThemePreferences.init(rawValue:))
            selectedThemePreferences = Set(prefs)
        } else {
            selectedThemePreferences = []
        }
    }
}
