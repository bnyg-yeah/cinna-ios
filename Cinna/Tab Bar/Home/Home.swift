//
//  Home.swift
//  Cinna
//
//  Created by Brighton Young on 9/26/25.
//

import SwiftUI

struct Home: View {
    @EnvironmentObject private var moviePreferences: MoviePreferencesData
    @State private var recommendations: [TMDbMovie] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommended for you")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color(.label))
                        
                        if !moviePreferences.selectedGenres.isEmpty {
                            Text("Based on: \(moviePreferences.sortedSelectedGenresString)")
                                .font(.subheadline)
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                    }
                    
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
            .navigationDestination(for: TMDbMovie.self) { movie in
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
            // Use recommendation engine with user's genre preferences
            let engine = MovieRecommendationEngine.shared
            recommendations = try await engine.getPersonalizedRecommendations(
                selectedGenres: moviePreferences.selectedGenres,
                page: 1
            )
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
    let movie: TMDbMovie

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Show poster from TMDb
            AsyncImage(url: URL(string: movie.posterURL ?? "")) { phase in
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
                
                Text(movie.overview)
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Label(movie.year, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color(.secondaryLabel))

                    RatingBadge(text: String(format: "⭐️ %.1f", movie.voteAverage))
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
    let movie: TMDbMovie

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Show poster
                AsyncImage(url: URL(string: movie.posterURL ?? "")) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(movie.title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color(.label))

                    HStack {
                        Text(movie.releaseDate)
                        Text("⭐️ \(String(format: "%.1f", movie.voteAverage))")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color(.secondaryLabel))
                    
                    Text("Popularity: \(String(format: "%.0f", movie.popularity))")
                        .font(.caption)
                        .foregroundStyle(Color(.tertiaryLabel))
                }

                VStack(alignment: .leading, spacing: 16) {
                    DetailSection(title: "Overview", content: movie.overview)
                }
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
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
            .environmentObject(MoviePreferencesData())
}
