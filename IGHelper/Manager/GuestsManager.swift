//
//  GuestsManager.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/28/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

//{
//  "2019 43": { "123214124", "123124124124" },
//  "2019 45": { "123214124", "123124124124" }
//}
//
//{
//  year and weekOfYear (String): { userId(String), userId(String) },
//  year and weekOfYear (String): { userId(String), userId(String) }
//}

class GuestsManager {
    
    private let KEY = "saved_guests"
    
    public static let shared = GuestsManager()
    private init() {}
    
    /// Save guests for this week
    public func save(_ guestsIds: [String]) {
        var dictionary = UserDefaults.standard.value(forKey: KEY) as? [String: [String]] ?? [:]
        dictionary[thisDayString()] = guestsIds
        saveDictionary(dictionary)
    }
    
    /// Get followers for this week
    public func getIds() -> [String] {
        guard let dictionary = UserDefaults.standard.value(forKey: KEY) as? [String: [String]] else { return [] }
        return dictionary[thisDayString()] ?? []
    }
    
    /// Has saved guests ids
    public func containIds() -> Bool {
        guard let dictionary = UserDefaults.standard.value(forKey: KEY) as? [String: [String]] else { return false }
        return !(dictionary[thisDayString()] ?? []).isEmpty
    }
    
    private func dateToString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy w"
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    private func stringToDate(_ dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy w"
        let date = dateFormatter.date(from: dateString)
        return date ?? Date()
    }
    
    private func thisDayString() -> String {
        return dateToString(Date())
    }
    
    private func saveDictionary(_ dictionary: [String: [String]]) {
        print("!!! save guests \(dictionary)")
        UserDefaults.standard.set(dictionary, forKey: KEY)
        UserDefaults.standard.synchronize()
    }
    
}
