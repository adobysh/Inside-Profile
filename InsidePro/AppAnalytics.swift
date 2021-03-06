//
//  AppAnalytics.swift
//  Second Phone
//
//  Created by Valik Kuchinsky on 5/24/18.
//  Copyright © 2018 Nesus UAB. All rights reserved.
//

import Foundation
import Crashlytics
import FBSDKCoreKit
import AppsFlyerLib
import Amplitude_iOS
import AdSupport
import SwiftKeychainWrapper
import UIKit
import CoreTelephony

enum Event: String {
    
    case start_app
    
    case event_open
    case event_click
    
    case purchase_analytics
    
    // дополнительные ивенты
    case settings_click
    
    case setting_get_premium_click
    case setting_restore_click
    case setting_terms_click
    case setting_privacy_click
    case setting_logout_click
    
    case main_reload
    case user_list_reload
    
    case user_click
    
    case user_follow
    case user_unfollow
}

enum EventButton: String {
    // dashboard
    case lost_followers
    case gained_followers
    case unfollowers
    case you_dont_follow
    case new_guests
    case recommendation
    case top_likers
    case top_commenters
    case blocked_by_you
    
    // vip
    case vip
    case restore
}

enum EventScreen: String {
    case dashboard
    case vip
}

enum EventSource: String {
    // dashboard
    case lost_followers
    case gained_followers
    case unfollowers
    case you_dont_follow
    case new_guests
    case recommendation
    case top_likers
    case top_commenters
    case blocked_by_you
    
    case settings
    
    case unknown
}

enum Property: String {
    // dashboard
    case followers
    case following
    case likes
    case comments
    
    case lost_followers
    case gained_followers
    case unfollowers
    case you_dont_follow
    case new_guests
    case recommendation
    case top_likers
    case top_commenters
}

class AppAnalytics {
    
    enum Key: String {
        case appOpen
        case dashboardOpen
        case vipOpen
    }
    
    static let amplitudeApiKey = "91d98733bedcadcda5e92ba5091cc370"
    
    public class func log(_ event: Event, properties: [String: Any]? = nil) {
        Amplitude.instance().logEvent(event.rawValue, withEventProperties: properties ?? [:])
//        Analytics.logEvent(event.rawValue, parameters: properties)
    }
    
    private class func log(_ event: Event, button: EventButton? = nil, screen: EventScreen? = nil, source: EventSource? = nil, properties: [String: Any]? = nil) {
        var properties = properties ?? [:]
        if let button = button {
            properties["button"] = button.rawValue
        }
        if let source = source {
            properties["source"] = source.rawValue
        }
        if let screen = screen {
            properties["screen"] = screen.rawValue
        }
        log(event, properties: properties)
    }
    
    public class func logClick(button: EventButton, source: EventSource? = nil, isDisabled: Bool = false) {
        let properties: [String: Any]? = isDisabled ? [ "is_disabled": "yes" ] : nil
        log(.event_click, button: button, source: source, properties: properties)
    }
    
    public class func logOpen(screen: EventScreen, source: EventSource? = nil) {
        log(.event_open, screen: screen, source: source)
    }
    
    public class func logAppOpen() {
        var properties: [String: Any] = [:]
        if UserDefaults.standard.bool(forKey: Key.appOpen.rawValue) == false {
            UserDefaults.standard.set(true, forKey: Key.appOpen.rawValue)
            UserDefaults.standard.synchronize()
            properties["is_first"] = "yes"
        }
        log(.start_app, properties: properties)
    }
    
    public class func logDashboardOpen() {
        var properties: [String: Any] = [:]
        properties["screen"] = EventScreen.dashboard.rawValue
        if UserDefaults.standard.bool(forKey: Key.dashboardOpen.rawValue) == false {
            UserDefaults.standard.set(true, forKey: Key.dashboardOpen.rawValue)
            UserDefaults.standard.synchronize()
            properties["is_first"] = "yes"
        }
        log(.event_open, properties: properties)
    }
    
    class func setUserID(_ userId: String) {
        Amplitude.instance()?.setUserId(userId)
    }
    
    class func setDeviceID() {
        Amplitude.instance()?.setDeviceId(getDeviceUUID())
    }
    
    class func setOnce(property: Property, value: NSObject) {
        Amplitude.instance()?.identify(AMPIdentify().setOnce(property.rawValue, value: value))
    }
    
    private class func set(property: Property, value: NSObject) {
        Amplitude.instance()?.identify(AMPIdentify().set(property.rawValue, value: value))
    }
    
