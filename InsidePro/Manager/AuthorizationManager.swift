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
    
    public var hasCookies: Bool {
        return UserDefaults.standard.string(forKey: "cookies") != nil
    }
    public var cookies: String? {
        return UserDefaults.standard.string(forKey: "cookies")
    }
    
    public func isAuthorized(cookieBase64: String? = nil, completion: @escaping (Completion<Bool>) -> Void) {
        guard let cookies = cookieBase64 ?? self.cookies else {
            completion(.success(false)) /* there is no any cookies */
            return
        }
        GraphRoutes.getUserInfo_graph(cookieBase64: cookies, completion: { baseUser in
            switch baseUser {
            case .success(let baseUser):
                if let baseUserId = baseUser.id, !baseUserId.isEmpty {
                    completion(.success(true))
                } else {
                    completion(.success(false))
                }
                break
            case .error(let errorModel):
                completion(.error(errorModel))
            }
        })
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
