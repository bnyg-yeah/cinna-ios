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
    
    @State private var aiSummary: AIMovieOverview?
    @State private var aiError: String?
    @State private var isSummarizing = false
    @State private var movieDetails: TMDbMovieDetails?
    
    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // ===== Header / artwork / metadata =====
                    Text(movie.title)
                        .font(.title.bold())
                        .foregroundColor(.white)

                    if !movie.overview.isEmpty {
                        Text(movie.overview)
                            .foregroundColor(.white.opacity(0.8))
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

                        let dateText: String = {
                            guard let releaseDate = movie.releaseDate, !releaseDate.isEmpty else { return "N/A" }

                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"

                            guard let date = formatter.date(from: releaseDate) else { return "N/A" }

                            formatter.dateFormat = "MMMM yyyy"
                            return formatter.string(from: date)
                        }()

                        HStack(spacing: 14) {
                            Text("Released \(dateText)")
                            Divider()
                            Text("Runtime \(runtimeText)")
                            Divider()
                            Text("Score \(scoreText)")
                            Divider()
                            Text("Rating \(certificationText)")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    }

                    // ===== Preferences chips (visual only) =====
                    if !moviePreferences.sortedSelectedGenresArray.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your preferences")
                                .font(.headline)
                                .foregroundColor(.white)
                            HStack {
                                ForEach(moviePreferences.sortedSelectedGenresArray, id: \.self) { genre in
                                    Text(genre.title)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .glassEffect(in: Capsule())
                                }
                            }
                        }
                    }

                    // ===== AI Tailored Overview Section =====
                    Group {
                        if isSummarizing {
                            ProgressView("Tailoring overview…")
                                .foregroundColor(.white)
                        } else if let aiOutput = aiSummary {
                            VStack(alignment: .leading, spacing: 12){
                                Text("Tailored for you")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(aiOutput.summary)

                                    if !aiOutput.tailoredPoints.isEmpty {
                                        VStack(alignment: .leading, spacing: 6) {
                                            ForEach(aiOutput.tailoredPoints, id: \.self) { point in
                                                Text("• \(point)")
                                            }
                                        }
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    }

                                    Text("Fit score: \(aiOutput.fitScore)/100")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(16)
                                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                            }
                        } else if let err = aiError {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tailored overview")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(err)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(16)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .glassEffect()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .contentMargins(.top, 16)
            .scrollIndicators(.hidden)
        }
        .navigationTitle(Text("Selected Movie"))
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
            
            //Call Gemini HERE
//            aiSummary = try await AIOverviewService.shared.generateTailoredOverview(
//                movie: movie,
//                details: details,
//                reviews: reviews,
//                preferenceTags: preferenceTags
//            )
            
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
            aiError = "Couldn't generate a tailored overview right now."
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
