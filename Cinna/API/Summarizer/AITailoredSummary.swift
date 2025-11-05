//
//  AITailoredSummary.swift
//  Cinna
//
//  Created by Brighton Young on 11/5/25.
//


// AIReviewService.swift
import Foundation

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

final class AIReviewService {
    static let shared = AIReviewService()
    private init() {}

    private var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String ?? ""
    }

    /// Basic, robust call to Gemini 2.0 Flash (Google AI Studio)
    func generateTailoredReview(
        movie: TMDbMovie,
        reviews: [TMDbService.TMDbReview],
        preferenceTags: [String]
    ) async throws -> AITailoredSummary {
        guard !apiKey.isEmpty else { throw AIReviewError.missingAPIKey }

        // Keep prompt compact and deterministic-ish
        let reviewSnippets = reviews
            .map { $0.content.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3) // a few reviews is enough for the starter
            .joined(separator: "\n---\n")

        let prompt = """
        You are a helpful movie critic assistant.

        TASK: Summarize the following movie for the user and weight the summary toward their preference tags.
        Movie:
        - Title: \(movie.title)
        - Year: \(movie.year)
        - Overview: \(movie.overview)

        Review snippets (from various sources, noisy but useful):
        \(reviewSnippets.isEmpty ? "No external reviews available." : reviewSnippets)

        User preference tags: \(preferenceTags.joined(separator: ", "))

        OUTPUT STRICTLY AS JSON with keys:
        {
          "summary": "120–180 words emphasizing the user's tags and what they care about (e.g., comedy, action, acting skill, animation).",
          "tailoredPoints": ["3-5 bullet points that reflect those tags"],
          "fitScore": 0-100  // how good a fit this movie likely is for the user
        }
        Do not include any extra text outside the JSON.
        """

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
            // generationConfig is optional but helps JSON-only responses on newer backends
            generationConfig: .init(temperature: 0.3, maxOutputTokens: 400, responseMimeType: "application/json")
        )

        var req = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: req)

        // Parse Gemini response -> string
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
        else { throw AIReviewError.noCandidates }

        // Try to decode the JSON the model produced; if it fails, fall back gracefully
        if let jsonData = text.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(AITailoredSummary.self, from: jsonData) {
            return parsed
        } else {
            // Fallback: show raw text as summary
            return AITailoredSummary(
                summary: text,
                tailoredPoints: [],
                fitScore: 50
            )
        }
    }
}
