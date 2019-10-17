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
    
    public func login(loginOrEmail: String, password: String, onSuccess: @escaping (AuthorizationData)->(), onError: @escaping (Error)->()) {
        
        let fullUrl = baseUrl + loginOrEmail + "/" + password
        
        Alamofire.request(fullUrl).response { response in
            guard let data = response.data else { return }
            do {
                let decoder = JSONDecoder()
                let authorizationData = try decoder.decode(AuthorizationData.self, from: data)
                guard authorizationData.ok == 1 else {
                    if authorizationData.error == "bad_password" {
                        onError(ApiError.bad_password)
                    } else if authorizationData.error == "invalid_user" {
                        onError(ApiError.invalid_user)
                    } else {
                        onError(ApiError.unknown)
                    }
                    return
                }
                onSuccess(authorizationData)
                guard let cookies = authorizationData.cookies else { return }
                UserDefaults.standard.set(cookies, forKey: "cookies")
            } catch {
                onError(error)
            }
        }
    }
    
}
