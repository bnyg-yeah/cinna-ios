//
//  Theater.swift
//  Cinna
//
//  Created by Subhan Shrestha on 10/9/25.
//

import Foundation
import CoreLocation

/// Represents a single movie theater with its essential metadata.
struct Theater: Identifiable, Hashable {
    let id: String
    let name: String
    let rating: Double?
    let address: String?
    let location: CLLocationCoordinate2D

    /// Optional external IDs for direct ticketing integrations
    let amcTheaterID: String?
    let regalTheaterID: String?
    let cinemarkTheaterID: String?
    let alamoTheaterID: String?

    init(
        id: String,
        name: String,
        rating: Double?,
        address: String?,
        location: CLLocationCoordinate2D,
        amcTheaterID: String? = nil,
        regalTheaterID: String? = nil,
        cinemarkTheaterID: String? = nil,
        alamoTheaterID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.rating = rating
        self.address = address
        self.location = location
        self.amcTheaterID = amcTheaterID
        self.regalTheaterID = regalTheaterID
        self.cinemarkTheaterID = cinemarkTheaterID
        self.alamoTheaterID = alamoTheaterID
    }

    // MARK: - Manual Equatable & Hashable conformance
    static func == (lhs: Theater, rhs: Theater) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Theater {
    enum Chain: String {
        case amc
        case regal
        case cinemark
        case alamo
        case other
    }

    /// Best-effort chain detection. Prefer explicit IDs; fall back to name heuristics.
    var chain: Chain {
        if amcTheaterID != nil { return .amc }
        if regalTheaterID != nil { return .regal }
        if cinemarkTheaterID != nil { return .cinemark }
        if alamoTheaterID != nil { return .alamo }

        // Heuristics based on name
        let lower = name.lowercased()
        if lower.contains("amc") { return .amc }
        if lower.contains("regal") { return .regal }
        if lower.contains("cinemark") || lower.contains("century") || lower.contains("cinearts")
            || lower.contains("tinseltown") { return .cinemark }
        if lower.contains("alamo") || lower.contains("drafthouse") { return .alamo }
        return .other
    }
}
