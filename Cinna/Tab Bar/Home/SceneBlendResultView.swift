//
//  SceneBlendResultView.swift
//  Cinna
//
//  Created by Brighton Young on 12/6/25.
//

import SwiftUI
import PhotosUI

struct SceneBlendResultView: View {
    let backdropURL: URL
    let userImage: UIImage
    
    @State private var isLoading = true
    @State private var resultImage: UIImage?
    @State private var errorMessage: String?
    @State private var hasSaved = false
    
    @Environment(\.dismiss) private var dismiss
    
    init(backdropURL: URL, userImage: UIImage, previewResultImage: UIImage? = nil) {
        self.backdropURL = backdropURL
        self.userImage = userImage
        if let previewResultImage {
            self._isLoading = State(initialValue: false)
            self._resultImage = State(initialValue: previewResultImage)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Spacer(minLength: 0)
                    
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
                            .aspectRatio(img.size, contentMode: .fit)
                            .padding(.horizontal, 20)
                    }
                    else if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                    
                    Spacer(minLength: 0)
                    
                    if resultImage != nil {
                        Button {
                            saveImageToPhotos()
                        } label: {
                            Text(hasSaved ? "Saved" : "Save to Photos")
                                .font(.headline.weight(.semibold))
                        }
                        .buttonStyle(.glassProminent)
                        .controlSize(.large)
                        .padding(.bottom, 24)
                        .disabled(hasSaved)
                        .opacity(hasSaved ? 0.6 : 1)
                    }
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

    private func saveImageToPhotos() {
        guard let uiImage = resultImage else { return }

        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                DispatchQueue.main.async {
                    self.hasSaved = true
                }
            }
        }
    }
}
