//
//  AuthorizationManager.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 7/22/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit
import Alamofire
import WebKit

class AuthorizationManager: NSObject {
    
    public static let shared = AuthorizationManager()
    private override init() {}
    
    private let baseUrl = "https://i-info.n44.me/login/"
    
    public var isLoggedIn: Bool {
        return UserDefaults.standard.string(forKey: "cookies") != nil
    }
    public var cookies: String? {
        print("!!! cookiesBase64 \(UserDefaults.standard.string(forKey: "cookies") ?? "")")
        return UserDefaults.standard.string(forKey: "cookies")
    }
    
    public func logOut() {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records) { /* onComplete */ }
            
//          dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records.filter { $0.displayName.contains("facebook") },
//            completionHandler: {
//
//            }
//          )
        }
        UserDefaults.standard.removeObject(forKey: "cookies")
    }
    
}
