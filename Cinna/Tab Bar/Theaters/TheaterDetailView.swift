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
            if let web = amcWebURL() {
                safariItem = SafariItem(url: web)
            } else if let app = amcDeepLinkURL() {
                UIApplication.shared.open(app)
            } else if let fallback = fandangoURL() {
                safariItem = SafariItem(url: fallback)
            }
        case .regal:
            if let web = regalWebURL() {
                safariItem = SafariItem(url: web)
            } else if let fallback = fandangoURL() {
                safariItem = SafariItem(url: fallback)
            }
        case .cinemark:
            if let url = URL(string: "https://www.cinemark.com/") {
                safariItem = SafariItem(url: url)
            } else if let fallback = fandangoURL() {
                safariItem = SafariItem(url: fallback)
            }
        case .alamo:
            if let url = URL(string: "https://drafthouse.com/") {
                safariItem = SafariItem(url: url)
            } else if let fallback = fandangoURL() {
                safariItem = SafariItem(url: fallback)
            }
        case .other:
            if let url = fandangoURL() {
                safariItem = SafariItem(url: url)
            }
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
    private func regalDeepLinkURL() -> URL? {
        // If Regal publishes an app scheme, place it here. For now, none.
        return nil
    }

    private func regalWebURL() -> URL? {
        // If we have a known Regal theater ID, link directly to the theatre page.
        if let id = theater.regalTheaterID, let url = URL(string: "https://www.regmovies.com/theatres/\(id)") {
            return url
        }
        // Fallback: site search for the theater name and city
        let query = searchQuery()
        return URL(string: "https://www.regmovies.com/search?query=\(query)")
    }

    // MARK: - Fandango (others)
    private func fandangoURL() -> URL? {
        let query = searchQuery()
        return URL(string: "https://www.fandango.com/")
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
        return q.replacingOccurrences(of: " ", with: "+")
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
        case .amc: return "Buy your tickets from AMC here!"
        case .regal: return "Buy your tickets from Regal here!"
        case .cinemark: return "Buy your tickets from Cinemark here!"
        case .alamo: return "Buy your tickets from Alamo here!"
        case .other: return "We’ll redirect you to Fandango to buy tickets"
        }
    }
    
    // Fallback view used when BuyTicketsView isn't available in the build target
    private struct TicketsFallbackView: View {
        let theater: Theater

        var body: some View {
            List {
                Section("Theater") {
                    Text(theater.name).font(.headline)
                    if let addr = theater.address { Text(addr).font(.subheadline).foregroundColor(.secondary) }
                }
                Section("Buy Tickets") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ticketing module not found in this build.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("You can still buy tickets on the web.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Button {
                            openRedirect()
                        } label: {
                            Label("Find showtimes on the web", systemImage: "safari")
                        }
                    }
                }
            }
            .navigationTitle("Buy Tickets")
            .navigationBarTitleDisplayMode(.inline)
        }

        private func openRedirect() {
            let query = theater.name.replacingOccurrences(of: " ", with: "+")
            if let url = URL(string: "https://www.fandango.com/search?q=\(query)") {
                UIApplication.shared.open(url)
            }
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