    class func increment(property: Property) {
        Amplitude.instance()?.identify(AMPIdentify().add(property.rawValue, value: NSNumber(value: 1)))
    }
    
    class func logPurchase(price: NSDecimalNumber?, currency: String?, identifier: String?, place: String) {
        let priceValue = price ?? 0
        let currencyValue = currency ?? "undefined"
        let identifierValue = identifier ?? "unknown"
        
        ApiService.shared.registerReceipt(price: price, currency: currency, place: place) { _, _ in }
        
        #if DEBUG

        #else
        Answers.logPurchase(withPrice: priceValue,
                            currency: currencyValue,
                            success: true,
                            itemName: nil,
                            itemType: "purchse",
                            itemId: identifierValue,
                            customAttributes: nil)
        
        Amplitude.instance().logRevenue(identifierValue,
                                        quantity: 1,
                                        price: priceValue)
        
        AppsFlyerTracker.shared().trackEvent(AFEventAddToCart, withValues: [
            AFEventParamContentId: "0",
            AFEventParamContentType : "Subscription",
            AFEventParamRevenue: priceValue,
            AFEventParamCurrency: currencyValue
        ])
        
        let parameters = [
            AppEvents.ParameterName.content.rawValue: priceValue,
            AppEvents.ParameterName.contentID.rawValue: "0",
            AppEvents.ParameterName.contentType.rawValue: "Subscription",
            AppEvents.ParameterName.currency.rawValue: currencyValue
            ] as [String : Any]

        
        AppEvents.logEvent(.addedToCart, valueToSum: priceValue.doubleValue,
                           parameters: parameters)

        
        AppAnalytics.logAddedToCartEvent(contentId: identifierValue,
                                         contentType: "product",
                                         currency: currencyValue,
                                         price: priceValue.doubleValue)
        #endif
    }
    
//    class func logPurchase(price: NSDecimalNumber?, currency: String?, identifier: String?) {
//        let priceValue = price ?? 0
//        let currencyValue = currency ?? "undefined"
//        let identifierValue = identifier ?? "unknown"
//        Answers.logPurchase(withPrice: priceValue, currency: currencyValue, success: true, itemName: nil, itemType: "purchse", itemId: identifierValue, customAttributes: nil)
////        AppsFlyerTracker.shared().trackEvent(AFEventPurchase, withValues: [
////            AFEventParamContentId:"0",
////            AFEventParamContentType : "Subscription",
////            AFEventParamRevenue: priceValue,
////            AFEventParamCurrency: currencyValue
////            ])
//        Amplitude.instance().logRevenue(identifierValue, quantity: 1, price: priceValue)
////        YMMYandexMetrica.reportEvent("Purchase", parameters: ["price": priceValue, "currency": currencyValue, "identifier": identifierValue]) { _ in }
////        YMMYandexMetrica.reportRevenue(YMMRevenueInfo(price: priceValue.doubleValue, currency: currencyValue)) { _ in }
////        Analytics.logEvent("purchase_client", parameters: [AnalyticsParameterPrice: priceValue, AnalyticsParameterCurrency: currencyValue, AnalyticsParameterItemID: identifierValue])
////        if AUTH_MANAGER.settings.fbAnalytics.contains(.manual) {
//            AppEvents.logPurchase(priceValue.doubleValue, currency: currencyValue)
////        }
////        if AUTH_MANAGER.settings.fbAnalytics.contains(.registerReceipt) {
////            let group = DispatchGroup()
////            group.enter()
////            SERVER_MANAGER.sendFBData { _ in group.leave() }
////            group.enter()
////            SERVER_MANAGER.sendAppsflyerData { _ in group.leave() }
////            group.notify(queue: .main) {
////                SERVER_MANAGER.registerReceipt(price: price, currency: currency) { _, _ in }
////            }
////        }
////        if AUTH_MANAGER.settings.fbAnalytics.contains(.addToCart) {
//            AppAnalytics.logAddedToCartEvent(contentId: identifierValue, contentType: "product", currency: currencyValue, price: priceValue.doubleValue)
////        }
////        if AUTH_MANAGER.settings.fbAnalytics.contains(.addToWishlist) {
////            AppAnalytics.logAddedToWishlistEvent(contentId: identifierValue, contentType: "product", currency: currencyValue, price: priceValue.doubleValue)
////        }
//    }
    
