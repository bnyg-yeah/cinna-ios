//
//  StudioPreferences.swift
//  Cinna
//
//  Created by Brighton Young on 12/8/25.
//

//MARK: Studio and Production Companies - disney, universal, warner bros, pixar, illumination

import Foundation

enum StudioPreferences: String, CaseIterable, Identifiable, Hashable {
    case Disney
    case Universal
    case WarnerBros
    case Pixar
    case Illumination
    case Marvel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .Disney: return "Disney"
        case .Universal: return "Universal"
        case .WarnerBros: return "Warner Bros."
        case .Pixar: return "Pixar"
        case .Illumination: return "Illumination"
        case .Marvel: return "Marvel"
        }
    }

    var symbol: String {
        switch self {
        case .Disney: return "sparkles"
        case .Universal: return "globe"
        case .WarnerBros: return "shield"
        case .Pixar: return "sparkles"
        case .Illumination: return "lightbulb"
        case .Marvel: return "bolt.shield"
        }
    }
}
