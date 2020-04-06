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

enum GraphError: Error {
    case headersIsNil
    case responseDataIsNil
    case decodeFailed
    case unknown
    case bad_password
    case invalid_user
    case nilValue
    case parsing(message: String)
}

class GraphRoutes {
    
    public static func getBlockedUsersUsernames(userName: String, onComplete: @escaping ([String]) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/accounts/access_tool/accounts_you_blocked"
        
        guard let headers = getHeaders() else { onError(GraphError.unknown); return }
        
        Alamofire.request(url, method: .get, headers: headers).responseString { response in
            
            guard let htmlPage = response.value else {
                onError(GraphError.nilValue)
                return
            }
            
            guard let document: Document = try? SwiftSoup.parse(htmlPage) else {
                onError(GraphError.parsing(message: "Document"))
                return
            }
            
            guard let scripts: Elements? = (try? document.body()?.getElementsByTag("script")) else {
                onError(GraphError.parsing(message: "Elements"))
                return
            }
            
            guard let scriptTextArray: [String] = (scripts?.array().map { (try? $0.html()) ?? "" }) else {
                onError(GraphError.parsing(message: "scriptTextArray"))
                return
            }
            
            let marker = "window._sharedData = "
            guard let firstNeededScriptText: String = (scriptTextArray.first { $0.starts(with: marker) }) else {
                onError(GraphError.parsing(message: "firstNeededScriptText"))
                return
            }

            var scriptTextWithoutPrefix: String = firstNeededScriptText.replacingOccurrences(of: marker, with: "")

            scriptTextWithoutPrefix.removeLast()

            guard let dictionary = scriptTextWithoutPrefix.asDictionary else {
                onError(GraphError.parsing(message: "dictionary"))
                return
            }

            guard let entryData = dictionary["entry_data"] as? [String: Any] else {
                onError(GraphError.parsing(message: "entryData"))
                return
            }

            guard let settingsPages = entryData["SettingsPages"] as? [[String: Any]] else {
                onError(GraphError.parsing(message: "SettingsPages"))
                return
            }

            guard let settingsPages_data = settingsPages.first?["data"] as? [String: Any] else {
                onError(GraphError.parsing(message: "settingsPages_data"))
                return
            }
            
            guard let settingsPages_data_data = settingsPages_data["data"] as? [[String: Any]] else {
                onError(GraphError.parsing(message: "settingsPages_data_data"))
                return
            }
            
            let blockedUsernames = settingsPages_data_data.compactMap { $0["text"] as? String }
            
            onComplete(blockedUsernames)
        }
    }
    
