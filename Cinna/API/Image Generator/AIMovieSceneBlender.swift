//
//  AIMovieSceneBlender.swift
//  Cinna
//
//  Created by Brighton Young on 12/6/25.
//

import Foundation
import UIKit

enum AIMovieSceneBlenderError: Error {
    case missingAPIKey
    case backdropDownloadFailed
    case encodingFailed
    case noImageCandidates
    case unsupportedResponse
    case contentFiltered
}

struct AIMovieSceneBlendResult {
    let image: UIImage
    let model: String
}

final class AIMovieSceneBlenderService {
    static let shared = AIMovieSceneBlenderService()
    private init() {}

    private var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String) ?? ""
    }

    private struct RequestBody: Codable {
        struct Part: Codable {
            struct InlineData: Codable {
                let mimeType: String
                let data: String
            }
            let text: String?
            let inlineData: InlineData?

            init(text: String) {
                self.text = text
                self.inlineData = nil
            }

            init(inlineData: InlineData) {
                self.text = nil
                self.inlineData = inlineData
            }
        }

        struct Content: Codable {
            let parts: [Part]
        }

        struct GenerationConfig: Codable {
            let responseMimeType: String?
            let temperature: Double?
            let maxOutputTokens: Int?
        }

        let contents: [Content]
        let generationConfig: GenerationConfig?
    }

    private struct GeminiImageResponse: Codable {
        struct Candidate: Codable {
            struct Content: Codable {
                struct Part: Codable {
                    struct InlineData: Codable {
                        let mimeType: String
                        let data: String
                    }
                    let text: String?
                    let inlineData: InlineData?
                }
                let parts: [Part]
            }
            let content: Content
            let finishReason: String?
        }
        let candidates: [Candidate]?
    }

    func blendUserIntoBackdrop(backdropURL: URL, userImage: UIImage) async throws -> AIMovieSceneBlendResult {
        guard !apiKey.isEmpty else { throw AIMovieSceneBlenderError.missingAPIKey }

        let backdropData: Data
        do {
            let (data, response) = try await URLSession.shared.data(from: backdropURL)
            if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                throw AIMovieSceneBlenderError.backdropDownloadFailed
            }
            backdropData = data
        } catch {
            throw AIMovieSceneBlenderError.backdropDownloadFailed
        }

        guard let userImageData = userImage.pngData() ?? userImage.jpegData(compressionQuality: 0.95) else {
            throw AIMovieSceneBlenderError.encodingFailed
        }

        // MARK: Scene Blender PROMPT
        let prompt = "Take the person/people from the second image and incorporate them seamlessly into the scene from the first image. Preserve the person's identity, and match the lighting, color grading, and vibe of the first image. You may modify the person's pose and size, so that they integrate better into the first image. Return a single final blended image."

        let contents: [RequestBody.Content] = [
            .init(parts: [
                .init(inlineData: .init(mimeType: "image/png", data: backdropData.base64EncodedString())),
                .init(inlineData: .init(mimeType: "image/png", data: userImageData.base64EncodedString())),
                .init(text: prompt)
            ])
        ]


        let body = RequestBody(
            contents: contents,
            generationConfig: .init(
                responseMimeType: nil,
                temperature: 0.2,
                maxOutputTokens: nil
            )
        )


        let bodyData = try JSONEncoder().encode(body)

        let endpoints = [
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"
        ]

        var lastError: Error?

        for endpoint in endpoints {
            do {
                var request = URLRequest(url: URL(string: endpoint)!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
                request.httpBody = bodyData

                let (data, response) = try await URLSession.shared.data(for: request)
                print(String(data: data, encoding: .utf8) ?? "No UTF8")

                if let http = response as? HTTPURLResponse {
                    if http.statusCode == 429 {
                        lastError = AIMovieSceneBlenderError.noImageCandidates
                        continue
                    } else if http.statusCode == 400 || http.statusCode == 403 {
                        throw AIMovieSceneBlenderError.contentFiltered
                    }
                }

                let decoded = try JSONDecoder().decode(GeminiImageResponse.self, from: data)
                guard let candidate = decoded.candidates?.first else {
                    throw AIMovieSceneBlenderError.noImageCandidates
                }

                if let part = candidate.content.parts.first(where: { $0.inlineData != nil }),
                   let inline = part.inlineData,
                   let imageData = Data(base64Encoded: inline.data),
                   let image = UIImage(data: imageData) {
                    return AIMovieSceneBlendResult(image: image, model: endpoint)
                }

                lastError = AIMovieSceneBlenderError.unsupportedResponse
            } catch {
                lastError = error
                continue
            }
        }

        throw lastError ?? AIMovieSceneBlenderError.noImageCandidates
    }
}
