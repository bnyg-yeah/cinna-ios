//
//  Profile.swift
//  Cinna
//
//  Created by Brighton Young on 10/4/25.
//

import SwiftUI
import CoreLocation
import CoreLocationUI

struct Profile: View {
    @EnvironmentObject private var userInfo: UserInfoData
    private let locationManager = LocationManager()
    
    @State private var isRequestingLocation = false
    @State private var locationStatusMessage: String?
    @State private var locationErrorMessage: String?
    @State private var isShowingProfilePhotoPicker = false
    @State private var isShowingUserPhotosPicker = false
    @State private var selectedPhotoIndex: Int? = nil
    @State private var isShowingDeletePhotoSheet = false

    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Name
                Section("*Cinna* Profile Details") {
                    HStack(spacing: 12) {
                        Text("Name")
                            .bold()
                            .frame(minWidth: 60, alignment: .leading)
                        
                        SwiftUI.TextField("Your name", text: $userInfo.name)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .contentShape(Rectangle())
                    }
                }
                
                // MARK: - Location
                Section("Location") {
                    VStack(alignment: .leading, spacing: 12) {

                        let isSaved = (userInfo.useCurrentLocationBool && userInfo.currentLocation != nil)

                        Button {
                            Task { await requestLocationFlow() }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isSaved ? "checkmark.circle.fill" : "location.fill")
                                    .font(.headline.weight(.semibold))

                                Text(isSaved ? "Location Saved" : "Use My Location")
                                    .font(.headline.weight(.semibold))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .buttonStyle(.glassProminent)
                        .controlSize(.regular)
                        .disabled(isRequestingLocation || isSaved)
                        .opacity(isSaved ? 0.55 : 1)
                        .animation(.easeInOut(duration: 0.2), value: isSaved)

                        if isSaved {
                            Button("Stop Using Current Location") {
                                userInfo.clearLocation()
                                locationStatusMessage = "Current location disabled."
                                locationErrorMessage = nil
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .tint(.red)
                            .frame(maxWidth: .infinity)
                        }

                        Group {
                            if isRequestingLocation {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Updating location…")
                                }
                                .foregroundStyle(.secondary)

                            } else if let locationStatusMessage {
                                Text(locationStatusMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                            } else if let locationErrorMessage {
                                Text(locationErrorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.red)

                            } else if isSaved {
                                Text("Location saved and ready to use for nearby theaters.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                            } else {
                                Text("Share your location to find nearby theaters.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    }
                }//end Location
                
                // MARK: Profile Photo
                Section("Profile Photo") {
                    // Row 1 - image only, not tappable
                    HStack {
                        Spacer()
                        Image(uiImage: userInfo.profilePhoto ?? UIImage(named: "UserPicture")!)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                            .shadow(radius: 4)
                            .padding(.vertical, 8)
                        Spacer()
                    }
                    
                    // Row 2 - choose photo button
                    Button("Choose Profile Photo") {
                        isShowingProfilePhotoPicker = true
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    if let realPhoto = userInfo.profilePhoto,
                       realPhoto != UIImage(named: "UserPicture") {
                        Button("Remove Profile Photo") {
                            userInfo.profilePhoto = nil
                        }
                        .foregroundColor(.red)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }

                }
                
                // MARK: User Photos
                // MARK: User Photos
                Section("User Photos") {

                    // Scrollable thumbnails
                    if !userInfo.userPhotos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(userInfo.userPhotos.enumerated()), id: \.offset) { index, photo in
                                    Image(uiImage: photo)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 140)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .clipped()
                                        .contentShape(Rectangle())   // ensures only this photo highlights on press
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                UserPhotosManager.shared.removeUserPhoto(at: index, from: &userInfo.userPhotos)
                                            } label: {
                                                Label("Delete Photo", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }

                    // Add + Clear layout
                    HStack {
                        Button("Add Photos") {
                            isShowingUserPhotosPicker = true
                        }
                        .buttonStyle(.glass)
                        .foregroundColor(.blue)
                        .controlSize(.large)
                        .disabled(userInfo.userPhotos.count >= 10)

                        Spacer()

                        if !userInfo.userPhotos.isEmpty {
                            Button("Clear User Photos") {
                                userInfo.clearUserPhotos()
                            }
                            .buttonStyle(.glass)
                            .foregroundColor(.red)
                            .controlSize(.large)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }//end user photos section



            }
            .scrollContentBackground(.hidden)
            .background(BackgroundView())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $isShowingProfilePhotoPicker) {
            PhotoPicker(allowMultiple: false) { images in
                if let first = images.first {
                    userInfo.profilePhoto = first
                }
            }
        }
        .sheet(isPresented: $isShowingUserPhotosPicker) {
            PhotoPicker(allowMultiple: true) { images in
                let _ = userInfo.addUserPhotos(images)
            }
        }
        .sheet(isPresented: $isShowingDeletePhotoSheet) {
            if let index = selectedPhotoIndex {
                VStack(spacing: 24) {

                    Text("Delete this photo?")
                        .font(.title2)
                        .padding(.top)

                    Image(uiImage: userInfo.userPhotos[index])
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("Delete Photo") {
                        UserPhotosManager.shared.removeUserPhoto(at: index, from: &userInfo.userPhotos)
                        isShowingDeletePhotoSheet = false
                    }
                    .foregroundColor(.red)
                    .buttonStyle(.borderedProminent)

                    Button("Cancel") {
                        isShowingDeletePhotoSheet = false
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                }
                .padding()
            }
        }

    }
}

#Preview {
    Profile()
        .environmentObject(UserInfoData())
}

// MARK: - Location flow
extension Profile {
    @MainActor
    private func requestLocationFlow() async {
        guard !isRequestingLocation else { return }
        
        isRequestingLocation = true
        locationStatusMessage = nil
        locationErrorMessage = nil
        isShowingProfilePhotoPicker = false
        isShowingUserPhotosPicker = false
        selectedPhotoIndex = nil
        isShowingDeletePhotoSheet = false
        
        do {
            // Uses your existing manager: ensures auth + one-shot location
            let coordinate = try await locationManager.requestLocation()
            
            // Persist with “while using” semantics
            userInfo.updateLocation(coordinate, preference: .allowWhileUsing)
            locationStatusMessage = "Location saved for nearby theaters."
        } catch {
            userInfo.clearLocation()
            locationErrorMessage = (error as? LocalizedError)?.errorDescription
            ?? error.localizedDescription
        }
        
        isRequestingLocation = false
    }
}
