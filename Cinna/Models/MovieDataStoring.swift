//
//  MovieDataStoring.swift
//  Cinna
//
//  Created by Brighton Young on 12/5/25.
//

import Foundation

struct StoredImage: Identifiable, Hashable {
    let id = UUID()
    let filePath: String
    let aspectRatio: Double?
    let url_w300: URL?
    let url_w780: URL?
    let url_original: URL?
}

struct MovieCacheEntry: Identifiable, Hashable {
    let id: Int
    var details: TMDbMovieDetails?
    var reviews: [TMDbService.TMDbReview] = []
    var backdrops: [StoredImage] = []
    var logos: [StoredImage] = []
    
    static func == (lhs: MovieCacheEntry, rhs: MovieCacheEntry) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


final class MovieDataStore: ObservableObject {
    static let shared = MovieDataStore()
    
    @Published private(set) var cache: [Int: MovieCacheEntry] = [:]
    
    func entry(for movieID: Int) -> MovieCacheEntry? {
        cache[movieID]
    }
    
    func storeDetails(_ details: TMDbMovieDetails, for movieID: Int) {
        var entry = cache[movieID] ?? MovieCacheEntry(id: movieID)
        entry.details = details
        cache[movieID] = entry
    }
    
    func storeReviews(_ reviews: [TMDbService.TMDbReview], for movieID: Int) {
        var entry = cache[movieID] ?? MovieCacheEntry(id: movieID)
        entry.reviews = reviews
        cache[movieID] = entry
    }
    
    func storeBackdrops(_ images: [StoredImage], for movieID: Int) {
        var entry = cache[movieID] ?? MovieCacheEntry(id: movieID)
        entry.backdrops = images
        cache[movieID] = entry
    }
    
    func storeLogos(_ images: [StoredImage], for movieID: Int) {
        var entry = cache[movieID] ?? MovieCacheEntry(id: movieID)
        entry.logos = images
        cache[movieID] = entry
    }
}
