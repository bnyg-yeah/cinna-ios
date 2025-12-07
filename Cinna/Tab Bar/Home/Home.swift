//
//  Home.swift
//  Cinna
//
//  Created by Brighton Young on 9/26/25.
//

import SwiftUI

struct Home: View {
    @EnvironmentObject private var moviePreferences: MoviePreferencesData
    @State private var movies: [TMDbMovie] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isSearching = false
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading movies…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 40)
                } else if let errorMessage {
                    ErrorStateView(message: errorMessage) {
                        Task { await loadMovies() }
                    }
                    .padding(.horizontal, 24)
                } else if movies.isEmpty {
                    EmptyStateView(title: "No movies found", systemImage: "film.stack")
                        .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 0) {
                        // Liquid Glass style search bar that animates in/out
                        if isSearching {
                            LiquidGlassSearchBar(text: $searchText) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                    isSearching = false
                                    searchText = ""
                                }
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }

                        ScrollView {
                            VStack(alignment: .center, spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Recommended Movies")
                                        .font(.title.bold())
                                        .foregroundStyle(.white)

                                    if !moviePreferences.selectedGenres.isEmpty {
                                        Text("Based on: \(moviePreferences.sortedSelectedGenresString)")
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                }

                                let filteredMovies: [TMDbMovie] = {
                                    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !query.isEmpty else { return movies }
                                    return movies.filter { $0.title.localizedCaseInsensitiveContains(query) }
                                }()

                                VStack(spacing: 16) {
                                    ForEach(filteredMovies) { movie in
                                        NavigationLink(value: movie) {
                                            MovieCard(movie: movie)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    if filteredMovies.isEmpty {
                                        EmptyStateView(title: "No results for \"\(searchText)\"", systemImage: "magnifyingglass")
                                            .padding(.top, 24)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .background(BackgroundView())

            .navigationDestination(for: TMDbMovie.self) { movie in
                MovieDetailView(movie: movie)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                            isSearching.toggle()
                            if !isSearching { searchText = "" }
                        }
                    } label: {
                        Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                    }
                    .accessibilityLabel(isSearching ? "Close search" : "Search")
                }
            }
            .task { await loadMovies() }
            .refreshable { await loadMovies() }
        }
    }

    // MARK: - Search UI
    private struct LiquidGlassSearchBar: View {
        @Binding var text: String
        var onCancel: () -> Void

        @FocusState private var focused: Bool

        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.9))

                TextField("Search movies", text: $text)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .foregroundStyle(.white)
                    .tint(.white)
                    .focused($focused)

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .accessibilityLabel("Clear search text")
                }

                Button("Cancel") { onCancel() }
                    .foregroundStyle(.white)
                    .opacity(0.9)
            }
            .padding(10)
            .background(
                // Liquid Glass-like material
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    focused = true
                }
            }
        }
    }

    // MARK: - Load

    private func loadMovies() async {
        isLoading = true
        errorMessage = nil
        do {
            // Use your existing engine as-is
            let engine = MovieRecommendationEngine.shared
            movies = try await engine.getPersonalizedRecommendations(
                selectedGenres: moviePreferences.selectedGenres,
                selectedFilmmakingPreferences: moviePreferences.selectedFilmmakingPreferences,
                page: 1
            )
        } catch {
            errorMessage = "Failed to load movies. Please try again."
            #if DEBUG
            print("Error loading movies: \(error)")
            #endif
        }
        isLoading = false
    }
}

// MARK: - Local simple states

private struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(Color(.systemOrange))
                .accessibilityHidden(true)

            Text(message)
                .font(.body)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

private struct EmptyStateView: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.7))
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    Home()
        .environmentObject(UserInfoData())
        .environmentObject(MoviePreferencesData())
}

