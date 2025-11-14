//
//  TheaterDetailView.swift
//  Cinna
//
//  Created by Subhan Shrestha on 10/10/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct TheaterDetailView: View {
    let theater: Theater
    
    // Map camera centered on the theater
    @State private var cameraPosition: MapCameraPosition
    
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
                Text(theater.name)
                    .font(.title.bold())
                    .foregroundColor(.white)
                
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
                
                // Placeholder for future showtimes/seat map/etc.
                VStack(alignment: .leading, spacing: 12) {
                    Text("Coming Soon")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Live showtimes, seat previews, and best-value tickets will appear here.")
                            .foregroundStyle(.secondary)
                        Text("We’ll also surface membership perks and promos for this location.")
                            .foregroundStyle(.secondary)
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
    }
    
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: theater.location)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = theater.name
        mapItem.openInMaps()
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

