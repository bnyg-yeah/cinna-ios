//
//  AnimationPreferences.swift
//  Cinna
//

import Foundation

enum AnimationPreferences: String, CaseIterable, Identifiable, Hashable {
    // Users select any combination of these interests.
    // `animationQuality` expresses that they care about overall animation quality,
    // and later logic (e.g., AI or heuristics) can evaluate whether a movie meets that bar.
    case animationQuality      // general “good animation” interest
    case twoD                  // 2D style
    case threeD                // 3D/CGI style
    case stopMotion
    case anime
    case stylizedArt

    var id: String { rawValue }

    var title: String {
        switch self {
        case .animationQuality: return "Animation Quality"
        case .twoD: return "2D"
        case .threeD: return "3D"
        case .stopMotion: return "Stop Motion"
        case .anime: return "Anime"
        case .stylizedArt: return "Stylized Art"
        }
    }

    var symbol: String {
        switch self {
        case .animationQuality: return "sparkles"
        case .twoD: return "rectangle.portrait"
        case .threeD: return "cube"
        case .stopMotion: return "stop.circle"
        case .anime: return "face.smiling"
        case .stylizedArt: return "paintpalette"
        }
    }
}
