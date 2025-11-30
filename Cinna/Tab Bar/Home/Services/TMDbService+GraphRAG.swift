//
//  TMDbService+GraphRAG.swift
//  Cinna
//
//  Created by Subhan Shrestha on 11/29/25.
//

import Foundation

// MARK: - GraphRAG Helper Methods

extension TMDbService {
    
    /// Fetch genre IDs for a specific movie
    /// This is a lightweight call that only gets genres (not full details)
    static func getMovieGenres(movieID: Int) async throws -> [Int] {
        let details = try await getMovieDetails(movieID: movieID, appendFields: [])
        return details.genres.map { $0.id }
    }
    
    /// Batch fetch genres for multiple movies (with rate limiting)
    static func batchFetchGenres(for movieIDs: [Int]) async -> [Int: [Int]] {
        var genreMapping: [Int: [Int]] = [:]
        
        // Process in batches to avoid overwhelming the API
        let batchSize = 10
        let batches = stride(from: 0, to: movieIDs.count, by: batchSize).map {
            Array(movieIDs[$0..<min($0 + batchSize, movieIDs.count)])
        }
        
        for batch in batches {
            await withTaskGroup(of: (Int, [Int]?).self) { group in
                for movieID in batch {
                    group.addTask {
                        do {
                            let genres = try await getMovieGenres(movieID: movieID)
                            return (movieID, genres)
                        } catch {
                            print("⚠️ Failed to fetch genres for movie \(movieID): \(error)")
                            return (movieID, nil)
                        }
                    }
                }
                
                for await (movieID, genres) in group {
                    if let genres = genres {
                        genreMapping[movieID] = genres
                    }
                }
            }
            
            // Small delay between batches
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        print("📊 Fetched genres for \(genreMapping.count)/\(movieIDs.count) movies")
        return genreMapping
    }
}
