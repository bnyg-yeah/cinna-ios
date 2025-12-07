//
//  SceneBlendResultView.swift
//  Cinna
//
//  Created by Brighton Young on 12/6/25.
//

import SwiftUI

struct SceneBlendResultView: View {
    let backdropURL: URL
    let userImage: UIImage
    
    @State private var isLoading = true
    @State private var resultImage: UIImage?
    @State private var errorMessage: String?
    
    @Environment(\.dismiss) private var dismiss
    
    // Preview-only convenience initializer to seed state
    init(backdropURL: URL, userImage: UIImage, previewResultImage: UIImage? = nil) {
        self.backdropURL = backdropURL
        self.userImage = userImage
        if let previewResultImage {
            // Seed @State via _ property wrappers
            self._isLoading = State(initialValue: false)
            self._resultImage = State(initialValue: previewResultImage)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                        Text("Blending your scene...")
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                else if let img = resultImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(img.size, contentMode: .fit) //preserve blended image ratio
                }
                else if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .task {
                await blend()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func blend() async {
        do {
            let result = try await AIMovieSceneBlenderService.shared.blendUserIntoBackdrop(
                backdropURL: backdropURL,
                userImage: userImage
            )
            await MainActor.run {
                self.resultImage = result.image
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Could not create blended image."
                self.isLoading = false
            }
        }
    }
}
