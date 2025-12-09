//
//  Home.swift
//  Cinna
//
//  Created by Brighton Young on 9/26/25.
//

import SwiftUI

struct Home: View {
    @EnvironmentObject private var moviePreferences: MoviePreferencesData
    @StateObject private var viewModel = HomeViewModel()   // ← NEW
    
    @State private var isSearching = false
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Recommending movies…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 40)
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorStateView(message: errorMessage) {
                        Task { await viewModel.loadMovies(with: moviePreferences) }
                    }
                    .padding(.horizontal, 24)
                } else if viewModel.movies.isEmpty {
                    EmptyStateView(title: "No movies found", systemImage: "film.stack")
                        .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 0) {


                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {

                                    if !moviePreferences.selectedGenres.isEmpty {
                                        Text("Based on: \(moviePreferences.sortedSelectedGenresString)")
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                }

                                let filteredMovies: [TMDbMovie] = {
                                    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !query.isEmpty else { return viewModel.movies }
                                    return viewModel.movies.filter {
                                        $0.title.localizedCaseInsensitiveContains(query)
                                    }
                                }()

                                VStack(spacing: 16) {
                                    ForEach(filteredMovies) { movie in
                                        NavigationLink(value: movie) {
                                            MovieCard(movie: movie)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    if filteredMovies.isEmpty {
                                        EmptyStateView(title: "No results for \"\(searchText)\"",
                                                       systemImage: "magnifyingglass")
                                            .padding(.top, 24)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .background(
                BackgroundView()
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            )

            .navigationDestination(for: TMDbMovie.self) { movie in
                MovieDetailView(movie: movie)
            }
            .navigationTitle("Recommended Movies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if isSearching {
                        TextField("Search movies", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .foregroundStyle(.white)
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Recommended Movies")
                            .foregroundStyle(.white)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            isSearching.toggle()
                            if !isSearching {
                                searchText = ""
                            }
                        }
                    } label: {
                        Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                    }
                }
            }

            .task { await viewModel.loadMovies(with: moviePreferences) }    // ← UPDATED
            .refreshable { await viewModel.loadMovies(with: moviePreferences) }  // ← UPDATED
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
                    Button { text = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                Button("Cancel") { onCancel() }
                    .foregroundStyle(.white)
                    .opacity(0.9)
            }
            .padding(10)
            .background(
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
