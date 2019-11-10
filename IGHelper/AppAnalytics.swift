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

class AppAnalytics {
    
    enum Event: String {
        case first_open
        case first_dashboard_open
        case first_vip_open
        case first_vip_button_click
//        case first_offer_open
//        case first_offer_btn_click
        
        case open
        case dashboard_open
        case vip_open
        case vip_button_click
        case restore_button_click
        
        case lost_followers_click
        case gained_followers_click
        case unfollowers_click
        case you_dont_follow_click
        case new_guests_click
        case recomendation_click
        case top_lickers_click
        case top_commenters_click
        
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
        
        case lost_followers_loading_click
        case gained_followers_loading_click
        case unfollowers_loading_click
        case you_dont_follow_loading_click
        case new_guests_loading_click
        case recomendation_loading_click
        case top_lickers_loading_click
        case top_commenters_loading_click
        
//        case onboarding_start
//        case onboarding_complete
        
//        case onboarding_slides_1_open
//        case onboarding_slides_2_open
//        case onboarding_slides_3_open
//        case onboarding_slides_4_open
        
//        case pre_vip_open
//        case send_code
//        case enter_valid_code
//        case error_code
//        case offer_btn_click
//        case requested_review
//        case purchased_with_issue
//        case purchase_analytics
//        case click_banner
//        case fetched_fb_deeplink
    }
    
    enum Property: String {
        case source = "source"
    }
    
    enum Key: String {
        case appOpen
        case dashboardOpen
        case vipOpen
    }
    
    class func log(_ event: Event, properties: [String: Any]? = nil) {
        Amplitude.instance().logEvent(event.rawValue, withEventProperties: properties ?? [:])
//        Analytics.logEvent(event.rawValue, parameters: properties)
    }
    
    class func log(_ event: Event, property: Property, value: Any) {
        log(event, properties: [property.rawValue: value])
    }
    
    class func logAppOpen(properties: [String: Any]? = nil) {
        if UserDefaults.standard.bool(forKey: Key.appOpen.rawValue) == false {
            UserDefaults.standard.set(true, forKey: Key.appOpen.rawValue)
            UserDefaults.standard.synchronize()
            log(.first_open, properties: properties)
        }
        log(.open, properties: properties)
    }
    
    class func logDashboardOpen(properties: [String: Any]? = nil) {
        if UserDefaults.standard.bool(forKey: Key.dashboardOpen.rawValue) == false {
            UserDefaults.standard.set(true, forKey: Key.dashboardOpen.rawValue)
            UserDefaults.standard.synchronize()
            log(.first_dashboard_open, properties: properties)
        }
        log(.dashboard_open, properties: properties)
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
    
    class func set(property: Property, value: NSObject) {
        Amplitude.instance()?.identify(AMPIdentify().set(property.rawValue, value: value))
    }
    
    class func increment(property: Property) {
        Amplitude.instance()?.identify(AMPIdentify().add(property.rawValue, value: NSNumber(value: 1)))
    }
    
    class func logPurchase(price: NSDecimalNumber?, currency: String?, identifier: String?) {
        let priceValue = price ?? 0
        let currencyValue = currency ?? "undefined"
        let identifierValue = identifier ?? "unknown"
        Answers.logPurchase(withPrice: priceValue, currency: currencyValue, success: true, itemName: nil, itemType: "purchse", itemId: identifierValue, customAttributes: nil)
//        AppsFlyerTracker.shared().trackEvent(AFEventPurchase, withValues: [
//            AFEventParamContentId:"0",
//            AFEventParamContentType : "Subscription",
//            AFEventParamRevenue: priceValue,
//            AFEventParamCurrency: currencyValue
//            ])
        Amplitude.instance().logRevenue(identifierValue, quantity: 1, price: priceValue)
//        YMMYandexMetrica.reportEvent("Purchase", parameters: ["price": priceValue, "currency": currencyValue, "identifier": identifierValue]) { _ in }
//        YMMYandexMetrica.reportRevenue(YMMRevenueInfo(price: priceValue.doubleValue, currency: currencyValue)) { _ in }
//        Analytics.logEvent("purchase_client", parameters: [AnalyticsParameterPrice: priceValue, AnalyticsParameterCurrency: currencyValue, AnalyticsParameterItemID: identifierValue])
//        if AUTH_MANAGER.settings.fbAnalytics.contains(.manual) {
            AppEvents.logPurchase(priceValue.doubleValue, currency: currencyValue)
//        }
//        if AUTH_MANAGER.settings.fbAnalytics.contains(.registerReceipt) {
//            let group = DispatchGroup()
//            group.enter()
//            SERVER_MANAGER.sendFBData { _ in group.leave() }
//            group.enter()
//            SERVER_MANAGER.sendAppsflyerData { _ in group.leave() }
//            group.notify(queue: .main) {
//                SERVER_MANAGER.registerReceipt(price: price, currency: currency) { _, _ in }
//            }
//        }
//        if AUTH_MANAGER.settings.fbAnalytics.contains(.addToCart) {
            AppAnalytics.logAddedToCartEvent(contentId: identifierValue, contentType: "product", currency: currencyValue, price: priceValue.doubleValue)
//        }
//        if AUTH_MANAGER.settings.fbAnalytics.contains(.addToWishlist) {
//            AppAnalytics.logAddedToWishlistEvent(contentId: identifierValue, contentType: "product", currency: currencyValue, price: priceValue.doubleValue)
//        }
    }
    
    class func getFBParameters() -> [String: Any?] {
        let event = "PURCHASE"
        let advertiserID = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        let advertiserTrackingEnabled = ASIdentifierManager.shared().isAdvertisingTrackingEnabled
        let applicationTrackingEnabled = true
        let bundleID = Bundle.main.bundleIdentifier
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
        let bundleShortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let attributes = try? FileManager().attributesOfFileSystem(forPath: NSHomeDirectory())
        let extinfo: [Any?] = [
            "i2",
            bundleID,
            bundleVersion,
            bundleShortVersion,
            UIDevice.current.systemVersion,
            UIDevice.current.modelName,
            Locale.current.identifier,
            NSTimeZone.system.abbreviation(),
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
    
//    class func getAppsflyerParameters() -> [String: Any?] {
//        return [
//            "appsflyer_id": AppsFlyerTracker.shared()?.getAppsFlyerUID(),
//            "af_events_api": 1,
//            "idfa": ASIdentifierManager.shared().advertisingIdentifier.uuidString,
//            "advertiser_id": AppsFlyerTracker.shared()?.advertiserId,
//            "bundle_id": Bundle.main.bundleIdentifier
//        ]
//    }
    
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
