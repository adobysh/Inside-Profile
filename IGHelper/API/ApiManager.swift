//
//  ApiManager.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 7/23/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation
import Alamofire
//import SwiftSoup

enum ApiError: Error {
    case unknown
    case bad_password
    case invalid_user
}

class ApiManager {
    
    static let shared = ApiManager()
    
    private let baseUrl = "https://api.instagram.com/v1/"
    
    private init() {}
    
    public func getUserInfo(onComplete: @escaping ((profileInfo: ProfileInfoData, followRequests: FollowRequests, postDataArray: [PostData], followers: [ApiUser], following: [ApiUser], suggestedUsers: [GraphUser])) -> (), onError: @escaping (Error) -> ()) {
        getProfileInfo(onComplete: { [weak self] profileInfoData in
            self?.getFollowRequests(onComplete: { [weak self] followRequests in
                self?.getPosts(onComplete: { [weak self] postDataArray in
                    self?.getFollowers(onComplete: { [weak self] followers in
                        self?.getFollowing(onComplete: { [weak self] following in
                            self?.getSuggestedUser(onComplete: { suggestedUsers in
                                onComplete((profileInfoData, followRequests, postDataArray, followers, following, suggestedUsers))
                            }, onError: onError)
                        }, onError: onError)
                    }, onError: onError)
                }, onError: onError)
            }, onError: onError)
        }, onError: onError)
    }
    
