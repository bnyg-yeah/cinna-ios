//
//  UserPhotosManager.swift
//  Cinna
//
//  Created by Brighton Young on 12/4/25.
//

import Foundation
import UIKit

final class UserPhotosManager {
    
    static let shared = UserPhotosManager()
    
    // MARK: file system paths
    private let fileManager = FileManager.default
    
    //directory where all photos are stored
    private lazy var photosDirectory: URL = {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosURL = documentsURL.appendingPathComponent("UserPhotos", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: photosURL.path) {
            try? fileManager.createDirectory(at: photosURL, withIntermediateDirectories: true)
            print("📁 Created UserPhotos directory at: \(photosURL.path)")
        }
        
        return photosURL
    }()
    
    //file url for profile photo
    private var profilePhotoURL: URL {
        photosDirectory.appendingPathComponent("profilePhoto.jpg")
    }
    
    //file url for user photo at a specific index
    private func userPhotoURL(at index: Int) -> URL {
        photosDirectory.appendingPathComponent("userPhoto_\(index).jpg")
    }
    
    private init() {}
    
    
    
    // MARK: profile photo management
    
    //save profile photo to file system
    func saveProfilePhoto(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert profile photo to JPEG data")
            return
        }
        
        do {
            try data.write(to: profilePhotoURL)
            
            #if DEBUG
            let sizeInMB = Double(data.count) / (1024 * 1024)
            print("✅ Saved profile photo to file system (\(String(format: "%.2f", sizeInMB)) MB)")
            print("📍 Location: \(profilePhotoURL.path)")
            #endif
            
        } catch {
            print("Failed to save profile photo: \(error)")
        }
    }
    
    // Load profile photo from file system, returns default "UserPicture" if none saved
    func loadProfilePhoto() -> UIImage? {
        // Try to load saved photo first
        if fileManager.fileExists(atPath: profilePhotoURL.path),
           let data = try? Data(contentsOf: profilePhotoURL),
           let image = UIImage(data: data) {
            
            #if DEBUG
            let sizeInMB = Double(data.count) / (1024 * 1024)
            print("✅ Loaded profile photo from file system (\(String(format: "%.2f", sizeInMB)) MB)")
            #endif
            
            return image
        }
        
        // Return default image from assets
        if let defaultImage = UIImage(named: "UserPicture") {
            
            #if DEBUG
            print("📷 Using default UserPicture from assets")
            #endif
            
            return defaultImage
        }
        
        #if DEBUG
        print("⚠️ No saved photo and UserPicture asset not found")
        #endif
        
        return nil
    }
    
    
    // Delete profile photo from file system
    func deleteProfilePhoto() {
        guard fileManager.fileExists(atPath: profilePhotoURL.path) else {
            print("No profile photo to delete, only have the default UserPicture from Assets")
            return
        }
        
        do {
            try fileManager.removeItem(at: profilePhotoURL)
            print("Deleted profile photo from file system")
        } catch {
            print("Failed to delete profile photo: \(error)")
        }
    }
    
    // MARK: User Photos Management
    
    
    // Save all user photos to file system
    func saveUserPhotos(_ photos: [UIImage]) {
        // First, save all photos in the array
        for (index, image) in photos.enumerated() {
            
            //convert to jpeg
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                print("Failed to convert user photo \(index) to JPEG data")
                continue
            }
            
            let fileURL = userPhotoURL(at: index)
            do {
                try data.write(to: fileURL)
            } catch {
                print("Failed to save user photo \(index): \(error)")
            }
        }
        
        #if DEBUG
        let totalSize = photos.compactMap { $0.jpegData(compressionQuality: 0.8) }
            .reduce(0) { $0 + $1.count }
        let sizeInMB = Double(totalSize) / (1024 * 1024)
        print("✅ Saved \(photos.count) user photos to file system (\(String(format: "%.2f", sizeInMB)) MB total)")
        #endif
    }
    
    
    // Load all user photos from file system
    func loadUserPhotos() -> [UIImage] {
        var photos: [UIImage] = []
        var index = 0
        
        // Load photos until we find a gap (no file at that index)
        while index < 10 { // Max 10 photos
            let fileURL = userPhotoURL(at: index)
            
            if fileManager.fileExists(atPath: fileURL.path),
               let data = try? Data(contentsOf: fileURL),
               let image = UIImage(data: data) {
                photos.append(image)
            } else {
                // No more photos to load
                break
            }
            
            index += 1
        }
        
        #if DEBUG
        if !photos.isEmpty {
            let totalSize = photos.compactMap { $0.jpegData(compressionQuality: 0.8) }
                .reduce(0) { $0 + $1.count }
            let sizeInMB = Double(totalSize) / (1024 * 1024)
            print("✅ Loaded \(photos.count) user photos from file system (\(String(format: "%.2f", sizeInMB)) MB total)")
        }
        #endif
        
        return photos
    }
    
    
    // Add a single photo to user photos (max 10)
    func addUserPhoto(_ photo: UIImage, to existingPhotos: inout [UIImage]) -> Bool {
        
        guard existingPhotos.count < 10 else {
            print("Maximum of 10 user photos reached")
            return false
        }
        
        existingPhotos.append(photo)
        saveUserPhotos(existingPhotos)
        return true
    }
    
    // Add multiple photos to user photos (fails if would exceed 10 max)
    func addUserPhotos(_ photos: [UIImage], to existingPhotos: inout [UIImage]) -> Bool {
        // Check if adding these photos would exceed max
        if existingPhotos.count + photos.count > 10 {
            print("Cannot add \(photos.count) photos - would exceed maximum of 10 (currently have \(existingPhotos.count))")
            return false
        }
        
        // Add all photos
        existingPhotos.append(contentsOf: photos)
        saveUserPhotos(existingPhotos)
        
        print("Added \(photos.count) photos (total: \(existingPhotos.count)/10)")
        return true
    }
    
    
    // MARK: removing photos
    
    // Remove a photo at specific index
    func removeUserPhoto(at index: Int, from existingPhotos: inout [UIImage]) -> Bool {
        // Remove from array
        existingPhotos.remove(at: index)
        
        // Delete the file at the removed index
        let removedFileURL = userPhotoURL(at: index)
        if fileManager.fileExists(atPath: removedFileURL.path) {
            try? fileManager.removeItem(at: removedFileURL)
        }
        
        // Shift files after the removed index down by renaming them
        // e.g., if we removed index 2, rename user_3 → user_2, user_4 → user_3, etc.
        if index < existingPhotos.count {
            for i in (index + 1)...existingPhotos.count {
                let oldURL = userPhotoURL(at: i)
                let newURL = userPhotoURL(at: i - 1)
                
                if fileManager.fileExists(atPath: oldURL.path) {
                    try? fileManager.moveItem(at: oldURL, to: newURL)
                }
            }
        }
        
        print("Removed photo at index \(index), shifted \(existingPhotos.count - index) files")
        
        return true
    }

    
    // Delete all user photo files from file system
    func deleteAllUserPhotoFiles() {
        for index in 0..<10 {
            let fileURL = userPhotoURL(at: index)
            if fileManager.fileExists(atPath: fileURL.path) {
                try? fileManager.removeItem(at: fileURL)
            }
        }
        print("Deleted all user photo files, but not profile photo")
    }
    
    // Clear all photos including profile photo, we can have this in the privacy and security page
    func clearAllPhotos() {
        deleteProfilePhoto()
        deleteAllUserPhotoFiles()
        print("Cleared all photos from file system")
    }
    
    
    // MARK: - Utility
    
    /// Get total size of all stored photos in MB
    func getTotalPhotoStorageSize() -> Double {
        var totalSize: Int64 = 0
        
        // Profile photo
        if fileManager.fileExists(atPath: profilePhotoURL.path),
           let attrs = try? fileManager.attributesOfItem(atPath: profilePhotoURL.path),
           let size = attrs[.size] as? Int64 {
            totalSize += size
        }
        
        // User photos
        for index in 0..<10 {
            let fileURL = userPhotoURL(at: index)
            if fileManager.fileExists(atPath: fileURL.path),
               let attrs = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let size = attrs[.size] as? Int64 {
                totalSize += size
            }
        }
        
        return Double(totalSize) / (1024 * 1024)
    }
    
    /// Print storage information (useful for debugging)
    func printStorageInfo() {
        print("📊 Photo Storage Info:")
        print("   Directory: \(photosDirectory.path)")
        print("   Total size: \(String(format: "%.2f", getTotalPhotoStorageSize())) MB")
        print("   Profile photo exists: \(fileManager.fileExists(atPath: profilePhotoURL.path))")
        
        let userPhotoCount = loadUserPhotos().count
        print("   User photos count: \(userPhotoCount)/10")
    }
}
