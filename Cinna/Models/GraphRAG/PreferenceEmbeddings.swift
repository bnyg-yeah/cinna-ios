//
//  PreferenceEmbeddings.swift
//  Cinna
//
//  Created by Subhan Shrestha
//

import Foundation

struct PreferenceEmbeddings: Codable {
    var cinematographyEmbedding: [Float]?
    var actingEmbedding: [Float]?
    var directingEmbedding: [Float]?
    var writingEmbedding: [Float]?
    var soundEmbedding: [Float]?
    var visualEffectsEmbedding: [Float]?
    
    // Animation-related embeddings (added)
    var animationQualityEmbedding: [Float]?
    var twoDEmbedding: [Float]?
    var threeDEmbedding: [Float]?
    var stopMotionEmbedding: [Float]?
    var animeEmbedding: [Float]?
    var stylizedArtEmbedding: [Float]?
    
    // Cache key for UserDefaults
    private static let cacheKey = "PreferenceEmbeddingsCache"
    
    // Reference texts for each filmmaking dimension
    // Concise, distinctive, and embedding-friendly phrasing to reduce overlap between dimensions.
    static let filmmakingReferenceTexts: [FilmmakingPreferences: String] = [
        .cinematography: """
        Emphasis on visual storytelling and composition. Precise framing, dynamic camera movement, and expressive lenses. Beautiful lighting and color grading that shape mood and theme. Texture, depth, and contrast are used purposefully. Every shot feels intentional and painterly, with strong visual continuity.
        """,
        
        .acting: """
        Nuanced, believable performances that reveal character through behavior and subtext. Emotional range, timing, and chemistry elevate scenes. Physicality and voice reflect internal change. Ensemble balance supports character arcs without showiness. Performances feel lived-in rather than theatrical.
        """,
        
        .directing: """
        Clear authorial vision guiding tone, pace, and staging. Confident blocking, rhythm, and transitions unify the film. Strong control over performances, visual language, and narrative focus. Choices feel intentional and cohesive, shaping audience attention and emotion from scene to scene.
        """,
        
        .writing: """
        Thoughtful screenplay structure with purposeful scenes and clean causality. Dialogue reveals character and subtext. Themes emerge through action and conflict. Character arcs are motivated and coherent. The plot balances setup and payoff without relying on exposition or coincidence.
        """,
        
        .sound: """
        Immersive sound design and purposeful mixing. Spatial detail, dynamics, and silence are used expressively. The score supports tone and rhythm without overwhelming. Foley and ambience enhance texture and world-building. Audio cues guide attention and emotional beats with clarity.
        """,
        
        .visualEffects: """
        Seamless visual effects integrated into the cinematography and lighting. VFX support story and world-building without distraction. Scale, simulation, and compositing feel grounded and consistent. Effects enhance scope and plausibility rather than drawing attention to technique.
        """
    ]
    
    static let animationReferenceTexts: [AnimationPreferences: String] = [
        .animationQuality: """
            High-fidelity animation with fluid motion, consistent character volumes, and polished timing. Clear staging and expressive posing. Visual cohesion across sequences reflects craftsmanship and care.
            """,
        .twoD: """
            Traditional 2D animation with expressive line work and hand-drawn sensibility. Strong silhouettes, squash and stretch, and illustrative backgrounds. Frame-by-frame charm and stylized motion.
            """,
        .threeD: """
            Modern 3D CGI with physically plausible lighting, texture, and depth. Clean rigging, natural motion, and cohesive rendering. Believable materials and environments enhance immersion.
            """,
        .stopMotion: """
            Tactile stop-motion with handcrafted models and miniature sets. Physical textures, subtle imperfections, and frame-by-frame motion convey charm. Practical lighting and depth emphasize materiality.
            """,
        .anime: """
            Anime-inspired style with stylized character design, kinetic action, and expressive timing. Bold compositions, limited animation used purposefully, and heightened emotion through framing and music.
            """,
        .stylizedArt: """
            Bold, stylized visual direction with distinctive palettes and shapes. Painterly textures, experimental shading, or mixed-media techniques. Art direction prioritizes mood, abstraction, and creativity.
            """
    ]
    
