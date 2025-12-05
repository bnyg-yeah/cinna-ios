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
    
    private var storedImage: StoredImage? {
        MovieDataStore.shared.entry(for: movieID)?.backdrops[index]
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
                )//end image
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Photos")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if userInfo.userPhotos.isEmpty {
                        Text("No user photos added")
                            .foregroundStyle(.secondary)
                    }
                    else {
                        HStack(spacing: 12) {
                            ForEach(Array(userInfo.userPhotos.enumerated()), id: \.offset) { _, photo in
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }//end user photos display
            }
            .navigationTitle("Backdrop")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }//end navigation stack
    }//end body
}
