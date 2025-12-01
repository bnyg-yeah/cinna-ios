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
    
    // Published so UI can react to changes.
    @Published private(set) var ratings: [Int: Int] = [:] // movieID -> rating (1–4)
    
    private let defaults: UserDefaults
    private let storageKey = "userMovieRatings.v1" // versioned for future migrations
    private var cancellables = Set<AnyCancellable>()
    
    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
        
        // Persist on every change
        $ratings
            .sink { [weak self] dict in
                self?.save(dict)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public API
    
    func getRating(for movieID: Int) -> Int? {
        ratings[movieID]
    }
    
    func setRating(_ rating: Int?, for movieID: Int) {
        // Validate 1–4 or nil
        if let rating = rating {
            guard (1...4).contains(rating) else { return }
            ratings[movieID] = rating
        } else {
            ratings.removeValue(forKey: movieID)
        }
    }
    
    func clearRating(for movieID: Int) {
        ratings.removeValue(forKey: movieID)
    }
    
    /// Read-only snapshot for engines like GraphRAG.
    func snapshot() -> [Int: Int] {
        ratings
    }
    
    // MARK: - Persistence
    
    private func load() {
        if let stored = defaults.dictionary(forKey: storageKey) as? [String: Int] {
            // Keys are String in UserDefaults; convert back to Int
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
    
    private func save(_ dict: [Int: Int]) {
        // Store as [String: Int] for UserDefaults
        let stringKeyed = Dictionary(uniqueKeysWithValues: dict.map { (String($0.key), $0.value) })
        defaults.set(stringKeyed, forKey: storageKey)
    }
}

