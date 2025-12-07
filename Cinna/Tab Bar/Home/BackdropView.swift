//
//  BackdropView.swift
//  Cinna
//
//  Created by Brighton Young on 12/5/25.
//
// This should bring up a sheet of the backdrop and user photos on the bottom for the user to ai integrate themselves into the backdrop scene

import SwiftUI

struct BackdropView: View {
    let movieID: Int
    let index: Int
    
    @Environment(\.dismiss) private var dismiss //for prompt
    @EnvironmentObject private var userInfo: UserInfoData //for user photos
    
    @State private var selectedUserPhotoIndex: Int?
    @State private var isBlending = false
    @State private var blendedImage: UIImage?
    @State private var blendError: String?
    @State private var readyToShowResult = false
    
    private var storedImage: StoredImage? {
        MovieDataStore.shared.entry(for: movieID)?.backdrops.indices.contains(index) == true
        ? MovieDataStore.shared.entry(for: movieID)?.backdrops[index]
        : nil
    }
    
    private var selectedUserPhoto: UIImage? {
        guard let selectedUserPhotoIndex else {
            return nil
        }
        guard userInfo.userPhotos.indices.contains(selectedUserPhotoIndex) else {
            return nil
        }
        return userInfo.userPhotos[selectedUserPhotoIndex]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                AsyncImage(
                    url: storedImage?.url_w780,
                    content: { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .glassEffect(in: .rect()
                            )
                            .padding(.horizontal, 12)
                    },
                    placeholder: {
                        ProgressView()
                    }
                ) // end image
                
                VStack(alignment: .center, spacing: 8) {
                    Text("Select a photo to see yourself in the scene!")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if userInfo.userPhotos.isEmpty {
                        Text("No user photos added")
                            .foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 12) {
                            ForEach(Array(userInfo.userPhotos.enumerated()), id: \.offset) { idx, photo in
                                Button {
                                    if selectedUserPhotoIndex == idx {
                                        selectedUserPhotoIndex = nil    // tap to deselect
                                    } else {
                                        selectedUserPhotoIndex = idx    // select new
                                    }
                                } label: {
                                    Image(uiImage: photo)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 160, height: 160)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .glassEffect(
                                                .regular.interactive(),
                                                in: RoundedRectangle(cornerRadius: 12)
                                            )
                                        .overlay(alignment: .center) {
                                            if selectedUserPhotoIndex == idx {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 20, weight: .semibold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedUserPhotoIndex == idx ? Color.white : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // Always-visible Blend button, placed below the user photos, sized to its label
                Button {
                    readyToShowResult = true
                } label: {
                    Text("Blend")
                        .font(.title3.weight(.semibold))
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .disabled(selectedUserPhoto == nil || storedImage?.url_w780 == nil)
                
            }
            .navigationTitle("Movie Scene Blend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $readyToShowResult) {
                if let selectedUserPhoto, let backdropURL = storedImage?.url_w780 {
                    SceneBlendResultView(
                        backdropURL: backdropURL,
                        userImage: selectedUserPhoto
                    )
                }
            }
        } // end NavigationStack
    } // end body
}
