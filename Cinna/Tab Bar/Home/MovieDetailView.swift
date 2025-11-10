//
//  MovieDetailView.swift
//  Cinna
//
//  Updated to generate AI-tailored summaries using user preferences.
//  Enhanced with comprehensive debug logging.
//

import SwiftUI

struct MovieDetailView: View {
    let movie: TMDbMovie

    @EnvironmentObject private var moviePreferences: MoviePreferencesData

    @State private var aiSummary: AITailoredSummary?
    @State private var aiError: String?
    @State private var isSummarizing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // ===== Your existing header / artwork / metadata UI goes here =====
                // Example placeholders (keep your current implementation):
                Text(movie.title)
                    .font(.title.bold())
                if !movie.overview.isEmpty {
                    Text(movie.overview)
                        .foregroundStyle(.secondary)
                }

                // ===== Preferences chips (optional visual) =====
                if !moviePreferences.sortedSelectedGenresArray.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your preferences")
                            .font(.headline)
                        WrapHStack(spacing: 8) {
                            ForEach(moviePreferences.sortedSelectedGenresArray, id: \.self) { genre in
                                Text(genre.title)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }
                        }
                    }
                }

                // ===== AI Tailored Review Section =====
                Group {
                    if isSummarizing {
                        ProgressView("Tailoring review…")
                    } else if let ai = aiSummary {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tailored for you")
                                .font(.headline)

                            Text(ai.summary)

                            if !ai.tailoredPoints.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(ai.tailoredPoints, id: \.self) { point in
                                        Text("• \(point)")
                                    }
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }

                            Text("Fit score: \(ai.fitScore)/100")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else if let err = aiError {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tailored review")
                                .font(.headline)
                            Text(err).foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }

                // Optional: a button to retry/regenerate
                HStack {
                    Spacer()
                    Button {
                        Task { await loadTailoredSummary() }
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                    }
                    .disabled(isSummarizing)
                }
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(movie.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadTailoredSummary() }
    }

    // MARK: - AI Integration with Enhanced Debug Logging

    private func loadTailoredSummary() async {
        isSummarizing = true
        aiError = nil
        defer { isSummarizing = false }

        do {
            // 1) Kick off metadata and review fetches in parallel
            async let reviewsTask = TMDbService.getReviews(movieID: movie.id)
            async let detailsTask = TMDbService.getMovieDetails(movieID: movie.id)

            let reviews = try await reviewsTask
            let details = try await detailsTask

            // 2) Turn the user's preferences into human-readable tags
            let preferenceTags = moviePreferences.sortedSelectedGenresArray.map(\.title)

            // DEBUG: Log the raw API responses
            #if DEBUG
            print("\n🎬 ========== TMDb API Debug Output ==========")
            print("📽️ Movie: \(movie.title) (ID: \(movie.id))")
            
            print("\n📝 Reviews Response:")
            print("  - Total reviews fetched: \(reviews.count)")
            for (index, review) in reviews.prefix(3).enumerated() {
                print("  - Review \(index + 1):")
                print("    Author: \(review.author)")
                print("    Content preview: \(String(review.content.prefix(200)))...")
                print("    Created: \(review.createdAt ?? "Unknown")")
            }
            
            print("\n🎭 Movie Details Response:")
            print("  - Runtime: \(details.runtime ?? 0) minutes")
            print("  - Tagline: \(details.tagline ?? "None")")
            print("  - Genres: \(details.genres.map(\.name).joined(separator: ", "))")
            print("  - Vote Average: \(details.voteAverage) from \(details.voteCount) votes")
            
            if let credits = details.credits {
                print("\n  🎬 Credits:")
                print("    - Cast count: \(credits.cast?.count ?? 0)")
                let topCast = (credits.cast ?? []).prefix(5).map { member in
                    "\(member.name) as \(member.character ?? "Unknown")"
                }.joined(separator: ", ")
                print("    - Top cast: \(topCast)")
                
                if let directors = credits.crew?.filter({ $0.job == "Director" }) {
                    print("    - Directors: \(directors.map(\.name).joined(separator: ", "))")
                }
            }
            
            if let keywords = details.keywords?.keywords {
                print("\n  🏷️ Keywords (\(keywords.count) total):")
                let keywordNames = keywords.prefix(10).map(\.name).joined(separator: ", ")
                print("    \(keywordNames)")
            }
            
            print("\n  🌍 Production Info:")
            print("    - Countries: \(details.productionCountries.map(\.name).joined(separator: ", "))")
            print("    - Languages: \(details.spokenLanguages.map(\.englishName).joined(separator: ", "))")
            
            if let releaseDates = details.releaseDates?.results {
                if let usRelease = releaseDates.first(where: { $0.iso3166_1 == "US" }) {
                    if let cert = usRelease.releaseDates.first?.certification {
                        print("    - US Certification: \(cert)")
                    }
                }
            }
            
            if let providers = details.watchProviders?.results?["US"] {
                print("\n  📺 Watch Providers (US):")
                if let flatrate = providers.flatrate {
                    print("    - Streaming on: \(flatrate.map(\.providerName).joined(separator: ", "))")
                }
                if let rent = providers.rent {
                    print("    - Rent from: \(rent.map(\.providerName).joined(separator: ", "))")
                }
                if let buy = providers.buy {
                    print("    - Buy from: \(buy.map(\.providerName).joined(separator: ", "))")
                }
            }
            
            print("\n🎯 User Preferences:")
            print("  - Selected genres: \(preferenceTags.joined(separator: ", "))")
            print("  - Matching genres: \(details.genres.map(\.name).filter { genreName in preferenceTags.contains { $0.lowercased() == genreName.lowercased() } }.joined(separator: ", "))")
            
            print("========================================\n")
            #endif

            // 3) Ask the AI to tailor

            // 3) Ask the AI to tailor
            aiSummary = try await AIReviewService.shared.generateTailoredReview(
                movie: movie,
                details: details,
                reviews: reviews,
                preferenceTags: preferenceTags
            )
            
            #if DEBUG
            if let summary = aiSummary {
                print("\n✨ AI Generated Summary:")
                print("  - Summary length: \(summary.summary.count) chars")
                print("  - Summary: \(summary.summary)")
                print("  - Tailored Points (\(summary.tailoredPoints.count)):")
                for point in summary.tailoredPoints {
                    print("    • \(point)")
                }
                print("  - Fit Score: \(summary.fitScore)/100")
            }
            #endif
        } catch {
            #if DEBUG
            print("❌ AI summary error: \(error)")
            print("  - Error type: \(type(of: error))")
            print("  - Localized: \(error.localizedDescription)")
            #endif
            aiSummary = nil
            aiError = "Couldn't generate a tailored review right now."
        }
    }
}