    public static func getUserFollowings(previous: (end_cursor: String, users: [GraphUser])? = nil, limited: Bool, id: String, onSubpartLoaded: @escaping (Int)->Void, onComplete: @escaping ([GraphUser]) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/graphql/query/"
        
        let after = previous == nil ? "" : ",\"after\":\"\(previous?.end_cursor ?? "")\""

        let parameters: [String: String] = [
            "query_hash": "d04b0a864b4b54837c0d870b0e77e076",
            "variables": "{\"id\":\"\(id)\",\"include_reel\":false,\"fetch_mutual\":false,\"first\":50\(after)}"
        ]
        
        guard let headers = getHeaders() else { onError(GraphError.headersIsNil); return }
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).response { response in
            
            guard let data = response.data else { onError(GraphError.responseDataIsNil); return }
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(GraphFollowingsContainer.self, from: data)
                guard var followings = result.followings else {
                    onError(GraphError.unknown)
                    return
                }
            
                if let previous = previous {
                    onSubpartLoaded(previous.users.count)
                    followings.append(contentsOf: previous.users)
                }

                if limited && followings.count > LIMITED_ANALYTICS_F_OR_F_COUNT_REQUARED_LOAD {
                    onComplete(followings)
                } else if result.has_next_page == true, let end_cursor = result.end_cursor {
                    getUserFollowings(previous: (end_cursor: end_cursor, users: followings), limited: limited, id: id, onSubpartLoaded: onSubpartLoaded, onComplete: onComplete, onError: onError)
                } else {
                    onComplete(followings)
                }
            } catch {
                onError(error)
            }
        }
    }
    
    public static func getAllFollowers(limited: Bool, id: String, onSubpartLoaded: @escaping (Int) -> Void, onComplete: @escaping ([GraphUser]) -> (), onError: @escaping (Error) -> ()) {
        getUserFollowers(limited: limited, id: id, onSubpartLoaded: onSubpartLoaded, onComplete: { allFollowers in
            let ids = allFollowers.compactMap { $0.id }
            PastFollowersManager.shared.save(id, ids)
            onComplete(allFollowers)
        }, onError: onError)
    }
    
    private static func getUserFollowers(previous: (end_cursor: String, users: [GraphUser])? = nil, limited: Bool, id: String, onSubpartLoaded: @escaping (Int) -> Void, onComplete: @escaping ([GraphUser]) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/graphql/query/"

        let after = previous == nil ? "" : ",\"after\":\"\(previous?.end_cursor ?? "")\""
        
        let parameters: [String: String] = [
            "query_hash": "c76146de99bb02f6415203be841dd25a",
            "variables": "{\"id\":\"\(id)\",\"include_reel\":false,\"fetch_mutual\":false,\"first\":50\(after)}"
        ]
        
        guard let headers = getHeaders() else { onError(GraphError.unknown); return }
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).response { response in
            
            guard let data = response.data else { onError(GraphError.unknown); return }
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(GraphFollowersContainer.self, from: data)
                guard var followers = result.followers else {
                    onError(GraphError.unknown)
                    return
                }
                
                if let previous = previous {
                    onSubpartLoaded(previous.users.count)
                    followers.append(contentsOf: previous.users)
                }
                
                if limited && followers.count > LIMITED_ANALYTICS_F_OR_F_COUNT_REQUARED_LOAD {
                    onComplete(followers)
                } else if result.has_next_page == true, let end_cursor = result.end_cursor {
                    getUserFollowers(previous: (end_cursor: end_cursor, users: followers), limited: limited, id: id, onSubpartLoaded: onSubpartLoaded, onComplete: onComplete, onError: onError)
                } else {
                    onComplete(followers)
                }
            } catch {
                onError(error)
            }
        }
    }
    
    public static func getPostLikers(previous: (end_cursor: String, users: [GraphUser])? = nil, shortcode: String) -> (likers: [GraphUser]?, error: Error?) {
        let url = "https://www.instagram.com/graphql/query/"

        let after = previous == nil ? "" : ",\"after\":\"\(previous?.end_cursor ?? "")\""
        
        let parameters: [String: String] = [
            "query_hash": "d5d763b1e2acf209d62d22d184488e57",
            "variables": "{\"shortcode\":\"\(shortcode)\",\"include_reel\":true,\"first\":50\(after)}"
        ]
        
        guard let headers = getHeaders() else { return (likers: nil, error: GraphError.headersIsNil) }
        
        let response = Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).response()
            
        guard let data = response.data else { return (likers: nil, error: GraphError.responseDataIsNil) }
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(GraphLikersContainer.self, from: data)
            guard var likers = result.likers else { return (likers: nil, error: GraphError.decodeFailed) }
            
            if let previous = previous {
                likers.append(contentsOf: previous.users)
            }

            if likers.count > LIMITED_ANALYTICS_LIKERS_PER_POST_COUNT {
                return (likers: likers, error: nil)
            } else if result.has_next_page == true, let end_cursor = result.end_cursor {
                return getPostLikers(previous: (end_cursor: end_cursor, users: likers), shortcode: shortcode)
            } else {
                return (likers: likers, error: nil)
            }
        } catch {
            return (likers: nil, error: error)
        }
    }
    
    public static func getPostLikers(previous: (end_cursor: String, users: [GraphUser])? = nil, shortcode: String, onComplete: @escaping ((likers: [GraphUser]?, error: Error?)) -> ()) {
        DispatchQueue.global().async {
            let result = getPostLikers(previous: previous, shortcode: shortcode)
            onComplete(result)
        }
    }
    
    public static func getPosts(id: String, onSubpartLoaded: @escaping (Int,Int) -> Void, onComplete: @escaping ([GraphPost]) -> (), onError: @escaping (Error) -> ()) {
        
        getPostsWithoutLikers(id: id, onSubpartLoaded: onSubpartLoaded, onComplete: { postsWithoutLikers in
            var posts = postsWithoutLikers
            
            var completedTasks = 0
            
            DispatchQueue.global().async {
                let posts_withLikers_count = min(LIMITED_ANALYTICS_POSTS_WITH_LIKERS_COUNT, posts.count)
                
                if posts_withLikers_count == 0 {
                    DispatchQueue.main.async {
                        onComplete(posts)
                    }
                } else {
                    for i in 0..<posts_withLikers_count {
                        let post = posts[safe: i]
                        
                        usleep(120_000) /// 3 seconds for all requests. will sleep for 0.12 seconds
                        
                        getPostLikers(shortcode: post?.shortcode ?? "", onComplete: { likers, error in
                            if let error = error {
                                print("!!! ERROR: while async load likers \(error)")
                            }

                            DispatchQueue.main.async {
                                if var post_withLikers = post {
                                    post_withLikers.likers = likers
                                    posts[i] = post_withLikers
                                }
                                completedTasks += 1

                                if completedTasks >= posts_withLikers_count {
                                    onComplete(posts)
                                }
                            }
                        })
                    }
                }
            }
            
//            DispatchQueue.global().async {
//                for post in postsWithoutLikers {
//                    let likersResult = getPostLikers(shortcode: post.shortcode ?? "")
//                    if let likers = likersResult.likers {
//                        var postWithLikers = post
//                        postWithLikers.likers = likers
//
//                        postsWithLikers.append(postWithLikers)
//                    }
//                }
//                DispatchQueue.main.async {
//                    onComplete(postsWithLikers)
//                }
//            }
        }, onError: onError)
    }
        
    public static func getPostsWithoutLikers(previous: (end_cursor: String, posts: [GraphPost])? = nil, id: String, onSubpartLoaded: @escaping (Int, Int) -> Void, onComplete: @escaping ([GraphPost]) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/graphql/query/"

        let after = previous == nil ? "" : ",\"after\":\"\(previous?.end_cursor ?? "")\""
        
        let parameters: [String: String] = [
            "query_hash": "f045d723b6f7f8cc299d62b57abd500a",
            "variables": "{\"id\":\"\(id)\",\"first\":50\(after)}"
        ]
        
        guard let headers = getHeaders() else { onError(GraphError.unknown); return }
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).response { response in
            
            guard let data = response.data else { onError(GraphError.unknown); return }
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(GraphPostsContainer.self, from: data)
                guard var posts = result.posts else {
                    onError(GraphError.unknown)
                    return
                }
                
                if let previous = previous {
                    // обновлять прогресс сейчас так как при учитывании последней подгруженной части может оказаться что загруженных частей больше чем максимальное значение возможных и будет переполнение прогресса шага
                    onSubpartLoaded(previous.posts.count, LIMITED_ANALYTICS_TOTAL_POSTS_COUNT)
                    posts.append(contentsOf: previous.posts)
                }
                
                if posts.count > LIMITED_ANALYTICS_TOTAL_POSTS_COUNT {
                    onComplete(posts)
                } else if result.has_next_page == true, let end_cursor = result.end_cursor {
                    getPostsWithoutLikers(previous: (end_cursor: end_cursor, posts: posts), id: id, onSubpartLoaded: onSubpartLoaded, onComplete: onComplete, onError: onError)
                } else {
                    onComplete(posts)
                }
            } catch {
                onError(error)
            }
        }
    }
    
    public static func getProfileInfo(cookieBase64: String? = nil, userName: String, onComplete: @escaping (GraphProfile) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/" + userName + "/"
        
        guard let headers = getHeaders() else { onError(GraphError.unknown); return }
        
        Alamofire.request(url, method: .get, headers: headers).responseString { response in
            guard let htmlPage = response.value else {
                onError(GraphError.nilValue)
                return
            }
            
            guard let document: Document = try? SwiftSoup.parse(htmlPage) else {
                onError(GraphError.parsing(message: "Document"))
                return
            }
            
            guard let scripts: Elements? = (try? document.body()?.getElementsByTag("script")) else {
                onError(GraphError.parsing(message: "Elements"))
                return
            }
            
            guard let scriptTextArray: [String] = (scripts?.array().map { (try? $0.html()) ?? "" }) else {
                onError(GraphError.parsing(message: "scriptTextArray"))
                return
            }
            
            let marker = "window._sharedData = "
            guard let firstNeededScriptText: String = (scriptTextArray.first { $0.starts(with: marker) }) else {
                onError(GraphError.parsing(message: "firstNeededScriptText"))
                return
            }
            
            var scriptTextWithoutPrefix: String = firstNeededScriptText.replacingOccurrences(of: marker, with: "")
            
            scriptTextWithoutPrefix.removeLast()
            
            guard let dictionary = scriptTextWithoutPrefix.asDictionary else {
                onError(GraphError.parsing(message: "dictionary"))
                return
            }
            
            guard let entryData = dictionary["entry_data"] as? [String: Any] else {
                onError(GraphError.parsing(message: "entryData"))
                return
            }
            
            guard let profilePage = entryData["ProfilePage"] as? [[String: Any]] else {
                onError(GraphError.parsing(message: "profilePage"))
                return
            }
            
            guard let graphql = profilePage.first?["graphql"] as? [String: Any] else {
                onError(GraphError.parsing(message: "graphql"))
                return
            }
            
            guard let user = graphql["user"] as? [String: Any] else {
                onError(GraphError.parsing(message: "user"))
                return
            }
            
            guard let edge_followed_by = user["edge_followed_by"] as? [String: Any] else {
                onError(GraphError.parsing(message: "edge_followed_by"))
                return
            }
            
            guard let edge_follow = user["edge_follow"] as? [String: Any] else {
                onError(GraphError.parsing(message: "edge_follow"))
                return
            }
            
            guard let userId = user["id"] as? String else {
                onError(GraphError.parsing(message: "userId"))
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

    public static func getUserDirectSearch(onComplete: @escaping ([BaseUser]) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/direct_v2/web/ranked_recipients/?mode=raven&query=&show_threads=false"

        guard var headers = getHeaders() else { onError(GraphError.unknown); return }
        headers["User-Agent"] = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1"
        
        Alamofire.request(url, method: .get, headers: headers).responseJSON { response in
            
            let json = response.value as? [String: Any]
            let ranked_recipients = json?["ranked_recipients"] as? [[String: Any]?]
            let threadArray = ranked_recipients?.compactMap { $0?["thread"] as? [String: Any] }
            let users = threadArray?.compactMap { $0["users"] as? [[String: Any]?] }.flatMap { $0 }.compactMap { $0 }
            let baseUsers = users?.map { user in
                return BaseUser(
                    id: user["pk"] as? String,
                    full_name: user["full_name"] as? String,
                    username:  user["username"] as? String,
                    profile_pic_url: user["profile_pic_url"] as? String,
                    is_verified: user["is_verified"] as? Bool,
                    followers: nil,
                    followStatus: nil)
            } ?? []
            onComplete(baseUsers)
        }
    }
    
    public static func follow(id: String, username: String, onComplete: @escaping () -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/web/friendships/" + id + "/follow/"
        guard let headers = getHeaders(XCsrftocken: true) else { onError(GraphError.unknown); return }
        
        Alamofire.request(url, method: .post, headers: headers).response { response in
            if response.response?.statusCode == 200 {
                onComplete()
            } else {
                onError(GraphError.unknown)
            }
        }
    }
    
    public static func unfollow(id: String, onComplete: @escaping () -> (), onError: @escaping (Error) -> ()) {
        let url = "https://www.instagram.com/web/friendships/" + id + "/unfollow/"
        guard let headers = getHeaders(XCsrftocken: true) else { onError(GraphError.unknown); return }
        
        Alamofire.request(url, method: .post, headers: headers).response { response in
            if response.response?.statusCode == 200 {
                onComplete()
            } else {
                onError(GraphError.unknown)
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
                guard let status = container.status, status == "ok" else {
                    onError(GraphError.unknown)
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

        guard let headers = getHeaders() else { onError(GraphError.unknown); return }
        
        Alamofire.request(url, method: .get, headers: headers).responseString { response in
            guard let result = response.value else { onError(GraphError.unknown); return }
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
                onError(GraphError.nilValue)
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
            guard let json = response.value as? [String: Any] else { onError(GraphError.nilValue); return }
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
extension GraphRoutes {
    
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
        
        var headers: HTTPHeaders = [
            "Cookie": cookieString
        ]
        if XCsrftocken {
            headers["x-csrftoken"] = ((cookeisArray.first(where: { ($0["key"] as? String) == "csrftoken" }))?["value"] as? String) ?? ""
        }
        return headers
    }
    
}
