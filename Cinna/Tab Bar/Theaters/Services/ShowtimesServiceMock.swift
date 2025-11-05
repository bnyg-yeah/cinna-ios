//
//  ShowtimesServiceMock.swift
//  Cinna
//
//  Created by Subhan Shrestha on 10/9/25.
//

import Foundation

// MARK: - Showtime Model
struct Showtime: Identifiable, Hashable {
    let id = UUID()
    let movieTitle: String
    let startTime: Date
}

// MARK: - Mock Service
/// Temporary fake data generator for upcoming showtimes.
/// Later replaced by a real service (Fandango, TMDb, etc.)
struct ShowtimesServiceMock {

    /// Generates a few mock showtimes relative to the current time.
    func upcomingShowtimes(for theaterName: String) -> [Showtime] {
        let now = Date()
        let oneHour: TimeInterval = 60 * 60

        // Return three showtimes spaced an hour apart
        return [
            Showtime(movieTitle: "Dune: Part Two", startTime: now.addingTimeInterval(oneHour)),
            Showtime(movieTitle: "Inside Out 2", startTime: now.addingTimeInterval(oneHour * 2)),
            Showtime(movieTitle: "Deadpool & Wolverine", startTime: now.addingTimeInterval(oneHour * 3))
        ]
    }

    /// Formats a showtime date for display (e.g. “7:30 PM”)
    static func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
