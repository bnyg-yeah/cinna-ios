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
                Text("Genres")
                    .font(.headline)
                ForEach(GenrePreferences.allCases) { genrePreference in
                    Toggle(isOn: Binding(
                        get: { moviePreferences.selectedGenres.contains(genrePreference) },
                        set: { isOn in
                            if isOn {
                                moviePreferences.selectedGenres.insert(genrePreference)
                            } else {
                                moviePreferences.selectedGenres.remove(genrePreference)
                            }
                        }
                    )) {
                        Label(genrePreference.title, systemImage: genrePreference.symbol)
                    }
                    .tint(.accentColor)
                }
                
                Text("Filmmaking")
                    .font(.headline)
                ForEach(FilmmakingPreferences.allCases) { filmmakingPreference in
                    Toggle(isOn: Binding(
                        get: {
                            moviePreferences.selectedFilmmakingPreferences.contains(filmmakingPreference)
                        },
                        set: { isOn in
                            if isOn {
                                moviePreferences.selectedFilmmakingPreferences.insert(filmmakingPreference)
                            }
                            else {
                                moviePreferences.selectedFilmmakingPreferences.remove(filmmakingPreference)
                            }
                        }
                    ))
                    {
                        Label(filmmakingPreference.title, systemImage:filmmakingPreference.symbol)
                    }
                    .tint(.accentColor)
                }
                
                Text("Animation")
                    .font(.headline)
                ForEach(AnimationPreferences.allCases) { animationPreference in
                    Toggle(isOn: Binding(
                        get: {
                            moviePreferences.selectedAnimationPreferences.contains(animationPreference)
                        },
                        set: { isOn in
                            if isOn {
                                moviePreferences.selectedAnimationPreferences.insert(animationPreference)
                            } else {
                                moviePreferences.selectedAnimationPreferences.remove(animationPreference)
                            }
                        }
                    )) {
                        Label(animationPreference.title, systemImage: animationPreference.symbol)
                    }
                    .tint(.accentColor)
                }
                
                Text("Studios")
                    .font(.headline)
                ForEach(StudioPreferences.allCases) { studioPreference in
                    Toggle(isOn: Binding(
                        get: {
                            moviePreferences.selectedStudioPreferences.contains(studioPreference)
                        },
                        set: { isOn in
                            if isOn {
                                moviePreferences.selectedStudioPreferences.insert(studioPreference)
                            } else {
                                moviePreferences.selectedStudioPreferences.remove(studioPreference)
                            }
                        }
                    )) {
                        Label(studioPreference.title, systemImage: studioPreference.symbol)
                    }
                    .tint(.accentColor)
                }
                
                Text("Themes")
                    .font(.headline)
                ForEach(ThemePreferences.allCases) { themePreference in
                    Toggle(isOn: Binding(
                        get: {
                            moviePreferences.selectedThemePreferences.contains(themePreference)
                        },
                        set: { isOn in
                            if isOn {
                                moviePreferences.selectedThemePreferences.insert(themePreference)
                            } else {
                                moviePreferences.selectedThemePreferences.remove(themePreference)
                            }
                        }
                    )) {
                        Label(themePreference.title, systemImage: themePreference.symbol)
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
