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
                            .glassEffect(
                                .regular.interactive(),
                                in: RoundedRectangle(cornerRadius: 18)
                            )
                    },
                    placeholder: {
                        ProgressView()
                    }
                ) // end image
                
                VStack(alignment: .leading, spacing: 12) {
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
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedUserPhotoIndex == idx ? Color.cyan : Color.clear, lineWidth: 3)
                                        )
                                        .overlay(alignment: .topTrailing) {
                                            if selectedUserPhotoIndex == idx {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.cyan)
                                                    .padding(6)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .padding(.vertical, 6)
            .navigationTitle("Backdrop")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        } // end NavigationStack
    } // end body
}
