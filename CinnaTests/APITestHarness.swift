//
//  APITestHarness.swift
//  Cinna
//
//  Created by Brighton Young on 11/9/25.
//


//
//  APITestHarness.swift
//  Cinna
//
//  Test harness for debugging TMDb API calls independently
//  Add this to your project and run it to test API responses
//

import Foundation

// MARK: - Test Harness

class APITestHarness {
    
    /// Test fetching movie details and reviews for a specific movie
    /// Run this in viewDidAppear or a test button to see raw API output
    static func testMovieDataFetch() async {
        print("\n🧪 ========== API TEST HARNESS ==========")
        
        // Test with a popular movie (Dune: Part Two)
        let testMovieId = 693134
        let testMovieTitle = "Dune: Part Two"
        
        print("📽️ Testing with movie: \(testMovieTitle) (ID: \(testMovieId))")
        print("=" * 50)
        
        do {
            // Test 1: Fetch Movie Details
            print("\n📊 TEST 1: Fetching Movie Details...")
            let details = try await TMDbService.getMovieDetails(
                movieID: testMovieId,
                appendFields: [
                    "keywords",
                    "credits", 
                    "release_dates",
                    "watch/providers",
                    "similar",
                    "recommendations"
                ]
            )
            
            print("✅ Movie Details Retrieved:")
            print("  - Runtime: \(details.runtime ?? 0) minutes")
            print("  - Genres: \(details.genres.map(\.name).joined(separator: ", "))")
            print("  - Vote: \(details.voteAverage)/10 from \(details.voteCount) votes")
            
            if let credits = details.credits {
                print("\n  📋 Credits:")
                print("    - Cast members: \(credits.cast?.count ?? 0)")
                print("    - Crew members: \(credits.crew?.count ?? 0)")
                
                if let topActor = credits.cast?.first {
                    print("    - Lead actor: \(topActor.name) as \(topActor.character ?? "Unknown")")
                }
                
                if let director = credits.crew?.first(where: { $0.job == "Director" }) {
                    print("    - Director: \(director.name)")
                }
            }
            
            if let keywords = details.keywords?.keywords {
                print("\n  🏷️ Keywords (\(keywords.count) total):")
                let keywordSample = keywords.prefix(10).map(\.name).joined(separator: ", ")
                print("    \(keywordSample)")
            }
            
            if let usProviders = details.watchProviders?.results?["US"] {
                print("\n  📺 US Watch Providers:")
                if let stream = usProviders.flatrate {
                    print("    - Stream: \(stream.map(\.providerName).joined(separator: ", "))")
                }
                if let rent = usProviders.rent {
                    print("    - Rent: \(rent.prefix(3).map(\.providerName).joined(separator: ", "))")
                }
            }
            
            // Test 2: Fetch Reviews
            print("\n📝 TEST 2: Fetching Reviews...")
            let reviews = try await TMDbService.getReviews(movieID: testMovieId)
            
            print("✅ Reviews Retrieved: \(reviews.count)")
            
            for (index, review) in reviews.prefix(3).enumerated() {
                print("\n  Review \(index + 1):")
                print("    - Author: \(review.author)")
                print("    - Date: \(review.createdAt ?? "Unknown")")
                print("    - Preview: \(String(review.content.prefix(100).filter { !$0.isNewline }))...")
                if let rating = review.rating {
                    print("    - Rating: \(rating)/10")
                }
            }
            
            // Test 3: Test Data Extraction for AI
            print("\n🤖 TEST 3: Data Extraction for AI...")
            testDataExtraction(details: details, reviews: reviews)
            
        } catch {
            print("\n❌ Test Failed: \(error)")
            print("  Error Type: \(type(of: error))")
            print("  Description: \(error.localizedDescription)")
        }
        
        print("\n========================================\n")
    }
    
    /// Test the data extraction logic that feeds the AI
    private static func testDataExtraction(
        details: TMDbMovieDetails,
        reviews: [TMDbService.TMDbReview]
    ) {
        print("  Extracting data points for AI prompt...")
        
        // Test runtime formatting
        let runtime: String = {
            guard let runtime = details.runtime, runtime > 0 else { return "Unknown" }
            let hours = runtime / 60
            let minutes = runtime % 60
            return hours > 0
                ? String(format: "%d h %02d m", hours, minutes)
                : "\(minutes) min"
        }()
        print("    - Formatted runtime: \(runtime)")
        
        // Test cast extraction
        let castCount = (details.credits?.cast ?? [])
            .prefix(5)
            .compactMap { credit -> String? in
                guard !credit.name.isEmpty else { return nil }
                if let character = credit.character, !character.isEmpty {
                    return "\(credit.name) as \(character)"
                }
                return credit.name
            }.count
        print("    - Extracted cast members: \(castCount)")
        
        // Test keyword extraction
        let keywords = (details.keywords?.keywords ?? [])
            .map(\.name)
            .filter { !$0.isEmpty }
        print("    - Extracted keywords: \(keywords.count)")
        
        // Test review processing
        let processedReviews = reviews
            .prefix(3)
            .map { review in
                review.content
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\n", with: " ")
            }
            .filter { !$0.isEmpty }
        print("    - Processed reviews: \(processedReviews.count)")
        
        print("\n✅ Data extraction successful - ready for AI prompt")
    }
    
    /// Test genre matching logic
    static func testGenreMatching() {
        print("\n🎯 Testing Genre Matching Logic...")
        
        let testCases: [(movie: [String], user: [String], expected: String)] = [
            (["Action", "Thriller"], ["Action", "Comedy"], "Partial match"),
            (["Drama", "Romance"], ["Action", "Sci-Fi"], "No match"),
            (["Sci-Fi", "Action"], ["Sci-Fi", "Action"], "Perfect match"),
            (["Comedy"], ["Comedy", "Drama", "Action"], "Partial match")
        ]
        
        for testCase in testCases {
            let score = calculateTestGenreScore(
                movieGenres: testCase.movie,
                userPreferences: testCase.user
            )
            print("  Movie: \(testCase.movie.joined(separator: ", "))")
            print("  User:  \(testCase.user.joined(separator: ", "))")
            print("  Score: \(score)/100 - \(testCase.expected)")
            print("  ---")
        }
    }
    
    private static func calculateTestGenreScore(
        movieGenres: [String],
        userPreferences: [String]
    ) -> Int {
        guard !userPreferences.isEmpty else { return 50 }
        
        let matches = movieGenres.filter { genre in
            userPreferences.contains { pref in
                pref.lowercased() == genre.lowercased()
            }
        }.count
        
        let score = (matches * 100) / max(userPreferences.count, 1)
        return min(100, max(0, score))
    }
}

// MARK: - Usage Examples

/*
 To use this test harness:
 
 1. In your AppDelegate or initial view controller:
 
 override func viewDidAppear(_ animated: Bool) {
     super.viewDidAppear(animated)
     
     // Run API tests
     Task {
         await APITestHarness.testMovieDataFetch()
         APITestHarness.testGenreMatching()
     }
 }
 
 2. Or create a debug button in your UI:
 
 Button("Test APIs") {
     Task {
         await APITestHarness.testMovieDataFetch()
     }
 }
 
 3. Check the console output to see:
    - What data TMDb is actually returning
    - How the data is being processed
    - Any errors or missing fields
 
 4. You can modify the testMovieId to test with different movies:
    - 872585 - Oppenheimer
    - 507089 - Five Nights at Freddy's
    - 466420 - Killers of the Flower Moon
*/

// Helper extension for string multiplication (for visual separators)
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}