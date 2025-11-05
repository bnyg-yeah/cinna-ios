//
//  MovieDetailView.swift
//  Cinna
//
//  Updated to generate AI-tailored summaries using user preferences.
//  Make sure AIReviewService.swift and TMDbService+Reviews.swift are added.
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

    // MARK: - AI Integration

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

            // 3) Ask the AI to tailor
            aiSummary = try await AIReviewService.shared.generateTailoredReview(
                movie: movie,
                details: details,
                reviews: reviews,
                preferenceTags: preferenceTags
            )
        } catch {
            #if DEBUG
            print("AI summary error:", error)
            #endif
            aiSummary = nil
            aiError = "Couldn’t generate a tailored review right now."
        }
    }
}

// MARK: - Small utility for wrapping chips
private struct WrapHStack<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder var content: () -> Content

    var body: some View {
        // Simple fallback layout that works fine without iOS 17+ FlowLayout APIs
        FlexibleView(
            availableWidth: UIScreen.main.bounds.width - 48, // matches .padding(24) on container
            spacing: spacing,
            alignment: .leading,
            content: content
        )
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
