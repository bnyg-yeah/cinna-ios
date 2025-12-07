//
//  PreferenceEmbeddings.swift
//  Cinna
//
//  Reference embeddings for filmmaking preferences
//

import Foundation

struct PreferenceEmbeddings {
    var actingEmbedding: [Float]? = nil
    var directingEmbedding: [Float]? = nil
    var cinematographyEmbedding: [Float]? = nil
    var writingEmbedding: [Float]? = nil
    var soundEmbedding: [Float]? = nil
    var visualEffectsEmbedding: [Float]? = nil
    
    /// Reference texts for each preference dimension
    static let referenceTexts: [FilmmakingPreferences: String] = [
        .acting: """
        Exceptional acting performances. Powerful and compelling performances. 
        Outstanding cast. Oscar-worthy performances. Brilliant acting. 
        Authentic emotional depth. Nuanced character portrayals. 
        Award-winning actors delivering unforgettable performances.
        """,
        
        .directing: """
        Masterful direction. Visionary filmmaking. Brilliant directorial choices. 
        Expertly crafted scenes. Cohesive storytelling vision. 
        Innovative camera work and staging. Director's unique voice shines through. 
        Perfectly paced and structured narrative.
        """,
        
        .cinematography: """
        Stunning cinematography. Breathtaking visuals. Gorgeous shot composition. 
        Beautiful lighting and color grading. Visually striking imagery. 
        Masterful use of camera movement. Artistic framing and visual storytelling. 
        Every frame is a painting. Stunning visual aesthetic.
        """,
        
        .writing: """
        Exceptional screenplay. Brilliant writing. Sharp dialogue. 
        Compelling narrative structure. Well-developed characters. 
        Thoughtful themes and subtext. Clever plot construction. 
        Memorable lines and emotional depth. Award-winning script.
        """,
        
        .sound: """
        Outstanding sound design. Immersive audio experience. 
        Powerful musical score. Perfect sound mixing. 
        Atmospheric soundscape. Effective use of silence and sound. 
        Award-winning soundtrack. Audio enhances emotional impact.
        """,
        
        .visualEffects: """
        Groundbreaking visual effects. Seamless CGI integration. 
        Stunning practical effects. Innovative VFX work. 
        Photorealistic digital effects. Impressive technical achievement. 
        Visual spectacle. Award-winning special effects.
        """
    ]
    
    /// Generate all preference embeddings
    static func generate() async throws -> PreferenceEmbeddings {
        var embeddings = PreferenceEmbeddings()
        
        print("🎬 Generating preference embeddings...")
        
        for (preference, text) in referenceTexts {
            let embedding = try await EmbeddingService.shared.generateEmbedding(for: text)
            
            switch preference {
            case .acting:
                embeddings.actingEmbedding = embedding
            case .directing:
                embeddings.directingEmbedding = embedding
            case .cinematography:
                embeddings.cinematographyEmbedding = embedding
            case .writing:
                embeddings.writingEmbedding = embedding
            case .sound:
                embeddings.soundEmbedding = embedding
            case .visualEffects:
                embeddings.visualEffectsEmbedding = embedding
            }
            
            print("  ✓ Generated \(preference.title) embedding")
        }
        
        print("✅ All preference embeddings generated")
        return embeddings
    }
}
