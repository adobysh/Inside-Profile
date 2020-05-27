//
//  ProfileStateBundleManager.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 5/26/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import Foundation

class ProfileStateBundleManager {
    
    private static let Key = "ProfileStateBundleSaveTime"
    
    public func load() -> ProfileStateBundle? {
        let currentTime = Date().timeIntervalSince1970
        let savedTime = loadLastSaveTimeSeconds()
        
        if (currentTime - savedTime) < 600 {
            return ProfileStateBundleModel().load()
        } else {
            return nil
        }
    }
        
    public func save(_ profileStateBundle: ProfileStateBundle) {
        saveLastSaveTimeSeconds(Date().timeIntervalSince1970)
        ProfileStateBundleModel().save(profileStateBundle)
    }
    
    private func loadLastSaveTimeSeconds() -> Double {
        UserDefaults.standard.double(forKey: ProfileStateBundleManager.Key)
    }
    
    private func saveLastSaveTimeSeconds(_ seconds: Double) {
        UserDefaults.standard.set(seconds, forKey: ProfileStateBundleManager.Key)
    }
    
}

fileprivate class ProfileStateBundleModel {

    private static let FileName = "ProfileStateBundleData"
    
    private static var FileURL: URL? {
        let documentDirectory: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentDirectory?.appendingPathComponent(ProfileStateBundleModel.FileName)
    }

    public func load() -> ProfileStateBundle? {
        guard let fileURL = ProfileStateBundleModel.FileURL,
            let data = try? Data(contentsOf: fileURL),
            let history = try? JSONDecoder().decode(ProfileStateBundle.self, from: data) else {
                return nil
        }
        return history
    }

    public func save(_ profileStateBundle: ProfileStateBundle) {
        guard let data = try? JSONEncoder().encode(profileStateBundle),
            let fileURL = ProfileStateBundleModel.FileURL else {
                return
        }
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(atPath: fileURL.path)
        }
        try? data.write(to: fileURL)
    }

}
