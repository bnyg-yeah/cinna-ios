//
//  UserInfoData.swift
//  Cinna
//
//  Created by Brighton Young on 10/10/25.
//

import Combine
import CoreLocation
import Foundation
import UIKit

final class UserInfoData: ObservableObject {
    
    // MARK: - Published user fields
    @Published var name: String {
        didSet { defaults.set(name, forKey: Keys.name) }
    }
    
    /// Mirror flag if you want to show a toggle/switch elsewhere (optional).
    @Published var useCurrentLocationBool: Bool {
        didSet {
            defaults.set(useCurrentLocationBool, forKey: Keys.useCurrentLocationBool)
            if !useCurrentLocationBool {
                resetStoredLocation()
            }
        }
    }
    
    @Published var currentLocation: CLLocationCoordinate2D? {
        didSet {
            if let currentLocation {
                defaults.set(currentLocation.latitude, forKey: Keys.latitude)
                defaults.set(currentLocation.longitude, forKey: Keys.longitude)
            } else {
                defaults.removeObject(forKey: Keys.latitude)
                defaults.removeObject(forKey: Keys.longitude)
            }
        }
    }
    
    @Published var locationPreference: LocationPreference? {
        didSet {
            if let locationPreference {
                defaults.set(locationPreference.rawValue, forKey: Keys.locationPreference)
            } else {
                defaults.removeObject(forKey: Keys.locationPreference)
            }
        }
    }
    
    /// Photo storages
    @Published var profilePhoto: UIImage? {
        didSet {
            if let image = profilePhoto {
                UserPhotosManager.shared.saveProfilePhoto(image)
            }
            else {
                UserPhotosManager.shared.deleteProfilePhoto()
            }
        }
    }
    
    @Published var userPhotos: [UIImage] {
        didSet {
            UserPhotosManager.shared.saveUserPhotos(userPhotos)
        }
    }
    
    // MARK: - Storage
    private let defaults: UserDefaults
    
    // MARK: - Init
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        
        // Load basic info
        self.name = defaults.string(forKey: Keys.name) ?? ""
        self.useCurrentLocationBool = defaults.object(forKey: Keys.useCurrentLocationBool) as? Bool ?? false
        
        // Load location
        if let lat = defaults.object(forKey: Keys.latitude) as? CLLocationDegrees,
           let lon = defaults.object(forKey: Keys.longitude) as? CLLocationDegrees {
            self.currentLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            self.currentLocation = nil
        }
        
        if let raw = defaults.string(forKey: Keys.locationPreference),
           let pref = LocationPreference(rawValue: raw) {
            self.locationPreference = pref
        } else {
            self.locationPreference = nil
        }
        
        // Load photos
        self.profilePhoto = UserPhotosManager.shared.loadProfilePhoto()
        self.userPhotos = UserPhotosManager.shared.loadUserPhotos()
    }
    
    // MARK: - Location helps used by views
    func updateLocation(_ coordinate: CLLocationCoordinate2D, preference: LocationPreference) {
        currentLocation = coordinate
        locationPreference = preference
        useCurrentLocationBool = true
    }
    
    func clearLocation() {
        if useCurrentLocationBool {
            useCurrentLocationBool = false
        } else {
            resetStoredLocation()
        }
    }
    
    private func resetStoredLocation() {
        currentLocation = nil
        locationPreference = nil
    }
    
    // MARK: Photo helpers used by views
    
    // add a single photo to user photos array (max 10 photos) for ai generation, not the profile photo
    @discardableResult
    func addUserPhoto(_ photo: UIImage) -> Bool {
        return UserPhotosManager.shared.addUserPhoto(photo, to: &userPhotos)
    }
    
    //add multiple photos at once, maximum of 10 in the photo array
    func addUserPhotos(_ photos: [UIImage]) -> Bool {
        return UserPhotosManager.shared.addUserPhotos(photos, to: &userPhotos)
    }
    
    //clear all user photos
    func clearUserPhotos() {
        userPhotos = []
        UserPhotosManager.shared.deleteAllUserPhotoFiles()
    }
    
    // clear all photos, including the profile photo, should only be in the privacy/security view
    func clearAllPhotos() {
        profilePhoto = nil
        userPhotos = []
        UserPhotosManager.shared.deleteAllUserPhotoFiles()
    }
    
    
    // MARK: - Keys
    private enum Keys {
        static let name = "UserInfo.name"
        static let useCurrentLocationBool = "UserInfo.useCurrentLocationBool"
        static let latitude = "UserInfo.latitude"
        static let longitude = "UserInfo.longitude"
        static let locationPreference = "UserInfo.locationPreference"
    }
}
