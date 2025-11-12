//
//  FilmmakingPreference.swift
//  Cinna
//

import Foundation

/// User-selectable filmmaking craft interests (no evaluation here).
/// Later logic (e.g., AI or heuristics) can decide if a movie exhibits strong qualities in these areas
/// using TMDb data such as credits (cast/crew jobs/departments), keywords, etc.
enum FilmmakingPreferences: String, CaseIterable, Identifiable, Hashable {
    case acting
    case directing
    case writing
    case cinematography
    case sound
    case visualEffects

    var id: String { rawValue }

    var title: String {
        switch self {
        case .acting: return "Acting"
        case .directing: return "Directing"
        case .writing: return "Writing"
        case .cinematography: return "Cinematography"
        case .sound: return "Sound"
        case .visualEffects: return "Visual Effects"
        }
    }

    var symbol: String {
        switch self {
        case .acting: return "person.3.sequence"
        case .directing: return "megaphone"
        case .writing: return "pencil.and.list.clipboard"
        case .cinematography: return "camera.aperture"
        case .sound: return "waveform"
        case .visualEffects: return "sparkles"
        }
    }
}