// MARK: - Small utility for wrapping chips
private struct WrapHStack<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder var content: () -> Content

    var body: some View {
        // Use GeometryReader to get available width from context instead of deprecated UIScreen.main
        GeometryReader { geometry in
            FlexibleView(
                availableWidth: geometry.size.width,
                spacing: spacing,
                alignment: .leading,
                content: content
            )
        }
    }
}

// FlexibleView: lightweight wrap layout; not deprecated on iOS 26
private struct FlexibleView<Content: View>: View {
    let availableWidth: CGFloat
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    @ViewBuilder var content: () -> Content

    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
            _FlexibleContent(availableWidth: availableWidth, spacing: spacing, content: content)
                .background(viewHeightReader($totalHeight))
        }
        .frame(height: totalHeight)
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            DispatchQueue.main.async { binding.wrappedValue = geometry.size.height }
            return .clear
        }
    }
}

private struct _FlexibleContent<Content: View>: View {
    let availableWidth: CGFloat
    let spacing: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                content()
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > availableWidth) {
                            width = 0
                            height -= d.height + spacing
                        }
                        let result = width
                        if contentIsLast(d) { width = 0 } else { width -= d.width + spacing }
                        return result
                    }
                    .alignmentGuide(.top) { _ in height }
            }
        }
        .frame(height: 0) // Let FlexibleView compute height
    }

    private func contentIsLast(_ d: ViewDimensions) -> Bool { false }
}