    // MARK: - Cache Management
    
    /// Load from cache or generate if needed
    static func loadOrGenerate() async throws -> PreferenceEmbeddings {
        // Try to load from cache first
        if let cached = loadFromCache() {
            print("✅ Loaded preference embeddings from cache")
            return cached
        }
        
        // Generate if not cached
        print("🎬 Generating preference embeddings (first time only)...")
        let embeddings = try await generate()
        
        // Save to cache
        saveToCache(embeddings)
        
        return embeddings
    }
    
    /// Generate embeddings for all preferences (BATCH MODE - FAST!)
    private static func generate() async throws -> PreferenceEmbeddings {
        var embeddings = PreferenceEmbeddings()
        
        // Batch generate all preference embeddings in ONE request
        let preferenceOrder: [FilmmakingPreferences] = [
            .acting, .directing, .cinematography, .writing, .sound, .visualEffects
        ]
        
        let texts = preferenceOrder.map { filmmakingReferenceTexts[$0]! }
        let generatedEmbeddings = try await EmbeddingService.shared.batchGenerateEmbeddings(for: texts)
        
        // Map back to preferences
        for (index, preference) in preferenceOrder.enumerated() {
            if index < generatedEmbeddings.count {
                switch preference {
                case .acting:
                    embeddings.actingEmbedding = generatedEmbeddings[index]
                    print("  ✓ Generated Acting embedding")
                case .directing:
                    embeddings.directingEmbedding = generatedEmbeddings[index]
                    print("  ✓ Generated Directing embedding")
                case .cinematography:
                    embeddings.cinematographyEmbedding = generatedEmbeddings[index]
                    print("  ✓ Generated Cinematography embedding")
                case .writing:
                    embeddings.writingEmbedding = generatedEmbeddings[index]
                    print("  ✓ Generated Writing embedding")
                case .sound:
                    embeddings.soundEmbedding = generatedEmbeddings[index]
                    print("  ✓ Generated Sound embedding")
                case .visualEffects:
                    embeddings.visualEffectsEmbedding = generatedEmbeddings[index]
                    print("  ✓ Generated Visual Effects embedding")
                }
            }
        }
        
        // Generate animation embeddings as well so GraphRAG can score animation-focused users
        for (preference, text) in animationReferenceTexts {
            let embedding = try await EmbeddingService.shared.generateEmbedding(for: text)
            
            switch preference {
            case .animationQuality:
                embeddings.animationQualityEmbedding = embedding
            case .twoD:
                embeddings.twoDEmbedding = embedding
            case .threeD:
                embeddings.threeDEmbedding = embedding
            case .stopMotion:
                embeddings.stopMotionEmbedding = embedding
            case .anime:
                embeddings.animeEmbedding = embedding
            case .stylizedArt:
                embeddings.stylizedArtEmbedding = embedding
            }
            
            print("  ✓ Generated \(preference.title) animation embedding")
        }
        
        print("✅ All embeddings generated\n")
        return embeddings
    }
    
    /// Save to UserDefaults cache
    private static func saveToCache(_ embeddings: PreferenceEmbeddings) {
        do {
            let data = try JSONEncoder().encode(embeddings)
            UserDefaults.standard.set(data, forKey: cacheKey)
            print("💾 Saved preference embeddings to cache")
        } catch {
            print("⚠️ Failed to cache preference embeddings: \(error)")
        }
    }
    
    /// Load from UserDefaults cache
    private static func loadFromCache() -> PreferenceEmbeddings? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }
        
        do {
            let embeddings = try JSONDecoder().decode(PreferenceEmbeddings.self, from: data)
            return embeddings
        } catch {
            print("⚠️ Failed to load cached embeddings: \(error)")
            return nil
        }
    }
    
    /// Clear cache (useful for testing/debugging)
    static func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        print("🗑️ Cleared preference embeddings cache")
    }
}
