//
//  CityGeocoder.swift
//  Cinna
//
//  Created by Brighton Young on 11/4/25.
//

import CoreLocation
import MapKit

// MARK: - Lightweight async geocoder (cached)
actor CityGeocoder {
    static let shared = CityGeocoder()
    private var cache: [String: String] = [:] // key: "lat,lon (rounded)"

    func cityString(for coordinate: CLLocationCoordinate2D) async -> String? {
        let key = Self.cacheKey(for: coordinate)

        if let cached = cache[key] { return cached }

        #if DEBUG
        // Make previews deterministic without hitting geocoder/network
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            let previewCity = "Blacksburg, VA"
            cache[key] = previewCity
            return previewCity
        }
        #endif

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        guard let request = MKReverseGeocodingRequest(location: location) else {
            return nil
        }
        
        do {
            let mapItems = try await request.mapItems
            guard let mapItem = mapItems.first else { return nil }
            
            let placemark = mapItem.placemark

            // Prefer locality + admin area (e.g., "Blacksburg, VA")
            if let city = placemark.locality, let region = placemark.administrativeArea, !city.isEmpty {
                let value = "\(city), \(region)"
                cache[key] = value
                return value
            }

            // Fallbacks: subLocality, name, or country
            if let sub = placemark.subLocality, let region = placemark.administrativeArea, !sub.isEmpty {
                let value = "\(sub), \(region)"
                cache[key] = value
                return value
            }

            if let name = placemark.name, !name.isEmpty {
                cache[key] = name
                return name
            }

            if let country = placemark.country {
                cache[key] = country
                return country
            }

            return nil
        } catch {
            // Geocoding can fail for transient reasons; just return nil and UI will fallback.
            return nil
        }
    }

    private static func cacheKey(for c: CLLocationCoordinate2D) -> String {
        // Round to ~0.001° (~100–120 m) to coalesce nearby locations into the same key.
        let lat = (c.latitude * 1000).rounded() / 1000
        let lon = (c.longitude * 1000).rounded() / 1000
        return "\(lat),\(lon)"
    }
}
