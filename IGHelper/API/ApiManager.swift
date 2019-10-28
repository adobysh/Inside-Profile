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
    
    public func getUserInfo(onComplete: @escaping ((followRequests: FollowRequests, followers: [ApiUser], following: [ApiUser], suggestedUsers: [GraphUser], userDirectSearch: [ApiUser])) -> (), onError: @escaping (Error) -> ()) {
        
        getFollowRequests(onComplete: { [weak self] followRequests in
            self?.getFollowers(onComplete: { [weak self] followers in
                self?.getFollowings(onComplete: { [weak self] following in
                    self?.getGoodSuggestedUser(onComplete: { [weak self] suggestedUsers in
                        self?.getUserDirectSearch(onComplete: { userDirectSearch in
                            onComplete((followRequests, followers, following, suggestedUsers, userDirectSearch))
                        }, onError: onError)
                    }, onError: onError)
                }, onError: onError)
            }, onError: onError)
        }, onError: onError)
    }
    
    public func getProfileInfoAndPosts(onComplete: @escaping ((profileInfo: ProfileInfoData, postDataArray: [PostData])) -> (), onError: @escaping (Error) -> ()) {
        
        getProfileInfo(onComplete: { [weak self] profileInfo in
            self?.getPosts(onComplete: { postDataArray in
                onComplete((profileInfo, postDataArray))
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
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).response { [weak self] response in
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
    
    public func getTopLikersFriends(topLikers: [ApiUser], onComplete: @escaping ([ApiUser]) -> (), onError: @escaping (Error) -> ()) {
        guard !topLikers.isEmpty else {
            onComplete([])
            return
        }
        
        print("!!! topLikers ids \(topLikers.map { $0.id })")
        
        var totalTopLikersFriends: [ApiUser] = [] // following and follower in one person
        
        getFollowings(userId: topLikers.first?.id, onComplete: { [weak self] followings in
            print("!!! topLiker 1 followings count \(followings.count)")
            
            self?.getFollowers(userId: topLikers.first?.id, onComplete: { [weak self] followers in
                print("!!! topLiker 1 followers count \(followers.count)")
                let topLiker1Friends = UserModel.friends(followings, followers)
                print("!!! topLiker 1 friends count \(topLiker1Friends.count)")
                totalTopLikersFriends.append(contentsOf: topLiker1Friends)
                
                if topLikers.count <= 1 {
                    onComplete(totalTopLikersFriends)
                } else {
                    self?.getFollowings(userId: topLikers[safe: 1]?.id, onComplete: { [weak self] followings in
                        print("!!! topLiker 2 followings count \(followings.count)")
                        
                        self?.getFollowers(userId: topLikers[safe: 1]?.id, onComplete: { followers in
                            print("!!! topLiker 2 followers count \(followers.count)")
                            let topLiker2Friends = UserModel.friends(followings, followers)
                            print("!!! topLiker 2 friends count \(topLiker2Friends.count)")
                            totalTopLikersFriends.append(contentsOf: topLiker2Friends)
                            
                            onComplete(totalTopLikersFriends)
                        }, onError: onError)
                    }, onError: onError)
                }
            }, onError: onError)
        }, onError: onError)
    }
    
    public func getFollowers(users: [ApiUser] = [], state: String? = nil, userId: String? = nil, onComplete: @escaping ([ApiUser]) -> (), onError: @escaping (Error) -> ()) {
        struct FollowersContainer: Codable {
            let feed: [ApiUser]?
            let state: String? // "{\"moreAvailable\":false,\"rankToken\":\"40a13a91-bbeb-5334-b287-265872c32210\",\"nextMaxId\":null}",
        }
        
        let url = "https://i-info.n44.me/user/followers/" + (userId ?? "me")

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
                    self?.getFollowers(users: followers, state: container.state, userId: userId, onComplete: onComplete, onError: onError)
                } else {
                    let ids = followers.compactMap { $0.id }
                    
                    // это значит что фоловеры мои
                    if userId == nil {
                        PastFollowersManager.shared.save(ids)
                    }
                    onComplete(followers)
                }
            } catch {
                onError(error)
            }
        }
    }
    
    public func getFollowings(users: [ApiUser] = [], state: String? = nil, userId: String? = nil, onComplete: @escaping ([ApiUser]) -> (), onError: @escaping (Error) -> ()) {
        struct FollowingContainer: Codable {
            let feed: [ApiUser]?
            let state: String? // "{\"moreAvailable\":false,\"rankToken\":\"40a13a91-bbeb-5334-b287-265872c32210\",\"nextMaxId\":null}",
        }
        
        let url = "https://i-info.n44.me/user/following/" + (userId ?? "me")

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
                    self?.getFollowings(users: following, state: container.state, userId: userId, onComplete: onComplete, onError: onError)
                } else {
                    onComplete(following)
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
    
    public func getUserDirectSearch(onComplete: @escaping ([ApiUser]) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/direct_v2/web/ranked_recipients/?mode=raven&query=&show_threads=false"

        guard var headers = getHeaders() else { onError(ApiError.unknown); return }
        headers["User-Agent"] = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1"
        
        Alamofire.request(url, method: .get, headers: headers).responseJSON { response in
//                guard let result = response.value else { onError(ApiError.unknown); return }
            let json = response.value as? [String: Any]
            let ranked_recipients = json?["ranked_recipients"] as? [[String: Any]?]
            let threadArray = ranked_recipients?.compactMap { $0?["thread"] as? [String: Any] }
            let users = threadArray?.compactMap { $0["users"] as? [[String: Any]?] }.flatMap { $0 }.compactMap { $0 }
            let apiUsers = users?.map { user in
                return ApiUser(
                    pk: user["pk"] as? Int,
                    full_name: user["full_name"] as? String,
                    username:  user["username"] as? String,
                    profile_pic_url: user["profile_pic_url"] as? String,
                    is_verified: user["is_verified"] as? Bool,
                    followers: nil,
                    followStatus: nil)
            } ?? []
            onComplete(apiUsers)
        }
    }
    
    public func getFollowRequests(onComplete: @escaping (FollowRequests) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/accounts/access_tool/current_follow_requests"

        guard let headers = getHeaders() else { onError(ApiError.unknown); return }
        
        Alamofire.request(url, method: .get, headers: headers).responseString { response in
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
    
    public func getGoodSuggestedUser(onComplete: @escaping ([GraphUser]) -> (), onError: @escaping (Error) -> ()) {
        func isGood(_ user: GraphUser) -> Bool {
            guard let description = user.descriptionText else { return true }
            if description.lowercased() == "suggested for you" {
                return true
            } else if description.lowercased().contains("followed by") && description.lowercased().contains("more") {
                return true
            } else {
                return false
            }
        }
        
        getSuggestedUser(onComplete: { suggestedUsers in
            let notBadSuggestedUsers = suggestedUsers.filter { $0.is_verified == false }
            
            var goodSuggestedUsers = notBadSuggestedUsers.filter { isGood($0) }
            if goodSuggestedUsers.isEmpty {
                goodSuggestedUsers = notBadSuggestedUsers
            }
            
            goodSuggestedUsers = goodSuggestedUsers.map { user in
                var user2 = user
                user2.descriptionText = user2.descriptionText?.replacingOccurrences(of: "by\\s.+\\s\\+", with: "", options: [.regularExpression])
                return user2
            }
            
            goodSuggestedUsers.sort { ($0.descriptionText ?? "") > ($1.descriptionText ?? "") }
            onComplete(goodSuggestedUsers)
        }, onError: onError)
    }
    
    private func getSuggestedUser(suggestedUsers: [GraphUser] = [], onComplete: @escaping ([GraphUser]) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/graphql/query/"
        
        guard var headers = getHeaders() else { return }
        headers["Accept-Language"] = "en"

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
                var users: [GraphUser] = container.data?.user?.edge_suggested_users?.edges?.compactMap { edge in
                    var user = edge.node?.user
                        
                    if user?.id == "7265304034" || user?.id == "7289403847" {
                        return nil
                    } else {
                        user?.descriptionText = edge.node?.description
                        return user
                    }
                } ?? []
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
