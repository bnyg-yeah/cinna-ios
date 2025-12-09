//
//  ThemePreferences.swift
//  Cinna
//
//  Created by Brighton Young on 12/8/25.
//

//MARK: Themes and Topics and Mood - subject matter, tropes, tone, thought-provoking

import Foundation

enum ThemePreferences: String, CaseIterable, Identifiable, Hashable {
    case Lighthearted
    case Dark
    case Emotional
    case ComingOfAge
    case Survival
    case Relaxing
    case Learning

    var id: String { rawValue }

    var title: String {
        switch self {
        case .Lighthearted: return "Lighthearted"
        case .Dark: return "Dark"
        case .Emotional: return "Emotional"
        case .ComingOfAge: return "Coming of Age"
        case .Survival: return "Survival"
        case .Relaxing: return "Relaxing"
        case .Learning: return "Learning"
        }
    }


    var symbol: String {
        switch self {
        case .Lighthearted: return "sun.max.fill"
        case .Dark: return "moon.stars.fill"
        case .Emotional: return "face.smiling.inverse"
        case .ComingOfAge: return "figure.walk"
        case .Survival: return "leaf.fill"
        case .Relaxing: return "cloud.fill"
        case .Learning: return "book.fill"
        }
    }
    
}
