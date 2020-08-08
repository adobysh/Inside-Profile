//
//  PastFollowersManager.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/18/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

//{
//  "2019.10.17": { "123214124", "123124124124" },
//  "2019.10.18": { "123214124", "123124124124" }
//}
//
//{
//  day(String): { userId(String), userId(String) },
//  day(String): { userId(String), userId(String) }
//}

class PastFollowersManager {
    
    public static let shared = PastFollowersManager()
    private init() {}
    
    private func KEY(_ userId: String) -> String {
        return "past_followers" + userId
    }
    
    /// Save followers for this day or add additions for this day if they come later.
    public func save(_ userId: String, _ followersIds: [String]) {
        if !getIdsForThisDay(userId).isEmpty { return }
        
        var dictionary = UserDefaults.standard.value(forKey: KEY(userId)) as? [String: [String]] ?? [:]
        dictionary[thisDayString()] = followersIds
        saveDictionary(userId, dictionary)
    }
    
    /// Get followers id older then month or if not found get just the oldest followers id.
    /// If there if 2 of more dates older then month ago keed only the newest and delete another.
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
    
    private func isOlderEnough(_ date: Date?) -> Bool {
        let dateToCompare = date ?? Date()
        let enoughOldDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        if dateToCompare < enoughOldDate {
            return true
        } else {
            return false
        }
    }
    
    private func getIdsForThisDay(_ userId: String) -> [String] {
        guard let dictionary = UserDefaults.standard.value(forKey: KEY(userId)) as? [String: [String]] else { return [] }
        return dictionary[thisDayString()] ?? []
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
