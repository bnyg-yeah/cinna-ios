//
//  AITailoredSummary.swift
//  Cinna
//
//  Created by Brighton Young on 11/5/25.
//

import Foundation

// MARK: - Models

struct AITailoredSummary: Codable {
    let summary: String
    let tailoredPoints: [String]
    let fitScore: Int
}

enum AIReviewError: Error {
    case noCandidates
    case decodingFailed
    case missingAPIKey
}

// MARK: - Service

final class AIReviewService {
    static let shared = AIReviewService()
    private init() {}

    private var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String) ?? ""
    }

    /// Calls Gemini 2.0 Flash to produce a tailored movie summary.
    func generateTailoredReview(
        movie: TMDbMovie,
        details: TMDbMovieDetails,
        reviews: [TMDbService.TMDbReview],
        preferenceTags: [String]
    ) async throws -> AITailoredSummary {
        guard !apiKey.isEmpty else { throw AIReviewError.missingAPIKey }

        // Reviews -> small, trimmed context
        let reviewSnippets = reviews
            .map { $0.content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3)
            .joined(separator: "\n---\n")

        let runtimeText: String = {
            guard let runtime = details.runtime, runtime > 0 else { return "Unknown" }
            let hours = runtime / 60
            let minutes = runtime % 60
            return hours > 0
                ? String(format: "%d h %02d m (%d min)", hours, minutes, runtime)
                : "\(minutes) min"
        }()

        let taglineText = details.tagline?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let genreText = details.genres.map(\.name).joined(separator: ", ")
        let castEntries = (details.credits?.cast ?? [])
            .sorted { (lhs, rhs) in
                let l = lhs.order ?? Int.max
                let r = rhs.order ?? Int.max
                return l < r
            }
            .prefix(5)
            .compactMap { credit -> String? in
                guard !credit.name.isEmpty else { return nil }
                if let character = credit.character, !character.isEmpty {
                    return "\(credit.name) as \(character)"
                }
                return credit.name
            }

        let keywordNames = (details.keywords?.keywords ?? []).map(\.name).filter { !$0.isEmpty }
        let productionCountries = details.productionCountries.map(\.name).filter { !$0.isEmpty }
        let languageNames = details.spokenLanguages
            .map { $0.englishName.isEmpty ? $0.name : $0.englishName }
            .filter { !$0.isEmpty }

        let ratingText: String = {
            guard details.voteCount > 0 else { return "Not enough ratings yet" }
            return String(format: "%.1f/10 from %d votes", details.voteAverage, details.voteCount)
        }()

        let certificationText: String? = {
            guard let countries = details.releaseDates?.results else { return nil }
            let primary = countries.first { $0.iso3166_1 == "US" } ?? countries.first
            let cert = primary?.releaseDates.first {
                guard let c = $0.certification?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else { return false }
                return !c.isEmpty
            }
            return cert?.certification
        }()

        var facts: [String] = []
        facts.append("Runtime: \(runtimeText)")

        if let taglineText, !taglineText.isEmpty {
            facts.append("Tagline: \(taglineText)")
        } else {
            facts.append("Tagline: None provided")
        }

        facts.append("Genres: \(genreText.isEmpty ? "Unknown" : genreText)")
        facts.append("Notable cast: \(castEntries.isEmpty ? "Not available" : castEntries.joined(separator: ", "))")
        facts.append("TMDb rating: \(ratingText)")
        let keywordLine = keywordNames.isEmpty ? "None listed" : keywordNames.prefix(10).joined(separator: ", ")
        facts.append("Keywords: \(keywordLine)")
        if !productionCountries.isEmpty {
            facts.append("Production countries: \(productionCountries.joined(separator: ", "))")
        }
        if !languageNames.isEmpty {
            facts.append("Spoken languages: \(languageNames.joined(separator: ", "))")
        }
        if let certificationText, !certificationText.isEmpty {
            facts.append("Primary certification: \(certificationText)")
        }

        let factsSection = "Facts from TMDb:\n" + facts.map { "- \($0)" }.joined(separator: "\n")
        let preferenceLine = preferenceTags.isEmpty ? "No specific tags provided." : preferenceTags.joined(separator: ", ")

        let prompt = """
        You are a helpful movie critic assistant.

        Movie:
        - Title: \(movie.title)
        - Year: \(movie.year)
        - Overview: \(movie.overview)

        \(factsSection)

        Review snippets (from various sources, noisy but useful):
        \(reviewSnippets.isEmpty ? "No external reviews available." : reviewSnippets)

        User preference tags to emphasize: \(preferenceLine)

        TASK: Summarize the movie for the user using the facts and reviews above, highlighting how it aligns (or not) with their preferences without inventing new information.

        OUTPUT STRICTLY AS JSON with keys:
        {
          "summary": "120–180 words emphasizing the user's tags and what they care about (e.g., comedy, action, acting skill, animation).",
          "tailoredPoints": ["3-5 bullet points that reflect those tags"],
          "fitScore": 0-100
        }
        Do not include any extra text outside the JSON.
        """

        // --- Request payload types ---
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
            generationConfig: .init(temperature: 0.3, maxOutputTokens: 400, responseMimeType: "application/json")
        )

        // --- Build request ---
        var req = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        req.httpBody = try JSONEncoder().encode(body)

        // --- Send ---
        let (data, _) = try await URLSession.shared.data(for: req)

        // --- Response decoding ---
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
            !text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
        else {
            throw AIReviewError.noCandidates
        }

        // Handle fenced code blocks or extra text—extract the first JSON object
        let cleaned = Self.extractJSONObject(from: text)

        if let jsonData = cleaned.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(AITailoredSummary.self, from: jsonData) {
            return parsed
        } else {
            // Fallback: return raw text as summary
            return AITailoredSummary(summary: text, tailoredPoints: [], fitScore: 50)
        }
    }

    // MARK: - Helpers

    /// Extract the first { ... } JSON object from a string (handles ```json fences).
    private static func extractJSONObject(from text: String) -> String {
        let trimmed = text
            .replacingOccurrences(of: "```json", with: "```")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if trimmed.hasPrefix("```") && trimmed.hasSuffix("```") {
            let body = trimmed.dropFirst(3).dropLast(3)
            return String(body).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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
