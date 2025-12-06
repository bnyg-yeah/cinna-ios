//
//  TheaterDetailView.swift
//  Cinna
//
//  Created by Subhan Shrestha on 10/10/25.
//

import SwiftUI
import MapKit
import CoreLocation
import UIKit
import SafariServices

struct TheaterDetailView: View {
    let theater: Theater

    @ObservedObject private var favorites = FavoriteTheater.shared
    
    // Map camera centered on the theater
    @State private var cameraPosition: MapCameraPosition
    @State private var safariItem: SafariItem?
    
    init(theater: Theater) {
        self.theater = theater
        let region = MKCoordinateRegion(
            center: theater.location,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        _cameraPosition = State(initialValue: .region(region))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                HStack(spacing: 12) {
                    if let ui = UIImage(named: (logoAssetName ?? "logo_default")) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .accessibilityHidden(true)
                    }
                    Text(theater.name)
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        favorites.toggleFavorite(id: theater.id)
                    } label: {
                        Image(systemName: favorites.isFavorite(id: theater.id) ? "star.fill" : "star")
                            .foregroundStyle(favorites.isFavorite(id: theater.id) ? .yellow : .white.opacity(0.8))
                            .font(.title3)
                            .accessibilityLabel(favorites.isFavorite(id: theater.id) ? "Unfavorite" : "Mark as Favorite")
                    }
                    .buttonStyle(.plain)
                }
                
