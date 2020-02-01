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
    
    public static let shared = GuestsManager()
    private init() {}
    
    private func KEY(_ userId: String) -> String {
        return "saved_guests" + userId
    }
    
    /// Save guests for this week
    public func save(_ userId: String, _ guestsIds: [String]) {
        if !getIdsForThisDay(userId).isEmpty { return }
        
        var dictionary = UserDefaults.standard.value(forKey: KEY(userId)) as? [String: [String]] ?? [:]
        dictionary[thisDayString()] = guestsIds
        saveDictionary(userId, dictionary)
    }
    
    /// Get followers for last 3 days
    public func getIds(_ userId: String) -> [String] {
        guard var dictionary = UserDefaults.standard.value(forKey: KEY(userId)) as? [String: [String]] else {
            return []
        }
        
        // dates.sorted() result: [2019-10-16 13:38:22 +0000, 2019-10-17 13:38:22 +0000, 2019-10-18 13:38:22 +0000]
        var dates: [Date] = dictionary.keys.map { stringToDate($0) }.sorted()
        
        // Если есть две и более достаточно старых дат.
        // Нужно оставить только самую свежую а followerIds более старых удалить.
        if isOlderEnough(dates[safe: 1]) {
            while(isOlderEnough(dates[safe: 1]) && dates.count >= 2) {
                if let dateToDeleteIds = dates.first {
                    dictionary.removeValue(forKey: dateToString(dateToDeleteIds))
                    dates.removeFirst()
                }
            }
            saveDictionary(userId, dictionary)
        }
        return dictionary[dateToString(dates.first ?? Date())] ?? []
    }
    
    private func getIdsForThisDay(_ userId: String) -> [String] {
        guard let dictionary = UserDefaults.standard.value(forKey: KEY(userId)) as? [String: [String]] else { return [] }
        return dictionary[thisDayString()] ?? []
    }
    
    private func isOlderEnough(_ date: Date?) -> Bool {
        let dateToCompare = date ?? Date()
        let enoughOldDate = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        
        if dateToCompare < enoughOldDate {
            return true
        } else {
            return false
        }
    }
    
    /// Has saved guests ids
    public func containIds(_ userId: String) -> Bool {
        guard let dictionary = UserDefaults.standard.value(forKey: KEY(userId)) as? [String: [String]] else { return false }
        return !(dictionary[thisDayString()] ?? []).isEmpty
    }
    
    private func dateToString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    private func stringToDate(_ dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: dateString)
        return date ?? Date()
    }
    
    private func thisDayString() -> String {
        return dateToString(Date())
    }
    
    private func saveDictionary(_ userId: String, _ dictionary: [String: [String]]) {
        UserDefaults.standard.set(dictionary, forKey: KEY(userId))
        UserDefaults.standard.synchronize()
    }
    
}
