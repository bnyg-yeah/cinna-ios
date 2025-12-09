//
//  MovieHistory.swift
//  Cinna
//
//  Created by Brighton Young on 12/8/25.
//

import SwiftUI

struct MovieHistory: View {
    @StateObject private var userRatings = UserRatings.shared
    
    private var ratedMoviesList: [TMDbMovie] {
        Array(userRatings.ratedMovies.values).sorted { $0.title < $1.title }
    }
    
    var body: some View {
        Group {
            if ratedMoviesList.isEmpty {
                VStack(spacing: 12) {
                    Text("No rated movies yet")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    Text("Rate a movie from the home screen to see it here.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(ratedMoviesList, id: \.id) { movie in
                        if let rating = userRatings.getRating(for: movie.id) {
                            NavigationLink(destination: MovieDetailView(movie: movie)) {
                                HStack(spacing: 12) {
                                    if let posterURL = movie.posterURL, let url = URL(string: posterURL) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .frame(width: 60, height: 90)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 60, height: 90)
                                                    .clipped()
                                                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 8))
                                            case .failure:
                                                Color.white.opacity(0.1)
                                                    .frame(width: 60, height: 90)
                                                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 8))
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(movie.title)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("Your rating: \(rating)/4")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(BackgroundView())
        .navigationTitle("Movie history")
        .navigationBarTitleDisplayMode(.inline)
    }
}
