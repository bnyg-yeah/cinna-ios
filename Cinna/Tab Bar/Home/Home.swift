//
//  Home.swift
//  Cinna
//
//  Created by Brighton Young on 9/26/25.
//

import SwiftUI

struct Home: View {
    @State private var recommendations: [OMDbSearchItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Recommended for you")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color(.label))
                    
                    if isLoading {
                        ProgressView("Loading movies...")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if let error = errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundStyle(Color(.systemOrange))
                            
                            Text(error)
                                .font(.body)
                                .foregroundStyle(Color(.secondaryLabel))
                                .multilineTextAlignment(.center)
                            
                            Button("Retry") {
                                Task {
                                    await loadRecommendations()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(40)
                        .frame(maxWidth: .infinity)
                    } else if recommendations.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "film.stack")
                                .font(.system(size: 48))
                                .foregroundStyle(Color(.secondaryLabel))
                            
                            Text("No movies found")
                                .font(.headline)
                                .foregroundStyle(Color(.label))
                        }
                        .padding(40)
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(recommendations) { movie in
                                NavigationLink(value: movie) {
                                    RecommendationCard(movie: movie)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: OMDbSearchItem.self) { movie in
                MovieDetailView(movie: movie)
            }
            .navigationTitle("Home")
            .task {
                await loadRecommendations()
            }
            .refreshable {
                await loadRecommendations()
            }
        }
    }
    
    // MARK: - Load Recommendations
    
    private func loadRecommendations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Search for popular movies (you can customize this query)
            let currentYear = String(Calendar.current.component(.year, from: Date()))
            let result = try await OMDbService.searchMovies(query: "movie", year: currentYear, page: 1)
            recommendations = result.search ?? []
            isLoading = false
        } catch {
            errorMessage = "Failed to load movies. Please try again."
            isLoading = false
            print("Error loading movies: \(error)")
        }
    }
}

// MARK: - RecommendationCard

private struct RecommendationCard: View {
    let movie: OMDbSearchItem

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Show poster from API or placeholder
            AsyncImage(url: URL(string: movie.poster)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 72, height: 108)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                default:
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.systemOrange), Color(.systemPink)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 72, height: 108)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        Image(systemName: "film.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    )
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(movie.title)
                    .font(.headline)
                    .foregroundStyle(Color(.label))

                HStack(spacing: 12) {
                    Label(movie.year, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color(.secondaryLabel))

                    RatingBadge(text: movie.type.capitalized)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(.quaternarySystemFill), lineWidth: 1)
        )
    }
}
// MARK: - Supporting Models & Views

//private struct MovieRecommendation: Identifiable, Hashable {
//    let id = UUID()
//    let title: String
//    let description: String
//    let details: String
//    let rating: String
//    let tags: [String]
//    let aiSummary: String
//    let aiReview: String
//}

// MARK: - MovieDetailView

private struct MovieDetailView: View {
    let movie: OMDbSearchItem
    @State private var movieDetails: OMDbMovie?
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading details...")
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else if let details = movieDetails {
                VStack(alignment: .leading, spacing: 24) {
                    // Show poster
                    AsyncImage(url: URL(string: details.poster)) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 400)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(details.title)
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color(.label))

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(details.year)
                                if let rating = details.imdbRating {
                                    Text("⭐️ \(rating)")
                                }
                            }
                            
                            if let released = details.released, released != "N/A" {
                                Label(released, systemImage: "calendar")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                        }

                        Text("Genre: \(details.genre)")
                            .font(.body)
                            .foregroundStyle(Color(.secondaryLabel))
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        DetailSection(title: "Plot", content: details.plot)
                    }
                }
                .padding(24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await loadMovieDetails()
        }
    }
    
    private func loadMovieDetails() async {
        isLoading = true
        
        do {
            movieDetails = try await OMDbService.getMovieDetails(imdbID: movie.imdbID, plot: "full")
            isLoading = false
        } catch {
            print("Error loading movie details: \(error)")
            isLoading = false
        }
    }
}

private struct DetailSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemYellow).opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(content)
                .font(.body)
                .foregroundStyle(Color(.label))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

private struct RatingBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemYellow).opacity(0.2))
            .foregroundStyle(Color(.systemOrange))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct TagBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(.tertiarySystemFill))
            .foregroundStyle(Color(.secondaryLabel))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    Home()
}
