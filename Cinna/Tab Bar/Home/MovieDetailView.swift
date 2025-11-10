//
//  MovieDetailView.swift
//  Cinna
//
//  Updated to separate factual metadata from AI summary.
//  Technical details (runtime, rating, etc.) now render in UI above Tailored section.
//

import SwiftUI

struct MovieDetailView: View {
    let movie: TMDbMovie

    @EnvironmentObject private var moviePreferences: MoviePreferencesData

    @State private var aiSummary: AITailoredSummary?
    @State private var aiError: String?
    @State private var isSummarizing = false
    @State private var movieDetails: TMDbMovieDetails?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // ===== Header / artwork / metadata =====
                Text(movie.title)
                    .font(.title.bold())

                if !movie.overview.isEmpty {
                    Text(movie.overview)
                        .foregroundStyle(.secondary)
                }

                // ===== Technical details (not part of AI summary) =====
                if let d = movieDetails {
                    let runtimeText: String = {
                        guard let r = d.runtime, r > 0 else { return "N/A" }
                        let h = r / 60
                        let m = r % 60
                        return h > 0 ? "\(h)h \(String(format: "%02d", m))m" : "\(m)m"
                    }()

                    let certificationText: String = {
                        guard let results = d.releaseDates?.results, !results.isEmpty else { return "N/A" }
                        let primary = results.first { $0.iso3166_1 == "US" } ?? results.first
                        let cert = primary?.releaseDates.first { c in
                            guard let v = c.certification?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
                            return !v.isEmpty
                        }?.certification
                        return (cert?.isEmpty == false) ? cert! : "N/A"
                    }()

                    let scoreText = String(format: "%.1f/10", d.voteAverage)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            if !movie.year.isEmpty {
                                Text("Year \(movie.year)")
                            }
                            Divider()
                            Text("Runtime \(runtimeText)")
                            Divider()
                            Text("Score \(scoreText)")
                            Divider()
                            Text("Rated \(certificationText)")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }

                // ===== Preferences chips (visual only) =====
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

                // ===== Regenerate button =====
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

    // MARK: - AI Integration
    private func loadTailoredSummary() async {
        isSummarizing = true
        aiError = nil
        defer { isSummarizing = false }

        do {
            async let reviewsTask = TMDbService.getReviews(movieID: movie.id)
            async let detailsTask = TMDbService.getMovieDetails(movieID: movie.id)

            let reviews = try await reviewsTask
            let details = try await detailsTask
            self.movieDetails = details

            let preferenceTags = moviePreferences.sortedSelectedGenresArray.map(\.title)

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
            #endif
            aiSummary = nil
            aiError = "Couldn't generate a tailored review right now."
        }
    }
}

// MARK: - Wrap Layouts (unchanged)
private struct WrapHStack<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder var content: () -> Content

    var body: some View {
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

        return GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                content()
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > availableWidth) {
                            width = 0
                            height -= d.height + spacing
                        }
                        let result = width
                        width -= d.width + spacing
                        return result
                    }
                    .alignmentGuide(.top) { _ in height }
            }
        }
        .frame(height: 0)
    }
}
