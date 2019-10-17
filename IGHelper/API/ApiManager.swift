//
//  ApiManager.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 7/23/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation
import Alamofire

enum ApiError: Error {
    case unknown
    case bad_password
    case invalid_user
}

class ApiManager {
    
    static let shared = ApiManager()
    
    private let baseUrl = "https://api.instagram.com/v1/"
    
    private init() {}
    
    public func getUserInfo(onComplete: @escaping ((profileInfo: ProfileInfoData, postDataArray: [PostData])) -> (), onError: @escaping (Error) -> ()) {
        getProfileInfo(onComplete: { [weak self] profileInfoData in
            self?.getPosts(onComplete: { postDataArray in
                onComplete((profileInfoData, postDataArray))
            }, onError: { error in
                onError(error)
            })
        }) { error in
            onError(error)
        }
    }
    
    public func getProfileInfo(cookieBase64: String? = nil, onComplete: @escaping (ProfileInfoData) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://i-info.n44.me/user/info/me"
        
        let parameters: [String: String]
        if let cookieBase64 = cookieBase64 {
            parameters = [
                "cookies" : cookieBase64
            ]
        } else {
            parameters = getParameters()
        }
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).response { response in
            guard let data = response.data else { return }
            do {
                let decoder = JSONDecoder()
                let container = try decoder.decode(ProfileInfoData.self, from: data)
                print("!!! ProfileInfoData \(container)")
                guard let _ = container.username, let _ = container.follower_count else {
                    onError(ApiError.unknown)
                    return
                }
                onComplete(container)
            } catch {
                onError(error)
            }
        }
    }
    
    public func getPosts(onComplete: @escaping ([PostData]) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://i-info.n44.me/user/posts/me"
        
        let parameters: [String: String] = getParameters()
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).response { response in
            guard let data = response.data else { return }
            do {
                let decoder = JSONDecoder()
                let container = try decoder.decode(PostsContainerData.self, from: data)
                print("!!! ProfileInfoData \(container)")
                guard let posts = container.feed else {
                    onError(ApiError.unknown)
                    return
                }
                let notNilposts = posts.compactMap { $0 }
                onComplete(notNilposts)
            } catch {
                onError(error)
            }
        }
    }
    
    public func getSuggestedUser(suggestedUser: [SuggestedUser] = [], onComplete: @escaping ([SuggestedUser]) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/graphql/query/"
        
        guard let cookiesBase64 = AuthorizationManager.shared.cookies else { return }
        guard let cookiesJsonData = Data(base64Encoded: cookiesBase64) else { return }
        guard let cookiesDictionary = (try? JSONSerialization.jsonObject(with: cookiesJsonData, options: [])) as? [String: Any] else { return }
        guard let cookeisArray = cookiesDictionary["cookies"] as? [[String: Any]] else { return }
        
        var cookieString = ""
        cookeisArray.forEach {
            cookieString = cookieString + (($0["key"] as? String) ?? "") + "="
            cookieString = cookieString + (($0["value"] as? String) ?? "") + "; "
        }
        
        print("!!! cookeisArray \(cookeisArray)")
        print("!!! cookieString \(cookieString)")
        
        let headers: HTTPHeaders = [
            "Cookie": cookieString
        ]

        //        "seen_ids":["263874345","1247439238",
        let seen_ids_array = suggestedUser.map { "\($0.id ?? "")" }
        let seen_ids = seen_ids_array.joined(separator:",")
        
        let parameters: [String: String] = [
            "query_hash": "bd90987150a65578bc0dd5d4e60f113d",
            "variables": "{\"fetch_media_count\":0,\"fetch_suggested_count\":30,\"ignore_cache\":false,\"filter_followed_friends\":true,\"seen_ids\":[\(seen_ids)],\"include_reel\":true}"
        ]
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).response { [weak self] response in
            print("!!! response \(response)")
            guard let data = response.data else { return }
            print("!!! data \(data)")
            do {
                let decoder = JSONDecoder()
                let container = try decoder.decode(SuggestedUsersWebContainer.self, from: data)
                print("!!! ProfileInfoData \(container)")
                guard let status = container.status, status == "ok" else {
                    onError(ApiError.unknown)
                    return
                }
                let users: [SuggestedUser] = container.data?.user?.edge_suggested_users?.edges.compactMap { $0.node?.user } ?? []
                onComplete(users)
            } catch {
                onError(error)
            }
        }
    }
    
    private func getParameters() -> [String: String] {
        guard let cookies = AuthorizationManager.shared.cookies else { return [:] }
        let parameters: [String: String] = [
            "cookies" : cookies
        ]
        return parameters
    }
    
}
