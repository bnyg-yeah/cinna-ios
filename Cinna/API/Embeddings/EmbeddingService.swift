//
//  EmbeddingService.swift
//  Cinna
//
//  OpenAI-based embedding service (FAST!)
//

import Foundation

struct EmbeddingService {
    static let shared = EmbeddingService()
    
    private var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String) ?? ""
    }
    
    private let embeddingModel = "text-embedding-3-small" // 1536 dimensions, fast & cheap
    
    private init() {}
    
    // MARK: - Generate Single Embedding
    
    func generateEmbedding(for text: String) async throws -> [Float] {
        let embeddings = try await batchGenerateEmbeddings(for: [text])
        guard let first = embeddings.first else {
            throw EmbeddingError.decodingFailed
        }
        return first
    }
    
    // MARK: - BATCH Generate Embeddings (FAST!)
    
    /// Generate embeddings for multiple texts in ONE API call
    func batchGenerateEmbeddings(for texts: [String]) async throws -> [[Float]] {
        guard !apiKey.isEmpty else { throw EmbeddingError.missingAPIKey }
        guard !texts.isEmpty else { return [] }
        
        let endpoint = "https://api.openai.com/v1/embeddings"
        
        guard let url = URL(string: endpoint) else {
            throw EmbeddingError.requestFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Batch request body
        let body: [String: Any] = [
            "model": embeddingModel,
            "input": texts  // Array of strings - batch processing!
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        #if DEBUG
        print("🚀 Batch embedding request for \(texts.count) texts...")
        #endif
        
        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let elapsed = Date().timeIntervalSince(startTime)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmbeddingError.requestFailed
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Embedding error response: \(responseString)")
            }
            #endif
            throw EmbeddingError.requestFailed
        }
        
        let decoded = try JSONDecoder().decode(OpenAIEmbeddingResponse.self, from: data)
        
        #if DEBUG
        // Clarify this is API/network latency (request -> response decode)
        print("✅ OpenAI embeddings API latency: \(decoded.data.count) vectors in \(String(format: "%.2f", elapsed))s (network + decode)")
        #endif
        
        // Return embeddings in original order
        return decoded.data
            .sorted { $0.index < $1.index }
            .map { $0.embedding }
    }
    
    // MARK: - Cosine Similarity
    
    static func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0.0 }
        
        var dotProduct: Float = 0.0
        var magnitudeA: Float = 0.0
        var magnitudeB: Float = 0.0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            magnitudeA += a[i] * a[i]
            magnitudeB += b[i] * b[i]
        }
        
        magnitudeA = sqrt(magnitudeA)
        magnitudeB = sqrt(magnitudeB)
        
        guard magnitudeA > 0, magnitudeB > 0 else { return 0.0 }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
}

// MARK: - Response Models

private struct OpenAIEmbeddingResponse: Codable {
    let data: [EmbeddingData]
    
    struct EmbeddingData: Codable {
        let embedding: [Float]
        let index: Int
    }
}

enum EmbeddingError: Error, LocalizedError {
    case missingAPIKey
    case emptyText
    case requestFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is missing"
        case .emptyText:
            return "Cannot generate embedding for empty text"
        case .requestFailed:
            return "Embedding request failed"
        case .decodingFailed:
            return "Failed to decode embedding response"
        }
    }
}

