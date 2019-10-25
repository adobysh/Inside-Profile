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
    
    private let KEY = "past_followers"
    
    public static let shared = PastFollowersManager()
    private init() {}
    
    /// Save followers for this day or add additions for this day if they come later.
    public func save(_ followersIds: [String]) {
        var todaysSavedId: [String] = getIdsForThisDay()
        todaysSavedId.append(contentsOf: followersIds)
        todaysSavedId = Array(Set(todaysSavedId))
        var dictionary = UserDefaults.standard.value(forKey: KEY) as? [String: [String]] ?? [:]
        dictionary[thisDayString()] = todaysSavedId
        saveDictionary(dictionary)
    }
    
    /// Get followers id older then month or if not found get just the oldest followers id.
    /// If there if 2 of more dates older then month ago keed only the newest and delete another.
    public func getIds() -> [String] {
        guard var dictionary = UserDefaults.standard.value(forKey: KEY) as? [String: [String]] else {
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
            saveDictionary(dictionary)
        }
        return dictionary[dateToString(dates.first ?? Date())] ?? []
    }
    
    private func isOlderEnough(_ date: Date?) -> Bool {
        let dateToCompare = date ?? Date()
        let enoughOldDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        print("!!! dateToCompare \(dateToCompare)")
        print("!!! enoughOldDate \(enoughOldDate)")
        if dateToCompare < enoughOldDate {
            print("!!! dateToCompare < enoughOldDate")
            return true
        } else {
            print("!!! dateToCompare >= enoughOldDate")
            return false
        }
    }
    
    private func getIdsForThisDay() -> [String] {
        guard let dictionary = UserDefaults.standard.value(forKey: KEY) as? [String: [String]] else { return [] }
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
    
    private func saveDictionary(_ dictionary: [String: [String]]) {
        print("!!! save followers \(dictionary)")
        UserDefaults.standard.set(dictionary, forKey: KEY)
        UserDefaults.standard.synchronize()
    }
    
}
