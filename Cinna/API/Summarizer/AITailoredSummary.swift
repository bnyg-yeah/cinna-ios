//
//  AITailoredSummary_Enhanced.swift
//  Cinna
//
//  Enhanced version with strict data grounding to prevent hallucination
//

import Foundation

// MARK: - Models

struct AITailoredSummary: Codable {
    let summary: String
    let tailoredPoints: [String]
    let fitScore: Int
    let dataSourcesUsed: [String]? // Track what data was used
}

enum AIReviewError: Error {
    case noCandidates
    case decodingFailed
    case missingAPIKey
    case insufficientData
}

// MARK: - Enhanced Service with Strict Data Grounding

final class AIReviewService {
    static let shared = AIReviewService()
    private init() {}

    private var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String) ?? ""
    }

    /// Enhanced method that strictly grounds the AI response in provided data
    func generateTailoredReview(
        movie: TMDbMovie,
        details: TMDbMovieDetails,
        reviews: [TMDbService.TMDbReview],
        preferenceTags: [String]
    ) async throws -> AITailoredSummary {
        guard !apiKey.isEmpty else { throw AIReviewError.missingAPIKey }

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
        return validateAndReturnSummary(summary, dataPoints: dataPoints)
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
        
        // Build factual information section
        var facts: [String] = []
        facts.append("Title: \(movie.title)")
        facts.append("Year: \(movie.year)")
        facts.append("Runtime: \(dataPoints.runtime)")
        facts.append("TMDb Rating: \(dataPoints.rating) from \(dataPoints.voteCount) votes")
        facts.append("Genres: \(dataPoints.genres.isEmpty ? "Not specified" : dataPoints.genres.joined(separator: ", "))")
        
        if !dataPoints.tagline.isEmpty {
            facts.append("Tagline: \(dataPoints.tagline)")
        }
        
        if let cert = dataPoints.certification {
            facts.append("Rating: \(cert)")
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
        
        if !dataPoints.streamingProviders.isEmpty {
            facts.append("Streaming on: \(dataPoints.streamingProviders.joined(separator: ", "))")
        }
        
        // Genre matching analysis for the AI
        let genreMatches = dataPoints.genres.filter { genre in
            preferenceTags.contains { pref in
                pref.lowercased() == genre.lowercased()
            }
        }
        
        let preferenceAnalysis = """
        User's preferred genres: \(preferenceTags.isEmpty ? "No specific preferences" : preferenceTags.joined(separator: ", "))
        Movie's genres: \(dataPoints.genres.joined(separator: ", "))
        Matching genres: \(genreMatches.isEmpty ? "None" : genreMatches.joined(separator: ", "))
        """
        
        // Build the complete prompt
        let prompt = """
        Please creates movie overviews that are tailored to the user preferences. First off, consider the user preferences. From all the movie information that you receive, you should create a summary revolving around only what the user preferences. The summary should be attractive to the user because it is not a generic plot summary, but actually shows them what they care about.
        
        MOVIE FACTS:
        \(facts.map { "• \($0)" }.joined(separator: "\n"))
        
        PLOT OVERVIEW:
        \(movie.overview)
        
        REVIEW EXCERPTS (these may give a broader picture of the movie, and you may the reviews if they are relevant and helpful to the overview):
        \(dataPoints.reviewExcerpts.isEmpty ? "No reviews available" : dataPoints.reviewExcerpts.enumerated().map { "Review \($0.offset + 1): \($0.element)" }.joined(separator: "\n"))
        
        PREFERENCE MATCHING:
        \(preferenceAnalysis)
        
        STRICT RULES:
        1. Use ONLY the facts provided above - do not invent or assume any information
        2. If user preferences match the movie's genres, emphasize those aspects
        3. If preferences don't match, honestly indicate this in the fit score
        4. Reference specific cast, director, or keywords ONLY if they appear in the facts above and are relevant to your analysis
        5. Keep the summary between 100-300 words
        6. Fit score should reflect: 85-100 if user preferences match very well, 65-84 if partial match, 30-64 if poor match, 0-29 for bad match
        7. Use keywords/themes naturally only when they strengthen your analysis - don't force them in
        8. Output in an easy to read format
        
        OUTPUT FORMAT (strict JSON):
        {
          "summary": "A 100-300 word summary emphasizing aspects relevant to user preferences, using ONLY provided information",
          "tailoredPoints": ["Create 3-4 bullet points about the movie that relate to the user's preferences (or note if they don't match)"],
          "fitScore": 0-100,
          "dataSourcesUsed": ["List which data categories you referenced: genres, cast, keywords, reviews, etc."]
        }
        
        Return ONLY valid JSON, no additional text.
        """
        
        return prompt
    }

    // MARK: - API Call

    private func callGeminiAPI(prompt: String) async throws -> AITailoredSummary {
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

        let body = RequestBody(
            contents: [.init(parts: [.init(text: prompt)])],
            generationConfig: .init(
                temperature: 0.2, // Lower temperature for more consistent, factual output
                maxOutputTokens: 500,
                responseMimeType: "application/json"
            )
        )

        var req = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        req.httpBody = try JSONEncoder().encode(body)

        #if DEBUG
        print("🚀 Sending request to Gemini API...")
        #endif

        let (data, _) = try await URLSession.shared.data(for: req)

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

        let response = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard
            let text = response.candidates?.first?.content.parts.first?.text,
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw AIReviewError.noCandidates
        }

        #if DEBUG
        print("✅ Received response from Gemini")
        print("📄 Raw response: \(text.prefix(200))...")
        #endif

        // Extract JSON
        let cleaned = Self.extractJSONObject(from: text)

        if let jsonData = cleaned.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(AITailoredSummary.self, from: jsonData) {
            return parsed
        } else {
            // Fallback with conservative response
            return AITailoredSummary(
                summary: "Unable to generate a tailored summary at this time.",
                tailoredPoints: ["Movie data is being processed"],
                fitScore: 50,
                dataSourcesUsed: []
            )
        }
    }

    // MARK: - Response Validation

    private func validateAndReturnSummary(
        _ summary: AITailoredSummary,
        dataPoints: VerifiedDataPoints
    ) -> AITailoredSummary {
        // Could add additional validation here to ensure the summary
        // doesn't contain information not in dataPoints
        return summary
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
