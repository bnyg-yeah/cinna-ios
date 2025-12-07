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
    @StateObject private var userRatings = UserRatings.shared
    @EnvironmentObject private var userInfo: UserInfoData
    
    @State private var aiSummary: AIMovieOverview?
    @State private var aiError: String?
    @State private var isSummarizing = false
    @State private var movieDetails: TMDbMovieDetails?
    
    @State private var backdrops: [TMDbService.TMDbImage] = []
    @State private var logos: [TMDbService.TMDbImage] = []
    @State private var isLoadingImages = false
    @State private var imageError: String?
    @State private var selectedBackdropIndex: Int?

    
    private var currentUserRating: Int? {
        userRatings.getRating(for: movie.id)
    }
    
    var body: some View {
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
                    
                    let dateText = movie.formattedReleaseDate(.monthYear)
                    
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
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(moviePreferences.sortedSelectedGenresArray, id: \.self) { genre in
                                    Text(genre.title)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .glassEffect(.regular.interactive(), in: Capsule())
                                }
                                if !moviePreferences.sortedSelectedFilmmakingArray.isEmpty{
                                    ForEach(moviePreferences.sortedSelectedFilmmakingArray, id: \.self) { filmmaking in
                                        Text(filmmaking.title)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .glassEffect(.regular.interactive(), in: Capsule())
                                    }
                                }
                                if !moviePreferences.sortedSelectedAnimationArray.isEmpty{
                                    ForEach(moviePreferences.sortedSelectedAnimationArray, id: \.self) { animation in
                                        Text(animation.title)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .glassEffect(.regular.interactive(), in: Capsule())
                                    }
                                }
                                
                            }
                            //                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // ===== AI Tailored Overview Section =====
                Group {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tailored overview")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            if isSummarizing {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else if let aiOutput = aiSummary {
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
                            } else if let err = aiError {
                                Text(err)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.clear)                                   // make fill transparent so it doesn’t add its own color
                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        )
                        
                    }
                    
                }//end overview
                
                if isLoadingImages {
                    ProgressView("Loading images…")
                        .foregroundColor(.white)
                } else if let imageError {
                    Text(imageError)
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    if !backdrops.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Backdrops")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 6)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    
                                    ForEach(Array(backdrops.enumerated()), id: \.offset) { index, img in
                                        
                                        if let url = TMDbService.imageURL(path: img.filePath, size: "w780") {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(img.aspectRatio, contentMode: .fit)
                                                        .frame(height: 160)
                                                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                                                        .onTapGesture {
                                                            selectedBackdropIndex = index
                                                        }
                                                case .failure:
                                                    Color.white.opacity(0.1)
                                                        .frame(width: 240, height: 160)
                                                        .glassEffect(.regular.interactive(), in: .rect())
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                        }
                                    }
                                }
                            }//end backdrops scroll view
                            Text("Tap a backdrop to generate an AI scene blend!")
                                .font(.footnote)
                                .foregroundColor(.white)
                        }//end backdrops vstack
                    }
                    
//                    if !logos.isEmpty {
//                        VStack(alignment: .leading, spacing: 12) {
//                            Text("Logos")
//                                .font(.headline)
//                                .foregroundColor(.white)
//                            ScrollView(.horizontal, showsIndicators: false) {
//                                HStack(spacing: 12) {
//                                    ForEach(logos) { img in
//                                        if let url = TMDbService.imageURL(path: img.filePath, size: "w300") {
//                                            AsyncImage(url: url) { phase in
//                                                switch phase {
//                                                case .empty:
//                                                    ProgressView()
//                                                case .success(let image):
//                                                    image
//                                                        .resizable()
//                                                        .scaledToFit()
//                                                        .frame(height: 80)
//                                                        .padding(10)
//                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
//                                                        .glassEffect(.clear.interactive(),
//                                                                     in: RoundedRectangle(cornerRadius:12, style: .continuous))
//                                                    
//                                                    
//                                                case .failure:
//                                                    Color.white.opacity(0.1)
//                                                        .frame(width: 140, height: 80)
//                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
//                                                        .glassEffect(.clear.interactive(),
//                                                                     in: RoundedRectangle(cornerRadius:12, style: .continuous))
//                                                @unknown default:
//                                                    EmptyView()
//                                                }
//                                            }
//                                        }
//                                    }
//                                }
//                                .padding(.vertical, 4)
//                            }
//                        }
//                    }//end logos
                }//end loading images
                
                // ===== User Rating =====
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rate this movie!")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(alignment: .center, spacing: 10) {
                        ForEach(1...4, id: \.self) { value in
                            Button {
                                UserRatings.shared.setRating(value, for: movie.id)
                            } label: {
                                Text("\(value)")
                                    .font(.headline)
                                    .frame(width: 44, height: 44)
                                    .glassEffect(in: .circle)
                                    .foregroundColor((currentUserRating == value) ? .white : .gray)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Button {
                            UserRatings.shared.clearRating(for: movie.id)
                        } label: {
                            Text("Clear")
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.glass(.clear))
                        
                    }
                    
                    if let current = currentUserRating {
                        Text("Your rating: \(current)/4")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not rated yet")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }//end rating
                
                
            }//end VStack of everything
            .padding(.top, 24)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            
        }//end Scroll view
        .scrollIndicators(.hidden)
        .background(BackgroundView())
        .navigationTitle(Text("Selected Movie"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadImages()
            await loadTailoredSummary()
        }
        .sheet(isPresented: Binding(
            get: { selectedBackdropIndex != nil },
            set: { if !$0 { selectedBackdropIndex = nil } }
        )) {
            if let index = selectedBackdropIndex {
                BackdropView(movieID: movie.id, index: index)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }


        
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
            MovieDataStore.shared.storeReviews(reviews, for: movie.id)

            let details = try await detailsTask
            self.movieDetails = details
            MovieDataStore.shared.storeDetails(details, for: movie.id)
            
            let preferenceTags = moviePreferences.sortedSelectedGenresArray.map(\.title)
            
            //Call Gemini HERE
            aiSummary = try await AIOverviewService.shared.generateTailoredOverview(
                movie: movie,
                details: details,
                reviews: reviews,
                preferenceTags: preferenceTags
            )
            
#if DEBUG
            if let summary = aiSummary {
                print("\nAI Generated Summary:")
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
    
    private func loadImages() async {
        isLoadingImages = true
        imageError = nil
        defer { isLoadingImages = false }
        do {
            let res = try await TMDbService.getImages(movieID: movie.id)
            backdrops = res.backdrops
            logos = res.logos
            
            let storedBackdrops = convertStoredImage(res.backdrops)
            let storedLogos = convertStoredImage(res.logos)
            
            MovieDataStore.shared.storeBackdrops(storedBackdrops, for: movie.id)
            MovieDataStore.shared.storeLogos(storedLogos, for: movie.id)
            
        } catch {
            imageError = "Couldn't load images right now."
            backdrops = []
            logos = []
        }
    }
    
    private func convertStoredImage(_ images: [TMDbService.TMDbImage]) -> [StoredImage] {
        images.map {
            StoredImage(
                filePath: $0.filePath,
                aspectRatio: $0.aspectRatio,
                url_w300: TMDbService.imageURL(path: $0.filePath, size: "w300"),
                url_w780: TMDbService.imageURL(path: $0.filePath, size: "w780"),
                url_original: TMDbService.imageURL(path: $0.filePath, size: "original")
            )
        }
    }
}

