//
//  GraphAPIRoutes.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 1/23/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import Foundation
import Alamofire
import Alamofire_Synchronous
import SwiftSoup

enum GraphApiError: Error {
    case headersIsNil
    case responseDataIsNil
    case decodeFailed
}

class GraphAPIRoutes {
    
    public static func getPostLikers(shortcode: String) -> (likers: [GraphLiker]?, error: Error?) {
        let url = "https://www.instagram.com/graphql/query/"

        let parameters: [String: String] = [
            "query_hash": "d5d763b1e2acf209d62d22d184488e57",
            "variables": "{\"shortcode\":\"\(shortcode)\",\"include_reel\":true,\"first\":50}"
        ]
        
        guard let headers = getHeaders() else { return (likers: nil, error: GraphApiError.headersIsNil) }
        
        let response = Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).response()
            
        guard let data = response.data else { return (likers: nil, error: GraphApiError.responseDataIsNil) }
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(GraphLikersContainer.self, from: data)
            guard let likers = result.likers else { return (likers: nil, error: GraphApiError.decodeFailed) }
            return (likers: likers, error: nil)
        } catch {
            return (likers: nil, error: error)
        }
    }
        
    public static func getPosts(id: String, onComplete: @escaping ([GraphPost]) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/graphql/query/"

        let parameters: [String: String] = [
            "query_hash": "f045d723b6f7f8cc299d62b57abd500a",
            "variables": "{\"id\":\"\(id)\",\"first\":50,\"after\":\"QVFETlNoTVhXd1NrUXF3TzQzczZBSGhmc0pESmVtZWhPbklzM2paNDJlZVJ6NWlpR2hXUi1ISUNkMlI1YV9aTzQ5VDNvRF9GQjI3aWhnUlFlNEx5QTBzZw==\"}"
        ]
        
        guard let headers = getHeaders() else { onError(ApiError.unknown); return }
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).response { response in
            
            guard let data = response.data else { onError(ApiError.unknown); return }
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(GraphPostsContainer.self, from: data)
                guard let posts = result.posts else {
                    onError(ApiError.unknown)
                    return
                }
                
                var postsWithLikers: [GraphPost] = []
                
                DispatchQueue.global().async {
                    for post in posts {
                        let likersResult = getPostLikers(shortcode: post.shortcode ?? "")
                        if let likers = likersResult.likers {
                            var postWithLikers = post
                            postWithLikers.likers = likers
                            
                            postsWithLikers.append(postWithLikers)
                        }
                    }
                    DispatchQueue.main.async {
                        onComplete(postsWithLikers)
                    }
                }
            } catch {
                onError(error)
            }
        }
    }
    
    public static func getProfileInfo(cookieBase64: String? = nil, userName: String, onComplete: @escaping (GraphProfile) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/" + userName + "/"
        
        guard let headers = getHeaders() else { onError(ApiError.unknown); return }
        
        Alamofire.request(url, method: .get, headers: headers).responseString { response in
            guard let htmlPage = response.value else {
                onError(ApiError.nilValue)
                return
            }
            
            guard let document: Document = try? SwiftSoup.parse(htmlPage) else {
                onError(ApiError.parsing(message: "Document"))
                return
            }
            
            guard let scripts: Elements? = (try? document.body()?.getElementsByTag("script")) else {
                onError(ApiError.parsing(message: "Elements"))
                return
            }
            
            guard let scriptTextArray: [String] = (scripts?.array().map { (try? $0.html()) ?? "" }) else {
                onError(ApiError.parsing(message: "scriptTextArray"))
                return
            }
            
            let marker = "window._sharedData = "
            guard let firstNeededScriptText: String = (scriptTextArray.first { $0.starts(with: marker) }) else {
                onError(ApiError.parsing(message: "firstNeededScriptText"))
                return
            }
            
            var scriptTextWithoutPrefix: String = firstNeededScriptText.replacingOccurrences(of: marker, with: "")
            
            scriptTextWithoutPrefix.removeLast()
            
            guard let dictionary = scriptTextWithoutPrefix.asDictionary else {
                onError(ApiError.parsing(message: "dictionary"))
                return
            }
            
            guard let entryData = dictionary["entry_data"] as? [String: Any] else {
                onError(ApiError.parsing(message: "entryData"))
                return
            }
            
            guard let profilePage = entryData["ProfilePage"] as? [[String: Any]] else {
                onError(ApiError.parsing(message: "profilePage"))
                return
            }
            
            guard let graphql = profilePage.first?["graphql"] as? [String: Any] else {
                onError(ApiError.parsing(message: "graphql"))
                return
            }
            
            guard let user = graphql["user"] as? [String: Any] else {
                onError(ApiError.parsing(message: "user"))
                return
            }
            
            guard let edge_followed_by = user["edge_followed_by"] as? [String: Any] else {
                onError(ApiError.parsing(message: "edge_followed_by"))
                return
            }
            
            guard let edge_follow = user["edge_follow"] as? [String: Any] else {
                onError(ApiError.parsing(message: "edge_follow"))
                return
            }
            
            guard let userId = user["id"] as? String else {
                onError(ApiError.parsing(message: "userId"))
                return
            }
            
            let profileInfo = GraphProfile(
                profile_pic_url:    user["profile_pic_url"] as? String,
                follower_count:     edge_followed_by["count"] as? Int,
                following_count:    edge_follow["count"] as? Int,
                username:           user["username"] as? String,
                full_name:          user["full_name"] as? String,
                profile_pic_url_hd: user["profile_pic_url_hd"] as? String,
                id:                 userId)
            
            onComplete(profileInfo)
        }
    }

    public static func getUserDirectSearch(onComplete: @escaping ([ApiUser]) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/direct_v2/web/ranked_recipients/?mode=raven&query=&show_threads=false"

        guard var headers = getHeaders() else { onError(ApiError.unknown); return }
        headers["User-Agent"] = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1"
        
        Alamofire.request(url, method: .get, headers: headers).responseJSON { response in
            
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
    
    public static func follow(id: String, username: String, onComplete: @escaping () -> (), onError: @escaping (Error) -> ()) {
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
    
    public static func unfollow(id: String, onComplete: @escaping () -> (), onError: @escaping (Error) -> ()) {
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
    
    public static func getSuggestedUser(suggestedUsers: [GraphUser] = [], onComplete: @escaping ([GraphUser]) -> (), onError: @escaping (Error) -> ()) {
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
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).response { response in
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
                    getSuggestedUser(suggestedUsers: users, onComplete: onComplete, onError: onError)
                } else {
                    onComplete(users)
                }
            } catch {
                onError(error)
            }
        }
    }
    
    public static func getFollowRequests(onComplete: @escaping (FollowRequests) -> (), onError: @escaping (Error) -> ()) {
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
    
    public static func getUserInfo_graph(cookieBase64: String? = nil, id: String = "", onComplete: @escaping (BaseUser) -> (), onError: @escaping (Error) -> ()) {
        // Если сделать запрос с пустым списком айдишек то вернёт инфу о себе.
        
        let url = "https://www.instagram.com/graphql/query/"
        
        guard let headers = getHeaders(cookieBase64: cookieBase64) else { return }
        
        let parameters: [String: String] = [
            "query_hash": "aec5501414615eca36a9acf075655b1e",
            "variables": "{\"user_id\":\"\(id)\",\"include_chaining\":false,\"include_reel\":true,\"include_suggested_users\":false,\"include_logged_out_extras\":false,\"include_highlight_reels\":false}"
        ]
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).responseJSON { response in
            guard let json = response.value as? [String: Any] else {
                onError(ApiError.nilValue)
                return
            }
            let data = json["data"] as? [String: Any]
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
                onComplete(BaseUser.disabled(id))
                return
            }
            
            let baseUser = BaseUser(
                id: userDictionary["id"] as? String,
                full_name: nil,
                username: userDictionary["username"] as? String,
                profile_pic_url: userDictionary["profile_pic_url"] as? String,
                is_verified: nil,
                followers: nil)
            
            onComplete(baseUser)
        }
    }
    
    public static func getHistory(onComplete: @escaping ([HistoryData]) -> (), onError: @escaping (Error) -> ()) {
        
        let url = "https://www.instagram.com/accounts/activity/?__a=1&include_reel=true"
        
        guard let headers = getHeaders() else { return }
        
        Alamofire.request(url, method: .get, encoding: URLEncoding(destination: .queryString), headers: headers).responseJSON { response in
            guard let json = response.value as? [String: Any] else { onError(ApiError.nilValue); return }
            let graphql = json["graphql"] as? [String: Any]
            let user = graphql?["user"] as? [String: Any]
            let activity_feed = user?["activity_feed"] as? [String: Any]
            let edge_web_activity_feed = activity_feed?["edge_web_activity_feed"] as? [String: Any]
            let edges = edge_web_activity_feed?["edges"] as? [[String: Any]]
            
            let historyFollowArray = edges?.filter { edge in
                let node = edge["node"] as? [String: Any]
                return (node?["__typename"] as? String) == "GraphFollowAggregatedStory"
            }
            let historyArray: [HistoryData]? = historyFollowArray?.map { edge in
                let node = edge["node"] as? [String: Any]
                let user = node?["user"] as? [String: Any]
                let baseUser = HistoryUser(
                    id: user?["id"] as? String,
                    full_name: user?["full_name"] as? String,
                    username: user?["username"] as? String,
                    profile_pic_url: user?["profile_pic_url"] as? String,
                    is_verified: nil,
                    followers: nil,
                    descriptionText: nil,
                    followStatus: nil,
                    yourPostsLikes: nil,
                    connectionsCount: nil,
                    followed_by_viewer: user?["followed_by_viewer"] as? Bool)
                return HistoryData(timestamp: node?["timestamp"] as? Double, user: baseUser)
            }
            onComplete(historyArray ?? [])
        }
    }
    
}

// MARK: - Utils
extension GraphAPIRoutes {
    
    public static func getHeaders(XCsrftocken: Bool = false, cookieBase64: String? = nil) -> HTTPHeaders? {
        guard let cookiesBase64 = cookieBase64 ?? AuthorizationManager.shared.cookies else { return nil }
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
