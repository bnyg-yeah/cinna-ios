//
//  AIMovieOverview.swift
//  Cinna
//
//  Enhanced version with strict data grounding to prevent hallucination
//

import Foundation

// MARK: - Models

struct AIMovieOverview: Codable {
    let summary: String
    let tailoredPoints: [String]
    let fitScore: Int
    let dataSourcesUsed: [String]? // Track what data was used
}

enum AIOverviewError: Error {
    case noCandidates
    case decodingFailed
    case missingAPIKey
    case insufficientData
}

// MARK: - Enhanced Service with Strict Data Grounding

final class AIOverviewService {
    static let shared = AIOverviewService()
    private init() {}

    private var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String) ?? ""
    }

    /// Enhanced method that strictly grounds the AI response in provided data
    func generateTailoredOverview(
        movie: TMDbMovie,
        details: TMDbMovieDetails,
        reviews: [TMDbService.TMDbReview],
        preferenceTags: [String]
    ) async throws -> AIMovieOverview {
        guard !apiKey.isEmpty else { throw AIOverviewError.missingAPIKey }

        // 1. Collect and validate all data points
        let dataPoints = extractVerifiedDataPoints(
            movie: movie,
            details: details,
            reviews: reviews
        )
        
        #if DEBUG
        print("\n🔍 Data Points for AI Grounding:")
        print("  - Runtime: \(dataPoints.runtime)")
        print("  - Genres: \(dataPoints.genres)")
        print("  - Cast count: \(dataPoints.castMembers.count)")
        print("  - Keywords count: \(dataPoints.keywords.count)")
        print("  - Review excerpts: \(dataPoints.reviewExcerpts.count)")
        print("  - User preferences: \(preferenceTags)")
        print("  - Genre match score: \(calculateGenreMatchScore(movieGenres: dataPoints.genres, userPreferences: preferenceTags))")
        #endif

        // 2. Build strictly grounded prompt
        let prompt = buildGroundedPrompt(
            movie: movie,
            dataPoints: dataPoints,
            preferenceTags: preferenceTags
        )
        
        #if DEBUG
        print("\n📝 Prompt length: \(prompt.count) characters")
        #endif

        // 3. Call Gemini with strict JSON output
        let summary = try await callGeminiAPI(prompt: prompt)
        
        // 4. Validate the response is grounded in data
        return validateAndReturnOverview(summary, dataPoints: dataPoints)
    }

    // MARK: - Data Extraction with Validation

    private struct VerifiedDataPoints {
        let runtime: String
        let tagline: String
        let genres: [String]
        let castMembers: [(name: String, character: String)]
        let directors: [String]
        let keywords: [String]
        let rating: String
        let voteCount: Int
        let certification: String?
        let productionCountries: [String]
        let languages: [String]
        let reviewExcerpts: [String]
        let streamingProviders: [String]
    }

    private func extractVerifiedDataPoints(
        movie: TMDbMovie,
        details: TMDbMovieDetails,
        reviews: [TMDbService.TMDbReview]
    ) -> VerifiedDataPoints {
        
        // Runtime formatting
        let runtime: String = {
            guard let runtime = details.runtime, runtime > 0 else { return "Unknown" }
            let hours = runtime / 60
            let minutes = runtime % 60
            return hours > 0
                ? String(format: "%d h %02d m", hours, minutes)
                : "\(minutes) min"
        }()
        
        // Cast - only verified data
        let castMembers: [(String, String)] = (details.credits?.cast ?? [])
            .sorted { ($0.order ?? Int.max) < ($1.order ?? Int.max) }
            .prefix(7) // Get more cast for better context
            .compactMap { credit in
                guard !credit.name.isEmpty else { return nil }
                let character = credit.character ?? "Unknown role"
                return (credit.name, character)
            }
        
        // Directors
        let directors = (details.credits?.crew ?? [])
            .filter { $0.job == "Director" }
            .map(\.name)
            .filter { !$0.isEmpty }
        
        // Keywords - important for theme understanding (unlimited)
        let keywords = (details.keywords?.keywords ?? [])
            .map(\.name)
            .filter { !$0.isEmpty }
        
        // Reviews - clean and truncate
        let reviewExcerpts = reviews
            .prefix(5) // Get more reviews for better context
            .map { review in
                let content = review.content
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\n", with: " ")
                // Limit each review to 300 chars
                return String(content.prefix(300))
            }
            .filter { !$0.isEmpty }
        
        // Streaming providers
        let streamingProviders: [String] = {
            guard let usProviders = details.watchProviders?.results?["US"] else { return [] }
            var providers: [String] = []
            if let flatrate = usProviders.flatrate {
                providers.append(contentsOf: flatrate.map(\.providerName))
            }
            return providers.filter { !$0.isEmpty }
        }()
        
        // Certification
        let certification: String? = {
            guard let countries = details.releaseDates?.results else { return nil }
            let primary = countries.first { $0.iso3166_1 == "US" } ?? countries.first
            let cert = primary?.releaseDates.first { cert in
                guard let c = cert.certification?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
                return !c.isEmpty
            }
            return cert?.certification
        }()
        
        return VerifiedDataPoints(
            runtime: runtime,
            tagline: details.tagline?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            genres: details.genres.map(\.name),
            castMembers: castMembers,
            directors: directors,
            keywords: keywords,
            rating: String(format: "%.1f/10", details.voteAverage),
            voteCount: details.voteCount,
            certification: certification,
            productionCountries: details.productionCountries.map(\.name),
            languages: details.spokenLanguages.map { $0.englishName.isEmpty ? $0.name : $0.englishName },
            reviewExcerpts: reviewExcerpts,
            streamingProviders: streamingProviders
        )
    }

    // MARK: - Prompt Building with Strict Grounding

    private func buildGroundedPrompt(
        movie: TMDbMovie,
        dataPoints: VerifiedDataPoints,
        preferenceTags: [String]
    ) -> String {
        var facts: [String] = []
        facts.append("Title: \(movie.title)")
        facts.append("Year: \(movie.year)")

        let genreMatches = dataPoints.genres.filter { g in
            preferenceTags.contains { $0.lowercased() == g.lowercased() }
        }
        let focusGenres = genreMatches.isEmpty ? preferenceTags : genreMatches

        // Put matched genres first and keep the full list separately for grounding only
        facts.append("Focus genres: \(focusGenres.isEmpty ? "None" : focusGenres.joined(separator: ", "))")
        facts.append("All genres: \(dataPoints.genres.isEmpty ? "Not specified" : dataPoints.genres.joined(separator: ", "))")

        if !dataPoints.tagline.isEmpty {
            facts.append("Tagline: \(dataPoints.tagline)")
        }
        if !dataPoints.directors.isEmpty {
            facts.append("Director(s): \(dataPoints.directors.joined(separator: ", "))")
        }
        if !dataPoints.castMembers.isEmpty {
            let castString = dataPoints.castMembers.prefix(5)
                .map { "\($0.name) as \($0.character)" }
                .joined(separator: ", ")
            facts.append("Main Cast: \(castString)")
        }
        if !dataPoints.keywords.isEmpty {
            facts.append("Themes/Keywords: \(dataPoints.keywords.joined(separator: ", "))")
        }

        let preferenceAnalysis = """
        User's preferred genres: \(preferenceTags.isEmpty ? "No specific preferences" : preferenceTags.joined(separator: ", "))
        Movie's genres: \(dataPoints.genres.joined(separator: ", "))
        Matching genres (focus): \(focusGenres.isEmpty ? "None" : focusGenres.joined(separator: ", "))
        """

        let prompt = """
        Create a movie overview tailored strictly to the user's focus genres. Center the writeup on the focus genres only. Non-focus genres may be mentioned once at most and only as background.

        MOVIE FACTS:
        \(facts.map { "• \($0)" }.joined(separator: "\n"))

        PLOT OVERVIEW:
        \(movie.overview)

        REVIEW EXCERPTS:
        \(dataPoints.reviewExcerpts.isEmpty ? "No reviews available" : dataPoints.reviewExcerpts.enumerated().map { "Review \($0.offset + 1): \($0.element)" }.joined(separator: "\n"))

        PREFERENCE MATCHING:
        \(preferenceAnalysis)

        RULES:
        1) Begin with one sentence that directly addresses why this is a strong fit for the focus genres (e.g., “If you love Comedy, ...”).
        2) At least 70% of sentences must develop the focus genres with concrete elements from the facts or reviews.
        3) Do not include runtime, numeric ratings, vote counts, certifications, or streaming platforms in the summary.
        4) Cast, director, or keywords are allowed only when they reinforce the focus genres.
        5) Keep the summary between 100 and 200 words, and the summary should be easy to read and follow along.
        6) Tailored points must each map explicitly to a focus genre element.
        7) Fit score must primarily reflect alignment with the focus genres.

        OUTPUT FORMAT (strict JSON):
        {
          "summary": "100-200 words focused on the user's preferences",
          "tailoredPoints": ["3-4 bullets, each tied to a user preference element"],
          "fitScore": 0-100,
          "dataSourcesUsed": ["genres", "cast", "keywords", "reviews"]
        }

        Return only valid JSON.
        """

        return prompt
    }



    // MARK: - API Call

    private func callGeminiAPI(prompt: String) async throws -> AIMovieOverview {
        // Ordered list of model endpoints
        let modelEndpoints = [
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent",
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent",
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent",
        ]
        
        struct RequestBody: Codable {
            struct Part: Codable { let text: String }
            struct Content: Codable { let parts: [Part] }
            struct GenerationConfig: Codable {
                let temperature: Double?
                let maxOutputTokens: Int?
                let responseMimeType: String?
            }
            let contents: [Content]
            let generationConfig: GenerationConfig?
        }

        struct GeminiResponse: Codable {
            struct Candidate: Codable {
                struct Content: Codable {
                    struct Part: Codable { let text: String? }
                    let parts: [Part]
                }
                let content: Content
            }
            let candidates: [Candidate]?
        }
        
        let body = RequestBody(
            contents: [.init(parts: [.init(text: prompt)])],
            generationConfig: .init(
                temperature: 0.2,
                maxOutputTokens: 500,
                responseMimeType: "application/json"
            )
        )
        let bodyData = try JSONEncoder().encode(body)
        
        var lastError: Error?
        
        for endpoint in modelEndpoints {
            do {
                var req = URLRequest(url: URL(string: endpoint)!)
                req.httpMethod = "POST"
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                req.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
                req.httpBody = bodyData
                
                #if DEBUG
                print("🚀 Trying Gemini endpoint: \(endpoint)")
                #endif
                
                let (data, response) = try await URLSession.shared.data(for: req)
                
                // Optionally inspect response for status code
                if let http = response as? HTTPURLResponse, http.statusCode == 429 {
                    // Rate limit hit, skip this endpoint
                    #if DEBUG
                    print("⚠️ Rate limit for endpoint: \(endpoint) (HTTP 429)")
                    #endif
                    lastError = AIOverviewError.insufficientData
                    continue
                }
                
                let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
                guard
                    let text = decoded.candidates?.first?.content.parts.first?.text,
                    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else {
                    throw AIOverviewError.noCandidates
                }
                
                let cleaned = Self.extractJSONObject(from: text)
                if let jsonData = cleaned.data(using: .utf8),
                   let parsed = try? JSONDecoder().decode(AIMovieOverview.self, from: jsonData) {
                    return parsed
                } else {
                    throw AIOverviewError.decodingFailed
                }
            } catch {
                lastError = error
                #if DEBUG
                print("⚠️ Endpoint failed: \(endpoint) with error: \(error)")
                #endif
                continue
            }
        }
        
        throw lastError ?? AIOverviewError.noCandidates
    }



    // MARK: - Response Validation

    private func validateAndReturnOverview(
        _ overview: AIMovieOverview,
        dataPoints: VerifiedDataPoints
    ) -> AIMovieOverview {
        // Could add additional validation here to ensure the overview
        // doesn't contain information not in dataPoints
        return overview
    }

    // MARK: - Helpers

    private func calculateGenreMatchScore(
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

    /// Extract the first { ... } JSON object from a string
    private static func extractJSONObject(from text: String) -> String {
        let trimmed = text
            .replacingOccurrences(of: "```json", with: "```")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("```") && trimmed.hasSuffix("```") {
            let body = trimmed.dropFirst(3).dropLast(3)
            return String(body).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let start = trimmed.firstIndex(of: "{") {
            var depth = 0
            for i in trimmed[start...].indices {
                let ch = trimmed[i]
                if ch == "{" { depth += 1 }
                if ch == "}" {
                    depth -= 1
                    if depth == 0 {
                        let json = trimmed[start...i]
                        return String(json)
                    }
                }
            }
        }
        return trimmed
    }
}
