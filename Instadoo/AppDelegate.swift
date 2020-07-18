//
//  AppDelegate.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 7/8/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import SwiftyStoreKit

import FBSDKCoreKit
//import AppsFlyerLib
import Amplitude_iOS
import AdSupport
import SwiftKeychainWrapper

fileprivate let LIMITED_ANALYTICS_F_AND_F_SUM = 10000 // при какой сумме подписок и подписчиков включается ограниченный режим
let LIMITED_ANALYTICS_F_OR_F_COUNT_REQUARED_LOAD = 200 // сумма подписок и подписчиков загружаемая в ограниченном режиме
let LIMITED_ANALYTICS_LIKERS_PER_POST_COUNT = 495
let LIMITED_ANALYTICS_POSTS_WITH_LIKERS_COUNT = 25
let LIMITED_ANALYTICS_TOTAL_POSTS_COUNT = 95
let LIMITED_ANALYTICS_TOTAL_BLOCKED = 195

func isLimitedMode(_ followersCount: Int, _ followingCount: Int) -> Bool {
    let isLimitedMode = followersCount + followingCount >= LIMITED_ANALYTICS_F_AND_F_SUM
    
    #if DEBUG
    if UserDefaults.standard.bool(forKey: "limited_mode") {
        return true
    } else {
        return isLimitedMode
    }
    #else
    return isLimitedMode
    #endif
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initializeSDKs(launchOptions: launchOptions)
        AppAnalytics.logAppOpen()
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                // Unlock content
                case .failed, .purchasing, .deferred:
                    break // do nothing
                }
            }
        }
        return true
    }
    
    private func initializeSDKs(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
//        AppsFlyerTracker.shared().appsFlyerDevKey = "put key here"
//        AppsFlyerTracker.shared().appleAppID = "put id here"
//        AppsFlyerTracker.shared().delegate = self
        Fabric.with([Crashlytics.self])
        AppEvents.activateApp()
        Amplitude.instance().initializeApiKey(AppAnalytics.amplitudeApiKey)
        ApplicationDelegate.initializeSDK(launchOptions)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        AppEvents.activateApp()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

