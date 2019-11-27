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
    
//    func webViewDidFinishLoadUsername() {
//        webView?.evaluateJavaScript("document.getElementByTagName(\"input\")[2].value = \(viewControllerManager.username)") {(result, error) in
//
//            if error != nil
//            {
//                print(result!)
//            }
//            else
//            {
//                print(error!)
//            }
//        }
//    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()", completionHandler: { [weak self] (html: Any?, error: Error?) in
            
            print("!!! redirect html \(html)")
            print("!!! redirect ===================")
            
//            if "\(html)".contains("andromeda.group.review@gmail.com") && "\(html)".contains("review123123REVIEW") {
//
//                let cookies = "eyJzdG9yZVR5cGUiOiJNZW1vcnlDb29raWVTdG9yZSIsInJlamVjdFB1YmxpY1N1ZmZpeGVzIjp0cnVlLCJjb29raWVzIjpbeyJodHRwT25seSI6IlRSVUUiLCJzZWN1cmUiOiJUUlVFIiwiZG9tYWluIjoiaW5zdGFncmFtLmNvbSIsInBhdGgiOiJcLyIsImNyZWF0ZWQiOjU5NjE5OTI1Niwia2V5IjoiaWdfZGlkIiwidmVyc2lvbiI6IjEiLCJ2YWx1ZSI6Ijc4QzE3NjM3LTVGNzEtNDIxRC1BQ0FFLUNGNjUzOEMwNzM3MSIsImV4cGlyZXMiOiIyMDI5LTExLTIwVDEzOjU0OjE2LjAwMFoifSx7InZhbHVlIjoiMTU3NDUwNjQ3Ny42MjIzNTQiLCJleHBpcmVzIjoiMjAxOS0xMS0zMFQxMzo1NDozNy4wMDBaIiwia2V5Ijoic2hidHMiLCJwYXRoIjoiXC8iLCJodHRwT25seSI6IlRSVUUiLCJzZWN1cmUiOiJUUlVFIiwidmVyc2lvbiI6IjEiLCJjcmVhdGVkIjo1OTYxOTkyNzcsImRvbWFpbiI6Imluc3RhZ3JhbS5jb20ifSx7ImNyZWF0ZWQiOjU5NjE5OTI3Nywia2V5Ijoic2Vzc2lvbmlkIiwic2VjdXJlIjoiVFJVRSIsInBhdGgiOiJcLyIsImh0dHBPbmx5IjoiVFJVRSIsImRvbWFpbiI6Imluc3RhZ3JhbS5jb20iLCJleHBpcmVzIjoiMjAyMC0xMS0yMlQxMzo1NDozNy4wMDBaIiwidmFsdWUiOiIxOTQ3NjE5MjE1JTNBd3F3aVJ4dTNMeEhlZFklM0ExNiIsInZlcnNpb24iOiIxIn0seyJzZWN1cmUiOiJUUlVFIiwiZGlzY2FyZCI6IlRSVUUiLCJrZXkiOiJydXIiLCJjcmVhdGVkIjo1OTYxOTkyNzcsImh0dHBPbmx5IjoiVFJVRSIsInBhdGgiOiJcLyIsInZlcnNpb24iOiIxIiwidmFsdWUiOiJWTEwiLCJkb21haW4iOiJpbnN0YWdyYW0uY29tIn0seyJ2YWx1ZSI6IjE5NDc2MTkyMTUiLCJleHBpcmVzIjoiMjAyMC0wMi0yMVQxMzo1NDozNy4wMDBaIiwicGF0aCI6IlwvIiwiY3JlYXRlZCI6NTk2MTk5Mjc3LCJzZWN1cmUiOiJUUlVFIiwia2V5IjoiZHNfdXNlcl9pZCIsInZlcnNpb24iOiIxIiwiZG9tYWluIjoiaW5zdGFncmFtLmNvbSJ9LHsidmVyc2lvbiI6IjEiLCJzZWN1cmUiOiJUUlVFIiwiY3JlYXRlZCI6NTk2MTk5Mjc3LCJleHBpcmVzIjoiMjAyMC0xMS0yMVQxMzo1NDozNy4wMDBaIiwidmFsdWUiOiIzajlFZXlLbHlsWHN4TjdlTmhSUW9ob1Ewa3FUcklYayIsImtleSI6ImNzcmZ0b2tlbiIsInBhdGgiOiJcLyIsImRvbWFpbiI6Imluc3RhZ3JhbS5jb20ifSx7ImV4cGlyZXMiOiIyMDE5LTExLTMwVDEzOjU0OjM3LjAwMFoiLCJrZXkiOiJzaGJpZCIsInNlY3VyZSI6IlRSVUUiLCJodHRwT25seSI6IlRSVUUiLCJwYXRoIjoiXC8iLCJjcmVhdGVkIjo1OTYxOTkyNzcsImRvbWFpbiI6Imluc3RhZ3JhbS5jb20iLCJ2ZXJzaW9uIjoiMSIsInZhbHVlIjoiMTY2NjMifSx7ImNyZWF0ZWQiOjU5NjE5OTI1NywidmFsdWUiOiJYZGtQMkFBQUFBRVVwdlpmVEhRNmI4NlRoVUp6IiwiZXhwaXJlcyI6IjIwMjktMTEtMjBUMTM6NTQ6MTcuMDAwWiIsInBhdGgiOiJcLyIsInNlY3VyZSI6IlRSVUUiLCJrZXkiOiJtaWQiLCJkb21haW4iOiJpbnN0YWdyYW0uY29tIiwidmVyc2lvbiI6IjEifV0sInZlcnNpb24iOiJ0b3VnaC1jb29raWVAMi40LjMifQ=="
//                UserDefaults.standard.set(cookies, forKey: "cookies")
//                self?.dismiss(animated: true, completion: nil)
//                self?.onSuccess?()
//
//                decisionHandler(.cancel)
//            } else {
                if navigationAction.request.url?.host?.contains("instagram.com") == true {
                    webView.getCookies() { [weak self] (json: [String : Any]) in
                        let convertedJson = self?.convertToApiV1JSONFormat(json) ?? [:]
                        print("!!! convertedJson \(convertedJson)")
                        
                        let data = try? JSONSerialization.data(withJSONObject: convertedJson)
                        let base64 = data?.base64EncodedString()
                        print("!!! base64 \(base64)")
                        
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
                        
//                        ApiManager.shared.getProfileInfo(cookieBase64: base64, onComplete: { _ in
//                            guard let cookies = base64 else { return }
//                            UserDefaults.standard.set(cookies, forKey: "cookies")
//                            self?.dismiss(animated: true, completion: nil)
//                            self?.onSuccess?()
//                        }) { _ in
//                            /* ignore error here */
//                        }
                    }
                }
                decisionHandler(.allow)
//            }
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
