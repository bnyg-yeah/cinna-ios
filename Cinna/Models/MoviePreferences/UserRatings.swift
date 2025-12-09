//
//  UserRatings.swift
//  Cinna
//
//  Created by Brighton Young on 11/30/25.
//
//

// For user ratings that can happen in moviedetailview, for graphrag recommendation to use.

import Foundation
import Combine

final class UserRatings: ObservableObject {
    static let shared = UserRatings()
    
    @Published private(set) var ratings: [Int: Int] = [:]
    @Published private(set) var ratedMovies: [Int: TMDbMovie] = [:]
    
    private let defaults: UserDefaults
    private let storageKey = "userMovieRatings.v1"
    private let moviesStorageKey = "userRatedMovieObjects.v1"
    private var cancellables = Set<AnyCancellable>()
    
    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
        loadMovies()
        
        $ratings
            .sink { [weak self] dict in
                self?.save(dict)
            }
            .store(in: &cancellables)
        
        $ratedMovies
            .sink { [weak self] dict in
                self?.saveMovies(dict)
            }
            .store(in: &cancellables)
    }
    
    func getRating(for movieID: Int) -> Int? {
        ratings[movieID]
    }
    
    func setRating(_ rating: Int?, for movieID: Int) {
        if let rating = rating {
            guard (1...4).contains(rating) else { return }
            ratings[movieID] = rating
        } else {
            ratings.removeValue(forKey: movieID)
            ratedMovies.removeValue(forKey: movieID)
        }
    }
    
    func setRating(_ rating: Int?, for movie: TMDbMovie) {
        if let rating = rating {
            guard (1...4).contains(rating) else { return }
            ratings[movie.id] = rating
            ratedMovies[movie.id] = movie
        } else {
            ratings.removeValue(forKey: movie.id)
            ratedMovies.removeValue(forKey: movie.id)
        }
    }
    
    func clearRating(for movieID: Int) {
        ratings.removeValue(forKey: movieID)
        ratedMovies.removeValue(forKey: movieID)
    }
    
    func snapshot() -> [Int: Int] {
        ratings
    }
    
    private func load() {
        if let stored = defaults.dictionary(forKey: storageKey) as? [String: Int] {
            var map: [Int: Int] = [:]
            for (k, v) in stored {
                if let id = Int(k), (1...4).contains(v) {
                    map[id] = v
                }
            }
            self.ratings = map
        } else {
            self.ratings = [:]
        }
    }
    
    private func loadMovies() {
        guard let data = defaults.data(forKey: moviesStorageKey) else {
            ratedMovies = [:]
            return
        }
        if let decoded = try? JSONDecoder().decode([Int: TMDbMovie].self, from: data) {
            ratedMovies = decoded
        } else {
            ratedMovies = [:]
        }
    }
    
    private func save(_ dict: [Int: Int]) {
        let stringKeyed = Dictionary(uniqueKeysWithValues: dict.map { (String($0.key), $0.value) })
        defaults.set(stringKeyed, forKey: storageKey)
    }
    
    private func saveMovies(_ dict: [Int: TMDbMovie]) {
        if let data = try? JSONEncoder().encode(dict) {
            defaults.set(data, forKey: moviesStorageKey)
        }
    }
}
