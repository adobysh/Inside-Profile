//
//  AuthorizationManager.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 7/22/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit
import Alamofire

class AuthorizationManager: NSObject {
    
    static let shared = AuthorizationManager()
    private override init() {}
    
    let baseUrl = "https://i-info.n44.me/login/"
    
    var isLoggedIn: Bool {
        return UserDefaults.standard.string(forKey: "cookies") != nil
    }
    var cookies: String? {
        return UserDefaults.standard.string(forKey: "cookies")
    }
    var session: String? {
        return UserDefaults.standard.string(forKey: "session")
    }
    
    func login(loginOrEmail: String, password: String, onSuccess: @escaping (AuthorizationData)->(), onError: @escaping (Error)->()) {
        
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
    
    private func authorization(_ viewController: UIViewController) {
//        let clientId = "ad813357a78e49bf810e179999ea65ea"
////        let clientId = "fd647b267a0e444cbad03e4b96e7c43c"
//        let redirectUri = "https://andromeda-group.jimdosite.com/"
//
//        let isClientSide = true
//        let responseType = isClientSide ? "token" : "code"
//
//        let link = "https://api.instagram.com/oauth/authorize/?client_id=\(clientId)&redirect_uri=\(redirectUri)&response_type=\(responseType)"
//
//        guard let url = URL(string: link) else { return }
//
//        let svc = SFSafariViewController(url: url)
//        svc.delegate = self
//        viewController.present(svc, animated: true, completion: nil)
    }
    
}
