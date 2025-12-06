//
//  PlacesService.swift
//  Cinna
//
//  Created by Subhan Shrestha on 10/9/25.
//

import Foundation
import CoreLocation

// MARK: - Protocol

/// Abstract definition for any location-based movie theater data provider.
protocol PlacesService {
    func nearbyMovieTheaters(at coordinate: CLLocationCoordinate2D,
                             radius: Int) async throws -> [Theater]
}

// MARK: - Google Places Implementation

/// Google Places API–based implementation of PlacesService.
struct GooglePlacesService: PlacesService {
    private let apiKey: String

    init() throws {
        guard
            let key = Bundle.main.object(forInfoDictionaryKey: "G_PLACES_API_KEY") as? String,
            !key.isEmpty
        else { throw APIError.missingKey }
        self.apiKey = key
    }

    func nearbyMovieTheaters(at coordinate: CLLocationCoordinate2D,
                             radius: Int = 15000) async throws -> [Theater] {
        
        print("📍 Searching near: \(coordinate.latitude), \(coordinate.longitude)")

        // Build the request URL
        var comps = URLComponents(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json")!
        comps.queryItems = [
            URLQueryItem(name: "keyword", value: "movie theater"),
            URLQueryItem(name: "type", value: "movie_theater"),
            URLQueryItem(name: "location", value: "\(coordinate.latitude),\(coordinate.longitude)"),
            URLQueryItem(name: "radius", value: "25000"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        print("🔗 URL: \(comps.url!)")

        guard let url = comps.url else { throw APIError.badURL }

        // Fetch and decode response
        let response: GooglePlacesResponse = try await APIClient.getJSON(url)

        // Map to Theater model and enrich with Place Details
        var theaters: [Theater] = []
        for result in response.results {
            // Fetch additional details for each theater to get website
            let theater = await enrichTheaterWithDetails(
                placeID: result.place_id,
                name: result.name,
                rating: result.rating,
                address: result.vicinity,
                location: CLLocationCoordinate2D(
                    latitude: result.geometry.location.lat,
                    longitude: result.geometry.location.lng
                )
            )
            theaters.append(theater)
        }
        
        return theaters
    }
    
    /// Fetch Place Details to get website and extract theater IDs
    private func enrichTheaterWithDetails(
        placeID: String,
        name: String,
        rating: Double?,
        address: String?,
        location: CLLocationCoordinate2D
    ) async -> Theater {
        // Try to fetch place details to get website
        do {
            let details = try await fetchPlaceDetails(placeID: placeID)
            let ids = extractTheaterIDs(from: details.website, theaterName: name)
            
            return Theater(
                id: placeID,
                name: name,
                rating: rating,
                address: address,
                website: details.website,
                location: location,
                amcTheaterID: ids.amc,
                regalTheaterID: ids.regal,
                cinemarkTheaterID: ids.cinemark,
                alamoTheaterID: ids.alamo
            )
        } catch {
            // If details fetch fails, return basic theater without IDs
            return Theater(
                id: placeID,
                name: name,
                rating: rating,
                address: address,
                website: nil,
                location: location,
            )
        }
    }
    
    /// Fetch Place Details API
    private func fetchPlaceDetails(placeID: String) async throws -> PlaceDetails {
        var comps = URLComponents(string: "https://maps.googleapis.com/maps/api/place/details/json")!
        comps.queryItems = [
            URLQueryItem(name: "place_id", value: placeID),
            URLQueryItem(name: "fields", value: "website"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = comps.url else { throw APIError.badURL }
        
        let response: PlaceDetailsResponse = try await APIClient.getJSON(url)
        return response.result
    }
    
    /// Extract theater-specific IDs from website URL
    private func extractTheaterIDs(from website: String?, theaterName: String) -> TheaterIDs {
        guard let website = website else { return TheaterIDs() }
        
        var ids = TheaterIDs()
        
        // AMC: https://www.amctheatres.com/movie-theatres/...
        if website.contains("amctheatres.com") {
            // AMC URLs are slug-based, which we can reconstruct
            // We'll leave this nil and use the slug construction method
            ids.amc = nil
        }
        
        // Regal: https://www.regmovies.com/theaters/regal-[name]/[ID]
        if website.contains("regmovies.com/theaters/") || website.contains("regmovies.com/theatres/") {
            if let match = website.range(of: #"/(\d+)/?$"#, options: .regularExpression) {
                ids.regal = String(website[match]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            }
        }
        
        // Cinemark: https://www.cinemark.com/theatres/[state]/[city]/[name-and-id]
        // or theater_id in URL params
        if website.contains("cinemark.com") {
            // Try to extract from URL path
            if let match = website.range(of: #"theatres/[^/]+/[^/]+/([^/?]+)"#, options: .regularExpression) {
                let extracted = String(website[match])
                // The last segment usually contains ID
                ids.cinemark = extracted.components(separatedBy: "/").last
            }
        }
        
        // Alamo: https://drafthouse.com/[city]/theater/[name]
        if website.contains("drafthouse.com") {
            // Extract city from URL
            if let match = website.range(of: #"drafthouse\.com/([^/]+)"#, options: .regularExpression) {
                let components = website[match].components(separatedBy: "/")
                if components.count > 1 {
                    ids.alamo = components[1]
                }
            }
        }
        
        print("🎭 \(theaterName): website=\(website)")
        print("   IDs: AMC=\(ids.amc ?? "nil"), Regal=\(ids.regal ?? "nil"), Cinemark=\(ids.cinemark ?? "nil"), Alamo=\(ids.alamo ?? "nil")")
        
        return ids
    }
}

// MARK: - Helper Structs

private struct TheaterIDs {
    var amc: String?
    var regal: String?
    var cinemark: String?
    var alamo: String?
}

private struct PlaceDetailsResponse: Decodable {
    let result: PlaceDetails
}

private struct PlaceDetails: Decodable {
    let website: String?
}

// MARK: - Response Decoding

/// Codable structs that represent the JSON structure returned by Google Places API.
private struct GooglePlacesResponse: Decodable {
    let results: [PlaceResult]

    struct PlaceResult: Decodable {
        let place_id: String
        let name: String
        let rating: Double?
        let vicinity: String?
        let geometry: Geometry

        struct Geometry: Decodable {
            let location: Location
            struct Location: Decodable {
                let lat: Double
                let lng: Double
            }
        }
    }
}
