//
//  SubscriptionsKeychain.swift
//  ReadOrDie
//
//  Created by Andrei Dobysh on 6/3/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

class SubscriptionKeychain {
    
    private init() { }
    
    private static let existsKey = "month-subscription-exists"
    private static let dateKey = "month-subscription-date"
    private static let subscribed = "1"
    private static let notSubscribed = "0"
    
    static func isSubscribed() -> Bool {
        return true
        
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "complete_purchase") {
            return true
        } else {
            return isExists() && !isExpired()
        }
        #else
        return isExists() && !isExpired()
        #endif
    }
    
    private static func isExists() -> Bool {
        return UserDefaults.standard.bool(forKey: existsKey)
    }
    
    private static func isExpired() -> Bool {
        let expirationTimestamp = UserDefaults.standard.integer(forKey: dateKey)
        let expirationDate = Date(timeIntervalSince1970: TimeInterval(expirationTimestamp))
        let isExpired = SubscriptionKeychain.isExpired(expirationDate, to: .second)
        if isExpired && isExists() {
            SubscriptionManager.verify()
            return false
        }
        return isExpired
    }
    
    private static func isExpired(_ date: Date, to granularity: Calendar.Component) -> Bool {
        return Calendar.current.compare(Date(), to: date, toGranularity: granularity) == .orderedDescending
    }
    
    static func unsubscribe() {
        UserDefaults.standard.set(false, forKey: existsKey)
        UserDefaults.standard.set(0, forKey: dateKey)
    }
    
    static func registerSubscription(expirationDate: Date) {
        UserDefaults.standard.set(true, forKey: existsKey)
        UserDefaults.standard.set(expirationDate.timeIntervalSince1970, forKey: dateKey)
    }
}