    public func getProfileInfo(cookieBase64: String? = nil, id: String = "me", onComplete: @escaping (ProfileInfoData) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://i-info.n44.me/user/info/" + id
        
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
                let notNilPosts = posts.compactMap { $0 }
                onComplete(notNilPosts)
            } catch {
                onError(error)
            }
        }
    }
    
    public func getFollowing(users: [ApiUser] = [], state: String? = nil, onComplete: @escaping ([ApiUser]) -> (), onError: @escaping (Error) -> ()) {
        struct FollowingContainer: Codable {
            let feed: [ApiUser]?
            let state: String? // "{\"moreAvailable\":false,\"rankToken\":\"40a13a91-bbeb-5334-b287-265872c32210\",\"nextMaxId\":null}",
        }
        
        let url = "https://i-info.n44.me/user/following/me"

        var parameters = getParameters()
        if let state = state {
            parameters["state"] = state
        }

        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).response { [weak self] response in
            guard let data = response.data else { return }
            do {
                let decoder = JSONDecoder()
                let container = try decoder.decode(FollowingContainer.self, from: data)
                print("!!! ProfileInfoData \(container)")
                guard var following = container.feed else {
                    onError(ApiError.unknown)
                    return
                }
                following.append(contentsOf: users)
                if container.state?.asDictionary?["moreAvailable"] as? Bool == true {
                    self?.getFollowing(users: following, state: container.state, onComplete: onComplete, onError: onError)
                } else {
                    onComplete(following)
                }
            } catch {
                onError(error)
            }
        }
    }
    
    public func getFollowers(users: [ApiUser] = [], state: String? = nil, onComplete: @escaping ([ApiUser]) -> (), onError: @escaping (Error) -> ()) {
        struct FollowersContainer: Codable {
            let feed: [ApiUser]?
            let state: String? // "{\"moreAvailable\":false,\"rankToken\":\"40a13a91-bbeb-5334-b287-265872c32210\",\"nextMaxId\":null}",
        }
        
        let url = "https://i-info.n44.me/user/followers/me"

        var parameters = getParameters()
        if let state = state {
            parameters["state"] = state
        }

        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).response { [weak self] response in
            guard let data = response.data else { return }
            do {
                let decoder = JSONDecoder()
                let container = try decoder.decode(FollowersContainer.self, from: data)
                print("!!! ProfileInfoData \(container)")
                guard var followers = container.feed else {
                    onError(ApiError.unknown)
                    return
                }
                followers.append(contentsOf: users)
                if container.state?.asDictionary?["moreAvailable"] as? Bool == true {
                    self?.getFollowers(users: followers, state: container.state, onComplete: onComplete, onError: onError)
                } else {
                    let ids = followers.compactMap { $0.id }
                    PastFollowersManager.shared.save(ids)
                    onComplete(followers)
                }
            } catch {
                onError(error)
            }
        }
    }
    
    public func unfollow(id: String, onComplete: @escaping () -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/web/friendships/" + id + "/unfollow/"
        guard let headers = getHeaders(XCsrftocken: true) else { onError(ApiError.unknown); return }
        
        Alamofire.request(url, method: .post, headers: headers).response { response in
            if response.response?.statusCode == 200 {
                onComplete()
            } else {
                onError(ApiError.unknown)
            }
        }
    }
    
    public func follow(id: String, username: String, onComplete: @escaping () -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/web/friendships/" + id + "/follow/"
        guard let headers = getHeaders(XCsrftocken: true) else { onError(ApiError.unknown); return }
        
        Alamofire.request(url, method: .post, headers: headers).response { response in
            if response.response?.statusCode == 200 {
                onComplete()
            } else {
                onError(ApiError.unknown)
            }
        }
    }
    
    public func getFollowRequests(onComplete: @escaping (FollowRequests) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/accounts/access_tool/current_follow_requests"

        guard let headers = getHeaders() else { onError(ApiError.unknown); return }
        
        Alamofire.request(url, method: .get, headers: headers).responseString { [weak self] response in
            guard let result = response.value else { onError(ApiError.unknown); return }
            onComplete(FollowRequests(value: result))
//            do {
//                let html: Document = try SwiftSoup.parse(result)
//                let body = html.body()
//                var current_follow_requests_Element: Element?
//                body?.callRecursively({ element, level in
//                    if element.description.contains("current_follow_requests") {
//                        current_follow_requests_Element = element
//                    }
//                })
//                guard let followRequestsString = current_follow_requests_Element?.description else {
//                    onError(ApiError.unknown)
//                    return
//                }
//                onComplete(FollowRequests(value: followRequestsString))
//            } catch {
//                onError(error)
//            }
        }
    }
    
    public func getUserInfoArray_graph(userInfoArray: [BaseUser] = [], ids: [String], onComplete: @escaping ([BaseUser]) -> (), onError: @escaping (Error) -> ()) {
        // Если сделать запрос с пустым списком айдишек то вернёт инфу о себе.
        if ids.isEmpty {
            onComplete([])
            return
        }
        
        let url = "https://www.instagram.com/graphql/query/"
        
        guard let headers = getHeaders() else { return }
        
        let parameters: [String: String] = [
            "query_hash": "aec5501414615eca36a9acf075655b1e",
            "variables": "{\"user_id\":\"\(ids.first ?? "")\",\"include_chaining\":false,\"include_reel\":true,\"include_suggested_users\":false,\"include_logged_out_extras\":false,\"include_highlight_reels\":false}"
        ]
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).responseJSON { [weak self] response in
            let json = response.value as? [String: Any]
            let data = json?["data"] as? [String: Any]
            let user = data?["user"] as? [String: Any]
            let reel = user?["reel"] as? [String: Any]

            // owner и user одинаковые.
            // Можно попробовать взять инфу у одного, если не получится у другого.
            let userDictionary: [String: Any]
            if let owner = reel?["owner"] as? [String: Any],
                let _ = owner["id"],
                let _ = owner["profile_pic_url"],
                let _ = owner["username"] {
                userDictionary = owner
            } else if let owner = reel?["user"] as? [String: Any],
                let _ = owner["id"],
                let _ = owner["profile_pic_url"],
                let _ = owner["username"] {
                userDictionary = owner
            } else {
                userDictionary = [:]
                onError(ApiError.unknown)
                return
            }
            
            let baseUser = BaseUser(
                id: userDictionary["id"] as? String,
                full_name: nil,
                username: userDictionary["username"] as? String,
                profile_pic_url: userDictionary["profile_pic_url"] as? String,
                is_verified: nil,
                followers: nil)
            
            var users = userInfoArray
            users.append(baseUser)
            if ids.count == 1 || ids.isEmpty {
                onComplete(users)
            } else {
                var idsWithoutFirst = ids
                idsWithoutFirst.removeFirst()
                self?.getUserInfoArray_graph(userInfoArray: users, ids: idsWithoutFirst, onComplete: onComplete, onError: onError)
            }
        }
    }
    
    public func getSuggestedUser(suggestedUsers: [GraphUser] = [], onComplete: @escaping ([GraphUser]) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/graphql/query/"
        
        guard let headers = getHeaders() else { return }

        //        "seen_ids":["263874345","1247439238",
        let seen_ids_array = suggestedUsers.map { "\($0.id ?? "")" }
        let seen_ids = seen_ids_array.joined(separator:",")
        
        let parameters: [String: String] = [
            "query_hash": "bd90987150a65578bc0dd5d4e60f113d",
            "variables": "{\"fetch_media_count\":0,\"fetch_suggested_count\":30,\"ignore_cache\":false,\"filter_followed_friends\":true,\"seen_ids\":[\(seen_ids)],\"include_reel\":true}"
        ]
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).response { [weak self] response in
            guard let data = response.data else { return }
            do {
                let decoder = JSONDecoder()
                let container = try decoder.decode(SuggestedUsersWebContainer.self, from: data)
                print("!!! ProfileInfoData \(container)")
                guard let status = container.status, status == "ok" else {
                    onError(ApiError.unknown)
                    return
                }
                var users: [GraphUser] = container.data?.user?.edge_suggested_users?.edges?.compactMap { $0.node?.user } ?? []
                users.append(contentsOf: suggestedUsers)
                if container.data?.user?.edge_suggested_users?.page_info?.has_next_page == true {
                    self?.getSuggestedUser(suggestedUsers: users, onComplete: onComplete, onError: onError)
                } else {
                    onComplete(users)
                }
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
        print("!!! cookiesBase64 \(cookies)")
        return parameters
    }
    
    private func getHeaders(XCsrftocken: Bool = false) -> HTTPHeaders? {
        guard let cookiesBase64 = AuthorizationManager.shared.cookies else { return nil }
        guard let cookiesJsonData = Data(base64Encoded: cookiesBase64) else { return nil }
        guard let cookiesDictionary = (try? JSONSerialization.jsonObject(with: cookiesJsonData, options: [])) as? [String: Any] else { return nil }
        guard let cookeisArray = cookiesDictionary["cookies"] as? [[String: Any]] else { return nil }
        
        var cookieString = ""
        cookeisArray.forEach {
            cookieString = cookieString + (($0["key"] as? String) ?? "") + "="
            cookieString = cookieString + (($0["value"] as? String) ?? "") + "; "
        }
        
        print("!!! cookeisArray \(cookeisArray)")
        print("!!! cookieString \(cookieString)")
        
        var headers: HTTPHeaders = [
            "Cookie": cookieString
        ]
        if XCsrftocken {
            headers["x-csrftoken"] = ((cookeisArray.first(where: { ($0["key"] as? String) == "csrftoken" }))?["value"] as? String) ?? ""
        }
        print("!!! headers \(headers)")
        return headers
    }
    
}

//extension Element {
//    
//    func callRecursively(level: Int = 0, _ body: (_ subview: Element, _ level: Int) -> Void) {
//        body(self, level)
//        for i in 0..<self.children().count {
//            let children = self.children().get(i)
//            children.callRecursively(level: level + 1, body)
//        }
//        
//    }
//
//}
