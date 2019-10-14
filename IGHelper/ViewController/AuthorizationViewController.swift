//
//  AuthorizationViewController.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/11/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit
import WebKit

class AuthorizationViewController: UIViewController {
    
    @IBOutlet var webView: WKWebView?
    
    public var onSuccess: (()->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let link = URL(string:"https://www.instagram.com/accounts/login") else { return }
        let request = URLRequest(url: link)
        webView?.navigationDelegate = self
        webView?.load(request)
    }
    
}

extension AuthorizationViewController: WKNavigationDelegate {
    
    private func convertToApiV1JSONFormat(_ json: [String : Any]) -> [String : Any] {
        var cookie: [String: Any] = [:]
        cookie["version"] = "tough-cookie@2.4.3"
        cookie["storeType"] = "MemoryCookieStore"
        cookie["rejectPublicSuffixes"] = true
        
        var innerCookieArray: [[String: Any]] = []
        json.keys.forEach {
            var cookie: [String: Any] = [:]
            cookie["key"] = $0
//            /* addition cookie */
//            cookie["maxAge"] = 31449600
//            cookie["hostOnly"] = false
//            cookie["creation"] = "2019-10-11T20:06:52.642Z"
//            cookie["lastAccessed"] = "2019-10-11T20:06:52.642Z"
            (json[$0] as? [String: Any])?.forEach {
                if let date = $0.value as? Date {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'.000Z'"
                    cookie[$0.key.lowercaseFirstLetter()] = dateFormatter.string(from: date)
                } else {
                    cookie[$0.key.lowercaseFirstLetter()] = $0.value
                }
            }
            if let domain = cookie["domain"] as? String, domain.first == "." {
                cookie["domain"] = domain.dropFirst()
            }
            innerCookieArray.append(cookie)
        }
        cookie["cookies"] = innerCookieArray
        return cookie
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        print("!!! redirect to \(navigationAction.request.url)")
        
//         get cookies for domain
        webView.getCookies() { [weak self] (json: [String : Any]) in
              print("!!! =========================================")
//              print("!!! https://www.instagram.com")
            
            let convertedJson = self?.convertToApiV1JSONFormat(json) ?? [:]
            
            let data = try? JSONSerialization.data(withJSONObject: convertedJson)
            let base64 = data?.base64EncodedString()
            ApiManager.shared.getProfileInfo(cookieBase64: base64, onComplete: { _ in
                guard let cookies = base64 else { return }
                UserDefaults.standard.set(cookies, forKey: "cookies")
                self?.dismiss(animated: true, completion: nil)
                self?.onSuccess?()
            }) { _ in
                /* ignore error here */
            }
        }
        
//        if(navigationAction.navigationType == .other)
//        {
//            if navigationAction.request.url != nil
//            {
//                //do what you need with url
//                //self.delegate?.openURL(url: navigationAction.request.url!)
//            }
//            decisionHandler(.cancel)
//            return
//        }
        decisionHandler(.allow)
    }
    
}

extension WKWebView {

    private var httpCookieStore: WKHTTPCookieStore  { return WKWebsiteDataStore.default().httpCookieStore }

    func getCookies(for domain: String? = nil, completion: @escaping ([String : Any])->())  {
        var cookieDict = [String : AnyObject]()
        httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                if let domain = domain {
                    if cookie.domain.contains(domain) {
                        cookieDict[cookie.name] = cookie.properties as AnyObject?
                    }
                } else {
                    cookieDict[cookie.name] = cookie.properties as AnyObject?
                }
            }
            completion(cookieDict)
        }
    }
    
}
