//
//  MoviePreferences.swift
//  Cinna
//
//  Created by Brighton Young on 10/4/25.
//

import SwiftUI

struct MoviePreferences: View {
    @EnvironmentObject private var moviePreferences: MoviePreferencesData
    
    var body: some View {
            List {
            Section("Your Genres") {
                if moviePreferences.sortedSelectedGenresArray.isEmpty {
                    Text("You haven't picked any genres yet.")
                        .foregroundStyle(.secondary)
                } else {
                    Text(moviePreferences.sortedSelectedGenresString)
                        .font(.body.weight(.semibold))
                        .accessibilityLabel("Selected genres: \(moviePreferences.sortedSelectedGenresString)")
                }
            }
            
            Section("Choose Your Favorites") {
                ForEach(Genre.allCases) { genre in
                    Toggle(isOn: Binding(
                        get: { moviePreferences.selectedGenres.contains(genre) },
                        set: { isOn in
                            if isOn {
                                moviePreferences.selectedGenres.insert(genre)
                            } else {
                                moviePreferences.selectedGenres.remove(genre)
                            }
                        }
                    )) {
                        Label(genre.title, systemImage: genre.symbol)
                    }
                    .tint(.accentColor)
                }
            }
        }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .background(BackgroundView())
            .navigationTitle("Movie Preferences")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MoviePreferences()
        .environmentObject(MoviePreferencesData())
}