                // Hero Map
                Map(position: $cameraPosition) {
                    Marker(theater.name, coordinate: theater.location)
                        .tint(.yellow)
                }
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                
                // Technical details / badges
                HStack(spacing: 14) {
                    if let rating = theater.rating {
                        Text("Score \(String(format: "%.1f/5", rating))")
                    } else {
                        Text("Score N/A")
                    }
                    
                    Divider()
                    
                    if let addr = theater.address, !addr.isEmpty {
                        Text("Address available")
                    } else {
                        Text("Address N/A")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                
                // Address section (glass card)
                if let addr = theater.address, !addr.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Location")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.secondary)
                                Text(addr)
                                    .foregroundStyle(.primary)
                            }
                            
                            Button {
                                openInMaps()
                            } label: {
                                Label("Open in Maps", systemImage: "map")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentColor)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.clear)
                                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        )
                    }
                }
                
                // Tickets section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tickets")
                        .font(.headline)
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(ticketingSubtitle)
                            .foregroundStyle(.secondary)

                        Button {
                            openTickets()
                        } label: {
                            Label("Buy Tickets", systemImage: "ticket.fill")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.clear)
                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    )
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(BackgroundView())
        .navigationTitle("Theater Info")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $safariItem) { item in
            SafariView(url: item.url)
                .ignoresSafeArea()
        }
    }
    
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: theater.location)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = theater.name
        mapItem.openInMaps()
    }
    
    private func openTickets() {
        switch theater.chain {
        case .amc:
            // AMC has reliable URL construction
            if let web = amcWebURL() {
                safariItem = SafariItem(url: web)
            } else if let app = amcDeepLinkURL() {
                UIApplication.shared.open(app)
            } else if let google = googleMapsURL() {
                safariItem = SafariItem(url: google)
            }
        case .regal, .cinemark, .alamo:
            if let web = theater.website, let url = URL(string: web) {
                    safariItem = SafariItem(url: url)
                    return
                }
                if let chainWeb = chainSpecificURL() {
                    safariItem = SafariItem(url: chainWeb)
                    return
                }
                if let google = googleMapsURL() {
                    safariItem = SafariItem(url: google)
                    return
                }
                if let fallback = fandangoURL() {
                    safariItem = SafariItem(url: fallback)
                    return
                }
        case .other:
            if let web = theater.website, let url = URL(string: web) {
                    safariItem = SafariItem(url: url)
                    return
                }
                if let google = googleMapsURL() {
                    safariItem = SafariItem(url: google)
                    return
                }
                if let fallback = fandangoURL() {
                    safariItem = SafariItem(url: fallback)
                    return
                }
        }
    }
    
    // MARK: - Google Maps/Search URL
    private func googleMapsURL() -> URL? {
        // Use Google Maps search with theater name and location
        // This will show the theater's Google Business Profile with links to buy tickets
        let query = "\(theater.name) \(theater.address ?? "")".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Google Maps (shows location + website link)
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(query)&query_place_id=\(theater.id)")
    }
    
    // MARK: - Chain-specific URLs
    private func chainSpecificURL() -> URL? {
        switch theater.chain {
        case .regal:
            return regalWebURL()
        case .cinemark:
            return cinemarkWebURL()
        case .alamo:
            return alamoWebURL()
        default:
            return nil
        }
    }

    // MARK: - AMC
    private func amcDeepLinkURL() -> URL? {
        // Prefer app scheme with known theater ID if available
        if let id = theater.amcTheaterID, let url = URL(string: "amctheatres://showtimes?theatreId=\(id)") {
            return url
        }
        return nil
    }

    private func amcWebURL() -> URL? {
        // Example format: https://www.amctheatres.com/movie-theatres/[location]/[theater-name]
        let locationSlug = cityStateSlug(from: theater.address) ?? ""
        let nameSlug = slugify(theater.name)
        let path = locationSlug.isEmpty ? nameSlug : "\(locationSlug)/\(nameSlug)"
        return URL(string: "https://www.amctheatres.com/movie-theatres/\(path)")
    }

    // MARK: - Regal
    private func regalWebURL() -> URL? {
        // If we have a known Regal theater ID, link directly to the theatre page.
        if let id = theater.regalTheaterID, !id.isEmpty {
            return URL(string: "https://www.regmovies.com/theaters/regal-cinema/\(id)")
        }
        
        // Fallback: Google Maps since we can't construct reliable URLs without ID
        return nil
    }
    
    private func cinemarkWebURL() -> URL? {
        // If we have extracted Cinemark ID, use it
        if let id = theater.cinemarkTheaterID, !id.isEmpty {
            return URL(string: "https://www.cinemark.com/\(id)")
        }
        
        // Try to construct direct theater URL
        // Format: https://www.cinemark.com/theatres/[state-abbreviation]/[city]/[theater-name]
        if let address = theater.address {
            let parts = address.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count >= 2 {
                let city = slugify(parts[0])
                let state = parts[1].trimmingCharacters(in: .whitespacesAndNewlines).prefix(2)
                let name = slugify(theater.name.replacingOccurrences(of: "Cinemark", with: "").trimmingCharacters(in: .whitespaces))
                
                if !city.isEmpty && !String(state).isEmpty && !name.isEmpty {
                    return URL(string: "https://www.cinemark.com/theatres/\(state.lowercased())/\(city)/\(name)")
                }
            }
        }
        
        // Fallback: Google Maps
        return nil
    }
    
    private func alamoWebURL() -> URL? {
        // If we have extracted city from their website, use it
        if let city = theater.alamoTheaterID, !city.isEmpty {
            return URL(string: "https://drafthouse.com/\(city)")
        }
        
        // Try to construct from address
        if let address = theater.address {
            let parts = address.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if let city = parts.first {
                let citySlug = slugify(city)
                if !citySlug.isEmpty {
                    return URL(string: "https://drafthouse.com/\(citySlug)")
                }
            }
        }
        
        // Fallback: Google Maps
        return nil
    }

    // MARK: - Fandango with specific theater
    private func fandangoURL() -> URL? {
        // Fandango allows theater search by name and location
        let query = searchQuery()
        return URL(string: "https://www.fandango.com/search?q=\(query)")
    }

    // MARK: - Helpers
    private func slugify(_ text: String) -> String {
        let lower = text.lowercased()
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        let replaced = lower.replacingOccurrences(of: " ", with: "-")
        let filtered = replaced.unicodeScalars.filter { allowed.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }

    private func cityStateSlug(from address: String?) -> String? {
        guard let address, !address.isEmpty else { return nil }
        // Very simple heuristic: split by comma and take first two parts as City, State
        let parts = address.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard parts.count >= 2 else { return nil }
        let city = slugify(parts[0])
        let state = slugify(parts[1])
        if city.isEmpty { return nil }
        return state.isEmpty ? city : "\(city)-\(state)"
    }

    private func searchQuery() -> String {
        var q = theater.name
        if let address = theater.address, !address.isEmpty {
            // Try to append city/state for better results
            let parts = address.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if let city = parts.first { q += " \(city)" }
        }
        return q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q.replacingOccurrences(of: " ", with: "+")
    }

    // MARK: - Branding
    private var logoAssetName: String? {
        switch theater.chain {
        case .amc: return "logo_amc"
        case .regal: return "logo_regal"
        case .cinemark: return "logo_cinemark"
        case .alamo: return "logo_alamo"
        case .other: return nil
        }
    }
    
    // MARK: - In-app Safari presentation
    private struct SafariItem: Identifiable {
        let id = UUID()
        let url: URL
    }

    private struct SafariView: UIViewControllerRepresentable {
        let url: URL

        func makeUIViewController(context: Context) -> SFSafariViewController {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = false
            let vc = SFSafariViewController(url: url, configuration: config)
            vc.preferredControlTintColor = UIColor.label
            return vc
        }

        func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
    }

    private var ticketingSubtitle: String {
        switch theater.chain {
        case .amc:
            return "Buy your tickets from AMC here!"
        case .regal:
            return theater.website != nil
                ? "Buy your tickets from Regal here!"
                : ""
        case .cinemark:
            return theater.website != nil
                ? "Buy your tickets from Cinemark here!"
                : ""
        case .alamo:
            return theater.website != nil
                ? "Buy your tickets from Alamo here!"
                : ""
        case .other:
            return "Buy your tickets here!"
        }
    }
}

#Preview {
    TheaterDetailView(theater: Theater(
        id: "demo",
        name: "AMC Metreon 16",
        rating: 4.4,
        address: "135 4th St, San Francisco, CA",
        location: CLLocationCoordinate2D(latitude: 37.78455, longitude: -122.40334)
    ))
}
