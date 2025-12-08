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
    static let filmmakingReferenceTexts: [FilmmakingPreferences: String] = [
        .cinematography: """
        Stunning cinematography. Breathtaking visuals. Gorgeous shot composition. Beautiful lighting and color grading. Visually striking imagery. Masterful use of camera movement. Artistic framing and visual storytelling. Every frame is a painting. Stunning visual aesthetic. Breathtaking photography. Beautiful camera work. Visually impressive. Gorgeous visuals.
        """,
        
            .acting: """
        Exceptional acting performances. Powerful and compelling performances. Outstanding cast. Oscar-worthy performances. Brilliant acting. Emotionally resonant performances. Masterful character portrayals. Captivating performances. Strong ensemble cast. Career-defining performances. Nuanced and layered acting. Transformative performances.
        """,
        
            .directing: """
        Masterful direction. Visionary filmmaking. Brilliant directorial choices. Expert pacing and storytelling. Confident direction. Skilled craftsmanship. Auteur vision. Directorial excellence. Assured filmmaking. Innovative direction. Bold creative choices. Meticulous attention to detail.
        """,
        
            .writing: """
        Brilliant screenplay. Sharp dialogue. Intelligent writing. Well-crafted story. Clever script. Witty and insightful writing. Compelling narrative. Strong character development. Thought-provoking themes. Excellent storytelling. Smart and engaging writing. Masterful plot construction.
        """,
        
            .sound: """
        Immersive sound design. Powerful score. Excellent sound mixing. Atmospheric audio. Impactful soundtrack. Creative use of sound. Rich soundscape. Masterful audio design. Compelling musical score. Sound that enhances the story. Impressive audio work. Sonic excellence.
        """,
        
            .visualEffects: """
        Groundbreaking visual effects. Seamless CGI. Stunning VFX. Impressive special effects. Cutting-edge effects work. Photorealistic effects. Innovative visual effects. Spectacular effects. Masterful VFX integration. Believable effects. State-of-the-art visual effects. Award-worthy effects work.
        """
    ]
    
    static let animationReferenceTexts: [AnimationPreferences: String] = [
        .animationQuality: """
            Breathtaking animation quality. Fluid motion, detailed frames, and polished visuals.
            Beautifully animated sequences with exceptional craftsmanship and care.
            Hand-crafted artistry that makes the world feel alive and immersive.
            """,
        .twoD: """
            Traditional 2D animation with hand-drawn charm and expressive line work.
            Flat-shaded color palettes, classic cartoon movement, and detailed backgrounds.
            Frame-by-frame artistry reminiscent of hand-drawn animated films.
            """,
        .threeD: """
            Modern 3D CGI animation with realistic lighting, depth, and texture.
            Computer-generated visuals with polished models and detailed rendering.
            Lifelike animation and immersive three-dimensional environments.
            """,
        .stopMotion: """
            Stop-motion animation using practical models and tactile textures.
            Physical miniature sets, handcrafted puppets, and frame-by-frame motion.
            Distinctive stop-motion feel with visible craftsmanship.
            """,
        .anime: """
            Anime-inspired visuals, stylized characters, and dynamic action.
            Japanese animation sensibilities, expressive eyes, and energetic motion.
            Themes and aesthetics common to anime storytelling and art.
            """,
        .stylizedArt: """
            Highly stylized animation with bold artistic direction and unique palettes.
            Painterly frames, experimental shading, and unconventional character designs.
            Visually distinctive art styles that prioritize mood and creativity.
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
