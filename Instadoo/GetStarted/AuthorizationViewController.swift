//
//  AuthorizationViewController.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/11/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit
import WebKit
import SafariServices

class AuthorizationViewController: UIViewController {
    
    @IBOutlet var webView: WKWebView?
    @IBOutlet var customNavigationBar: UINavigationBar?
    
    public var onSuccess: (()->())?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.scale()
        
        customNavigationBar?.setBackgroundImage(UIImage(), for: .default)
        customNavigationBar?.shadowImage = UIImage()
        
        guard let link = URL(string:"https://www.instagram.com/accounts/login") else { return }
        let request = URLRequest(url: link)
        webView?.navigationDelegate = self
        webView?.load(request)
    }
    
    @IBAction func doneAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func helpAction(_ sender: Any) {
        showAlert(title: "Help", message: "If you can't sign-in, please, confirm your sign-in in the official Instagram app.\nOr you can check Support Page to find solution.", actions: [
            UIAlertAction(title: "Open Instagram", style: .default, handler: { [weak self] _ in
                self?.openInstagram()
            }),
            UIAlertAction(title: "Open Support Page", style: .default, handler: { [weak self] _ in
                guard let url = URL(string: "https://help.instagram.com/") else { return }
                let svc = SFSafariViewController(url: url)
                self?.present(svc, animated: true)
            }),
            UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        ])
    }
    
    func openInstagram() {
        let instagramHooks = "instagram://"
        if let instagramUrl = URL(string: instagramHooks), UIApplication.shared.canOpenURL(instagramUrl) {
            UIApplication.shared.open(instagramUrl)
        } else {
            if let url = URL(string: "itms-apps://itunes.apple.com/app/id389801252"),
                UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { (opened) in
                    if opened {
                        print("App Store Opened")
                    }
                }
            } else {
                print("Can't Open URL on Simulator")
                guard let url = URL(string: "https://instagram.com/") else { return }
                let svc = SFSafariViewController(url: url)
                present(svc, animated: true)
            }
        }
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
                if $0.key.lowercased() != "name" {
                    if let date = $0.value as? Date {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'.000Z'"
                        cookie[$0.key.lowercaseFirstLetter()] = dateFormatter.string(from: date)
                    } else {
                        cookie[$0.key.lowercaseFirstLetter()] = $0.value
                    }
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
        
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()", completionHandler: { [weak self] (html: Any?, error: Error?) in
            
            if navigationAction.request.url?.host?.contains("instagram.com") == true {
                webView.getCookies() { [weak self] (json: [String : Any]) in
                    let convertedJson = self?.convertToApiV1JSONFormat(json) ?? [:]
                    
                    let data = try? JSONSerialization.data(withJSONObject: convertedJson)
                    let base64 = data?.base64EncodedString()
                    
                    AuthorizationManager.shared.isAuthorized(cookieBase64: base64 ?? "") { [weak self] (error, isAuthorized) in
                        if let _ = error {
                            /* ignore error here */
                        } else if isAuthorized == true {
                            guard let cookies = base64 else { return }
                            UserDefaults.standard.set(cookies, forKey: "cookies")
                            self?.dismiss(animated: true, completion: nil)
                            self?.onSuccess?()
                        }
                    }
                }
            }
            decisionHandler(.allow)
        })
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