    class func getFBParameters() -> [String: Any?] {
        let event = "PURCHASE"
        let advertiserID = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        let advertiserTrackingEnabled = ASIdentifierManager.shared().isAdvertisingTrackingEnabled
        let applicationTrackingEnabled = true
        let bundleID = Bundle.main.bundleIdentifier
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
        let bundleShortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let attributes = try? FileManager().attributesOfFileSystem(forPath: NSHomeDirectory())
        let carriers = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.map { ($0.value.carrierName ?? "") }.joined(separator:", ")
        let extinfo: [Any?] = [
            "i2",
            bundleID,
            bundleVersion,
            bundleShortVersion,
            UIDevice.current.systemVersion,
            UIDevice.current.modelName,
            Locale.current.identifier,
            NSTimeZone.system.abbreviation(),
            carriers,
            UIScreen.main.bounds.width,
            UIScreen.main.bounds.height,
            String(format: "%.02f", UIScreen.main.scale),
            ProcessInfo.processInfo.processorCount,
            attributes?[.systemSize],
            attributes?[.systemFreeSize],
            TimeZone.current.description
        ]
        return [
            "event": event,
            "advertiser_id": advertiserID,
            "advertiser_tracking_enabled": NSNumber(value: advertiserTrackingEnabled),
            "application_tracking_enabled": NSNumber(value: applicationTrackingEnabled),
            "bundle_id": bundleID,
            "bundle_version": bundleVersion,
            "bundle_short_version": bundleShortVersion,
            "extinfo": extinfo
        ]
    }
    
    class func getAppsflyerParameters() -> [String: Any?] {
        return [
            "appsflyer_id": AppsFlyerTracker.shared()?.getAppsFlyerUID(),
            "af_events_api": 1,
            "idfa": ASIdentifierManager.shared().advertisingIdentifier.uuidString,
            "advertiser_id": AppsFlyerTracker.shared()?.advertiserId,
            "bundle_id": Bundle.main.bundleIdentifier
        ]
    }
    
    class func setUserId(_ id: String) {
        Amplitude.instance()?.setUserId(id)
    }
    
    class func logAddedToCartEvent(contentId: String, contentType: String, currency: String, price: Double) {
        let parameters: [String: Any] = [
            AppEvents.ParameterName.contentID.rawValue: contentId,
            AppEvents.ParameterName.contentType.rawValue: contentType,
            AppEvents.ParameterName.currency.rawValue: currency
        ]
        AppEvents.logEvent(.addedToCart, valueToSum: price, parameters: parameters)
    }
    
    class func logAddedToWishlistEvent(contentId: String, contentType: String, currency: String, price: Double) {
        let parameters: [String: Any] = [
            AppEvents.ParameterName.contentID.rawValue: contentId,
            AppEvents.ParameterName.contentType.rawValue: contentType,
            AppEvents.ParameterName.currency.rawValue: currency
        ]
        AppEvents.logEvent(.addedToWishlist, valueToSum: price, parameters: parameters)
    }
    
    private class func getDeviceUUID() -> String? {
        if let uuid = KeychainWrapper.standard.string(forKey: "uuid_key") {
            return uuid
        } else {
            if let uuid = UIDevice.current.identifierForVendor?.uuidString {
                KeychainWrapper.standard.set(uuid, forKey: "uuid_key")
                return uuid
            }
            return nil
        }
    }
    
}

// MARK: Private methods
extension AppAnalytics {
    
    public class func setValues(
        followers: Int,
        following: Int,
        likes: Int,
        comments: Int,
        lostFollowers: Int,
        gainedFollowers: Int,
        youDontFollow: Int,
        unfollowers: Int,
        profileViewers: Int,
        recomendation: Int,
        topLikers: Int,
        topCommenters: Int
    ) {
        set(property: .followers, value: followers as NSObject)
        set(property: .following, value: following as NSObject)
        set(property: .likes, value: likes as NSObject)
        set(property: .comments, value: comments as NSObject)
        set(property: .lost_followers, value: lostFollowers as NSObject)
        set(property: .gained_followers, value: gainedFollowers as NSObject)
        set(property: .you_dont_follow, value: youDontFollow as NSObject)
        set(property: .unfollowers, value: unfollowers as NSObject)
        set(property: .new_guests, value: profileViewers as NSObject)
        set(property: .recommendation, value: recomendation as NSObject)
        set(property: .top_likers, value: topLikers as NSObject)
        set(property: .top_commenters, value: topCommenters as NSObject)
    }
}

extension UIDevice {

    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

}
