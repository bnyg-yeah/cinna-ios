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
    
    //MARK: Animation Quality - Style, Animation quality, style
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
    
    //MARK: Filmaking Quality - Acting, writing, directing, cinematography, visual effects
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

    private enum Keys {
        static let genres = "moviePreferences.genres"
        static let animation = "moviePreferences.animation"
        static let filmmaking = "moviePreferences.filmmaking"
    }
    
    
    //MARK: Studio and Production Companies - disney, universal, warner bros, pixar, illumination
    
    //MARK: Directors and Creators -  specific directors, showrunners, writers
    
    //MARK: Cast - specific actors and voice actors
    
    //MARK: Universes - marvel, star wars, harry potter, breaking bad
    
    //MARK: Themes and Topics and Mood - subject matter, tropes, tone, thought-provoking (heist, coming of age, feel good, villainous)

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
    }
}

