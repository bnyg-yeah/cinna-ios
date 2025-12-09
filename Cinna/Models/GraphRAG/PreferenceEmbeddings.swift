//
//  PreferenceEmbeddings.swift
//  Cinna
//
//  Created by Subhan Shrestha
//

import Foundation

struct PreferenceEmbeddings: Codable {
    // Filmmaking embeddings
    var cinematographyEmbedding: [Float]?
    var actingEmbedding: [Float]?
    var directingEmbedding: [Float]?
    var writingEmbedding: [Float]?
    var soundEmbedding: [Float]?
    var visualEffectsEmbedding: [Float]?
    
    // Animation embeddings
    var animationQualityEmbedding: [Float]?
    var twoDEmbedding: [Float]?
    var threeDEmbedding: [Float]?
    var stopMotionEmbedding: [Float]?
    var animeEmbedding: [Float]?
    var stylizedArtEmbedding: [Float]?
    
    // Studio embeddings
    var disneyEmbedding: [Float]?
    var universalEmbedding: [Float]?
    var warnerBrosEmbedding: [Float]?
    var pixarEmbedding: [Float]?
    var illuminationEmbedding: [Float]?
    var marvelEmbedding: [Float]?

    // Theme embeddings
    var lightheartedThemeEmbedding: [Float]?
    var darkThemeEmbedding: [Float]?
    var emotionalThemeEmbedding: [Float]?
    var comingOfAgeThemeEmbedding: [Float]?
    var survivalThemeEmbedding: [Float]?
    var relaxingThemeEmbedding: [Float]?
    var learningThemeEmbedding: [Float]?

    
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
    
    static let studioReferenceTexts: [StudioPreferences: String] = [
        .Disney: """
        Warm, family oriented storytelling with emotional sincerity, musical elements, and optimistic themes. Wholesome tone, colorful worlds, and heartfelt character arcs.
        """,
        .Pixar: """
        Emotionally rich character driven stories with clever humor, visually polished animation, and thoughtful themes. Focus on heart, creativity, and narrative depth.
        """,
        .Illumination: """
        Light, comedic, fast paced family movies with simple plots, bright visuals, and slapstick humor. Accessible tone and humorous characters.
        """,
        .WarnerBros: """
        Wide range of films from prestige drama to large scale genre projects with emphasis on spectacle, atmosphere, and strong world building.
        """,
        .Universal: """
        Genre diverse commercial films including adventure, comedy, horror, and family content. Mainstream accessible storytelling aimed at broad audiences.
        """,
        .Marvel: """
        Superhero focused action with an interconnected universe, ensemble casts, humor, high stakes conflicts, and recurring character arcs across films.
        """
    ]

    static let themeReferenceTexts: [ThemePreferences: String] = [
        .Lighthearted: """
        Warm, humorous, and uplifting tone with accessible conflicts, gentle stakes, and positive energy. Focus on fun, charm, and feel good moments.
        """,
        .Dark: """
        Grim or somber tone with moral ambiguity, tension, heavier subject matter, and intense atmosphere. Often explores difficult choices and consequences.
        """,
        .Emotional: """
        Deep character drama with heartfelt moments, vulnerability, and introspection. Strong emotional arcs and scenes designed to move the audience.
        """,
        .ComingOfAge: """
        Stories of growth and self discovery focused on youth, identity, relationships, and life lessons. Follows characters through formative transitions.
        """,
        .Survival: """
        High stakes endurance against danger or harsh conditions. Emphasis on resilience, resourcefulness, and the struggle to stay alive or protect others.
        """,
        .Relaxing: """
        Calm pacing, gentle tone, soothing visuals or music, and low stakes. Designed to be comforting, cozy, and easy to watch without stress.
        """,
        .Learning: """
        Informative or idea driven storytelling with educational value. Explores concepts, history, science, or social issues in a clear and engaging way.
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
    
    // MARK: Generate preference embeddings
    private static func generate() async throws -> PreferenceEmbeddings {
        var embeddings = PreferenceEmbeddings()
        
        let preferenceOrder: [FilmmakingPreferences] = [
            .acting, .directing, .cinematography, .writing, .sound, .visualEffects
        ]
        
        let texts = preferenceOrder.map { filmmakingReferenceTexts[$0]! }
        let generatedEmbeddings = try await EmbeddingService.shared.batchGenerateEmbeddings(for: texts)
        
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

        let studioOrder: [StudioPreferences] = [
            .Disney, .Pixar, .Illumination, .WarnerBros, .Universal, .Marvel
        ]
        let studioTexts = studioOrder.compactMap { studioReferenceTexts[$0] }
        if !studioTexts.isEmpty {
            let studioEmbeddings = try await EmbeddingService.shared.batchGenerateEmbeddings(for: studioTexts)
            for (index, studio) in studioOrder.enumerated() {
                if index < studioEmbeddings.count {
                    let vector = studioEmbeddings[index]
                    switch studio {
                    case .Disney:
                        embeddings.disneyEmbedding = vector
                        print("  ✓ Generated Disney embedding")
                    case .Pixar:
                        embeddings.pixarEmbedding = vector
                        print("  ✓ Generated Pixar embedding")
                    case .Illumination:
                        embeddings.illuminationEmbedding = vector
                        print("  ✓ Generated Illumination embedding")
                    case .WarnerBros:
                        embeddings.warnerBrosEmbedding = vector
                        print("  ✓ Generated Warner Bros embedding")
                    case .Universal:
                        embeddings.universalEmbedding = vector
                        print("  ✓ Generated Universal embedding")
                    case .Marvel:
                        embeddings.marvelEmbedding = vector
                        print("  ✓ Generated Marvel embedding")
                    }
                }
            }
        }

        let themeOrder: [ThemePreferences] = [
            .Lighthearted, .Dark, .Emotional, .ComingOfAge, .Survival, .Relaxing, .Learning
        ]
        let themeTexts = themeOrder.compactMap { themeReferenceTexts[$0] }
        if !themeTexts.isEmpty {
            let themeEmbeddings = try await EmbeddingService.shared.batchGenerateEmbeddings(for: themeTexts)
            for (index, theme) in themeOrder.enumerated() {
                if index < themeEmbeddings.count {
                    let vector = themeEmbeddings[index]
                    switch theme {
                    case .Lighthearted:
                        embeddings.lightheartedThemeEmbedding = vector
                        print("  ✓ Generated Lighthearted theme embedding")
                    case .Dark:
                        embeddings.darkThemeEmbedding = vector
                        print("  ✓ Generated Dark theme embedding")
                    case .Emotional:
                        embeddings.emotionalThemeEmbedding = vector
                        print("  ✓ Generated Emotional theme embedding")
                    case .ComingOfAge:
                        embeddings.comingOfAgeThemeEmbedding = vector
                        print("  ✓ Generated Coming of Age theme embedding")
                    case .Survival:
                        embeddings.survivalThemeEmbedding = vector
                        print("  ✓ Generated Survival theme embedding")
                    case .Relaxing:
                        embeddings.relaxingThemeEmbedding = vector
                        print("  ✓ Generated Relaxing theme embedding")
                    case .Learning:
                        embeddings.learningThemeEmbedding = vector
                        print("  ✓ Generated Learning theme embedding")
                    }
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
