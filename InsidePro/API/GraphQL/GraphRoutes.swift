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

struct ErrorModel: Error {
    private let file: String
    private let function: String
    private let line: Int
    private let comment: String?
    
    var localizedDescription: String {
        var localizedDescription = "Error\n\(file)\n\(function)\nat line \(line)"
        if let comment = comment {
            localizedDescription += "\n\"\(comment)\""
        }
        return localizedDescription
    }
    
    init(file: String, function: String, line: Int, comment: String? = nil) {
        self.file = file
        self.function = function
        self.line = line
        self.comment = comment
    }
}

enum Completion<T> {
    case success(T)
    case error(ErrorModel)
    
    var value: T? {
        switch self {
        case .success(let value):
            return value
        case .error:
            return nil
        }
    }
    
    var error: ErrorModel? {
        switch self {
        case .success:
            return nil
        case .error(let errorModel):
            return errorModel
        }
    }
}

class GraphRoutes {
    
    public static func getBlockedUsersUsernames(userName: String, previous: (cursor: String, blockedUsernames: [String])? = nil, completion: @escaping (Completion<[String]>) -> Void) {
        
        let url = "https://www.instagram.com/accounts/access_tool/accounts_you_blocked"
        
        var parameters: [String: String] = [:]
        
        if let cursor = previous?.cursor {
            parameters = [
                "__a": "1",
                "cursor": (cursor.decodeUrl() ?? "")
            ]
        }
        
        guard let headers = getHeaders() else {
            completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
            return
        }
        
        Alamofire.request(url, method: .get, parameters: parameters, headers: headers).responseString { response in
            
            if let _ = previous {
                guard let settingsPages_data = response.value?.asDictionary?["data"] as? [String: Any] else {
                    completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                    return
                }
                
                guard let settingsPages_data_data = settingsPages_data["data"] as? [[String: Any]] else {
                    completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                    return
                }
                
                var blockedUsernames = settingsPages_data_data.compactMap { $0["text"] as? String }
                
                if let previous = previous {
                    blockedUsernames.append(contentsOf: previous.blockedUsernames)
                }

                if blockedUsernames.count > LIMITED_ANALYTICS_TOTAL_BLOCKED {
                    completion(.success(blockedUsernames))
                } else if let cursor = settingsPages_data["cursor"] as? String {
                    getBlockedUsersUsernames(userName: userName, previous: (cursor: cursor, blockedUsernames: blockedUsernames), completion: completion)
                } else {
                     completion(.success(blockedUsernames))
                }
                return
            }
            
            guard let htmlPage = response.value else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            guard let document: Document = try? SwiftSoup.parse(htmlPage) else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            guard let scripts: Elements? = (try? document.body()?.getElementsByTag("script")) else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            guard let scriptTextArray: [String] = (scripts?.array().map { (try? $0.html()) ?? "" }) else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            let marker = "window._sharedData = "
            guard let firstNeededScriptText: String = (scriptTextArray.first { $0.starts(with: marker) }) else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }

            var scriptTextWithoutPrefix: String = firstNeededScriptText.replacingOccurrences(of: marker, with: "")

            scriptTextWithoutPrefix.removeLast()

            guard let dictionary = scriptTextWithoutPrefix.asDictionary else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }

            guard let entryData = dictionary["entry_data"] as? [String: Any] else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }

            guard let settingsPages = entryData["SettingsPages"] as? [[String: Any]] else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }

            guard let settingsPages_data = settingsPages.first?["data"] as? [String: Any] else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            guard let settingsPages_data_data = settingsPages_data["data"] as? [[String: Any]] else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            var blockedUsernames = settingsPages_data_data.compactMap { $0["text"] as? String }
            
            if let previous = previous {
                blockedUsernames.append(contentsOf: previous.blockedUsernames)
            }

            if blockedUsernames.count > LIMITED_ANALYTICS_TOTAL_BLOCKED {
                completion(.success(blockedUsernames))
            } else if let cursor = settingsPages_data["cursor"] as? String {
                getBlockedUsersUsernames(userName: userName, previous: (cursor: cursor, blockedUsernames: blockedUsernames), completion: completion)
            } else {
                 completion(.success(blockedUsernames))
            }
        }
    }
    
    public static func getUserFollowings(previous: (end_cursor: String, users: [GraphUser])? = nil, limited: Bool, id: String, onSubpartLoaded: @escaping (Int)->Void, completion: @escaping (Completion<[GraphUser]>) -> Void) {
        let url = "https://www.instagram.com/graphql/query/"
        
        let after = previous == nil ? "" : ",\"after\":\"\(previous?.end_cursor ?? "")\""

        let parameters: [String: String] = [
            "query_hash": "d04b0a864b4b54837c0d870b0e77e076",
            "variables": "{\"id\":\"\(id)\",\"include_reel\":false,\"fetch_mutual\":false,\"first\":50\(after)}"
        ]
        
        guard let headers = getHeaders() else {
            completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
            return
        }
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).response { response in
            
            guard let data = response.data else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(GraphFollowingsContainer.self, from: data)
                guard var followings = result.followings else {
                    completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                    return
                }
            
                if let previous = previous {
                    onSubpartLoaded(previous.users.count)
                    followings.append(contentsOf: previous.users)
                }

                if limited && followings.count > LIMITED_ANALYTICS_F_OR_F_COUNT_REQUARED_LOAD {
                    completion(.success(followings))
                } else if result.has_next_page == true, let end_cursor = result.end_cursor {
                    getUserFollowings(previous: (end_cursor: end_cursor, users: followings), limited: limited, id: id, onSubpartLoaded: onSubpartLoaded, completion: completion)
                } else {
                    completion(.success(followings))
                }
            } catch {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line, comment: error.localizedDescription)))
            }
        }
    }
    
    public static func getAllFollowers(limited: Bool, id: String, onSubpartLoaded: @escaping (Int) -> Void, completion: @escaping (Completion<[GraphUser]>) -> Void) {
        getUserFollowers(limited: limited, id: id, onSubpartLoaded: onSubpartLoaded, completion: { result in
            switch result {
            case .success(let allFollowers):
                let ids = allFollowers.compactMap { $0.id }
                PastFollowersManager.shared.save(id, ids)
                completion(.success(allFollowers))
            case .error(let errorModel):
                completion(.error(errorModel))
            }
        })
    }
    
    private static func getUserFollowers(previous: (end_cursor: String, users: [GraphUser])? = nil, limited: Bool, id: String, onSubpartLoaded: @escaping (Int) -> Void, completion: @escaping (Completion<[GraphUser]>) -> Void) {
        let url = "https://www.instagram.com/graphql/query/"

        let after = previous == nil ? "" : ",\"after\":\"\(previous?.end_cursor ?? "")\""
        
        let parameters: [String: String] = [
            "query_hash": "c76146de99bb02f6415203be841dd25a",
            "variables": "{\"id\":\"\(id)\",\"include_reel\":false,\"fetch_mutual\":false,\"first\":50\(after)}"
        ]
        
        guard let headers = getHeaders() else {
            completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
            return
        }
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).response { response in
            
            guard let data = response.data else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(GraphFollowersContainer.self, from: data)
                guard var followers = result.followers else {
                    completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                    return
                }
                
                if let previous = previous {
                    onSubpartLoaded(previous.users.count)
                    followers.append(contentsOf: previous.users)
                }
                
                if limited && followers.count > LIMITED_ANALYTICS_F_OR_F_COUNT_REQUARED_LOAD {
                    completion(.success(followers))
                } else if result.has_next_page == true, let end_cursor = result.end_cursor {
                    getUserFollowers(previous: (end_cursor: end_cursor, users: followers), limited: limited, id: id, onSubpartLoaded: onSubpartLoaded, completion: completion)
                } else {
                    completion(.success(followers))
                }
            } catch {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
            }
        }
    }
    
    public static func getPostLikers(previous: (end_cursor: String, users: [GraphUser])? = nil, shortcode: String) -> Completion<[GraphUser]> {
        let url = "https://www.instagram.com/graphql/query/"

        let after = previous == nil ? "" : ",\"after\":\"\(previous?.end_cursor ?? "")\""
        
        let parameters: [String: String] = [
            "query_hash": "d5d763b1e2acf209d62d22d184488e57",
            "variables": "{\"shortcode\":\"\(shortcode)\",\"include_reel\":true,\"first\":50\(after)}"
        ]
        
        guard let headers = getHeaders() else {
            return .error(ErrorModel(file: #file, function: #function, line: #line))
        }
        
        let response = Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).response()
            
        guard let data = response.data else {
            return .error(ErrorModel(file: #file, function: #function, line: #line))
        }
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(GraphLikersContainer.self, from: data)
            guard var likers = result.likers else {
                return .error(ErrorModel(file: #file, function: #function, line: #line))
            }
            
            if let previous = previous {
                likers.append(contentsOf: previous.users)
            }

            if likers.count > LIMITED_ANALYTICS_LIKERS_PER_POST_COUNT {
                return .success(likers)
            } else if result.has_next_page == true, let end_cursor = result.end_cursor {
                return getPostLikers(previous: (end_cursor: end_cursor, users: likers), shortcode: shortcode)
            } else {
                return .success(likers)
            }
        } catch {
            return .error(ErrorModel(file: #file, function: #function, line: #line, comment: error.localizedDescription))
        }
    }
    
    public static func getPostLikers(previous: (end_cursor: String, users: [GraphUser])? = nil, shortcode: String, completion: @escaping (Completion<[GraphUser]>) -> Void) {
        DispatchQueue.global().async {
            let result = getPostLikers(previous: previous, shortcode: shortcode)
            completion(result)
        }
    }
    
    public static func getPosts(id: String, onSubpartLoaded: @escaping (Int,Int) -> Void, completion: @escaping (Completion<[GraphPost]>) -> Void) {
        
        getPostsWithoutLikers(id: id, onSubpartLoaded: onSubpartLoaded, completion: { postsWithoutLikers in
            switch postsWithoutLikers {
            case .success(let postsWithoutLikers):
                fillPostsWithLikers(posts: postsWithoutLikers, completion: completion)
            case .error(let errorModel):
                completion(.error(errorModel))
            }
        })
    }
    
    private static func fillPostsWithLikers(posts postsWithoutLikers: [GraphPost], completion: @escaping (Completion<[GraphPost]>) -> Void) {
        var posts = postsWithoutLikers
        
        var completedTasks = 0
        
        DispatchQueue.global().async {
            let posts_withLikers_count = min(LIMITED_ANALYTICS_POSTS_WITH_LIKERS_COUNT, posts.count)
            
            if posts_withLikers_count == 0 {
                DispatchQueue.main.async {
                    completion(.success(posts))
                }
            } else {
                for i in 0..<posts_withLikers_count {
                    let post = posts[safe: i]
                    
                    usleep(120_000) /// 3 seconds for all requests. will sleep for 0.12 seconds
                    
                    getPostLikers(shortcode: post?.shortcode ?? "", completion: { result in
                        if let error = result.error {
                            print("!!! ERROR: \(error.localizedDescription)")
                        }

                        DispatchQueue.main.async {
                            if var post_withLikers = post {
                                post_withLikers.likers = result.value
                                posts[i] = post_withLikers
                            }
                            completedTasks += 1

                            if completedTasks >= posts_withLikers_count {
                                completion(.success(posts))
                            }
                        }
                    })
                }
            }
        }
    }
        
    public static func getPostsWithoutLikers(previous: (end_cursor: String, posts: [GraphPost])? = nil, id: String, onSubpartLoaded: @escaping (Int, Int) -> Void, completion: @escaping (Completion<[GraphPost]>) -> Void) {
        let url = "https://www.instagram.com/graphql/query/"

        let after = previous == nil ? "" : ",\"after\":\"\(previous?.end_cursor ?? "")\""
        
        let parameters: [String: String] = [
            "query_hash": "f045d723b6f7f8cc299d62b57abd500a",
            "variables": "{\"id\":\"\(id)\",\"first\":50\(after)}"
        ]
        
        guard let headers = getHeaders() else {
            completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
            return
        }
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).response { response in
            
            guard let data = response.data else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(GraphPostsContainer.self, from: data)
                guard var posts = result.posts else {
                    completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                    return
                }
                
                if let previous = previous {
                    // обновлять прогресс сейчас так как при учитывании последней подгруженной части может оказаться что загруженных частей больше чем максимальное значение возможных и будет переполнение прогресса шага
                    onSubpartLoaded(previous.posts.count, LIMITED_ANALYTICS_TOTAL_POSTS_COUNT)
                    posts.append(contentsOf: previous.posts)
                }
                
                if posts.count > LIMITED_ANALYTICS_TOTAL_POSTS_COUNT {
                    completion(.success(posts))
                } else if result.has_next_page == true, let end_cursor = result.end_cursor {
                    getPostsWithoutLikers(previous: (end_cursor: end_cursor, posts: posts), id: id, onSubpartLoaded: onSubpartLoaded, completion: completion)
                } else {
                    completion(.success(posts))
                }
            } catch {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
            }
        }
    }
    
    static func getProfile(userName: String, completion: @escaping (Completion<GraphProfile>) -> Void) {
        let url = "https://www.instagram.com/" + userName + "/"
        
        guard let headers = getHeaders() else {
            completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
            return
        }
        
        Alamofire.request(url, method: .get, headers: headers).responseString { response in
            guard let htmlPage = response.value else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            guard let document: Document = try? SwiftSoup.parse(htmlPage) else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            guard let scripts: Elements? = (try? document.body()?.getElementsByTag("script")) else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            guard let scriptTextArray: [String] = (scripts?.array().map { (try? $0.html()) ?? "" }) else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            let marker = "window._sharedData = "
            guard let firstNeededScriptText: String = (scriptTextArray.first { $0.starts(with: marker) }) else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            var scriptTextWithoutPrefix: String = firstNeededScriptText.replacingOccurrences(of: marker, with: "")
            
            scriptTextWithoutPrefix.removeLast()
            
            guard let dictionary = scriptTextWithoutPrefix.asDictionary else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            guard let entryData = dictionary["entry_data"] as? [String: Any] else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            guard let profilePage = entryData["ProfilePage"] as? [[String: Any]] else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            guard let graphql = profilePage.first?["graphql"] as? [String: Any] else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            guard let user = graphql["user"] as? [String: Any] else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            guard let edge_followed_by = user["edge_followed_by"] as? [String: Any] else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            guard let edge_follow = user["edge_follow"] as? [String: Any] else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            
            guard let userId = user["id"] as? String else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
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
            
            completion(.success(profileInfo))
        }
    }
    
    public static func getUserDirectSearch(completion: @escaping (Completion<[BaseUser]>) -> Void) {
        let url = "https://www.instagram.com/direct_v2/web/ranked_recipients/?mode=raven&query=&show_threads=false"

        guard var headers = getHeaders() else {
            completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
            return
        }
        
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
            
            completion(.success(baseUsers))
        }
    }
    
    public static func follow(id: String, username: String, completion: @escaping (Completion<FollowStatus>) -> Void) {
        let url = "https://www.instagram.com/web/friendships/" + id + "/follow/"
        guard let headers = getHeaders(XCsrftocken: true, XInstagramAjax: true) else {
            completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
            return
        }
        
        Alamofire.request(url, method: .post, headers: headers).responseString { response in
            if let statusCode = response.response?.statusCode, statusCode == 200 {
                guard let dictionary = response.value?.asDictionary else {
                    completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                    return
                }
                
                var followStatus: FollowStatus
                if (dictionary["result"] as? String) == "requested" {
                    followStatus = .requested
                } else if (dictionary["result"] as? String) == "following" {
                    followStatus = .yes
                } else {
                    followStatus = .disabled
                }
                
                completion(.success(followStatus))
            } else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
            }
        }
    }
    
    public static func unfollow(id: String, completion: @escaping (Completion<Int>) -> Void) {
        let url = "https://www.instagram.com/web/friendships/" + id + "/unfollow/"
        guard let headers = getHeaders(XCsrftocken: true) else {
            completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
            return
        }
        
        Alamofire.request(url, method: .post, headers: headers).response { response in
            if let statusCode = response.response?.statusCode, statusCode == 200 {
                completion(.success(statusCode))
            } else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
            }
        }
    }
    
    public static func getSuggestedUser(suggestedUsers: [GraphUser] = [], completion: @escaping (Completion<[GraphUser]>) -> Void) {
        let url = "https://www.instagram.com/graphql/query/"
        
        guard var headers = getHeaders() else {
            completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
            return
        }
        headers["Accept-Language"] = "en"

        //        "seen_ids":["263874345","1247439238",
        let seen_ids_array = suggestedUsers.map { "\($0.id ?? "")" }
        let seen_ids = seen_ids_array.joined(separator:",")
        
        let parameters: [String: String] = [
            "query_hash": "bd90987150a65578bc0dd5d4e60f113d",
            "variables": "{\"fetch_media_count\":0,\"fetch_suggested_count\":30,\"ignore_cache\":false,\"filter_followed_friends\":true,\"seen_ids\":[\(seen_ids)],\"include_reel\":true}"
        ]
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).response { response in
            guard let data = response.data else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            do {
                let decoder = JSONDecoder()
                let container = try decoder.decode(SuggestedUsersWebContainer.self, from: data)
                guard let status = container.status, status == "ok" else {
                    completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
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
                    getSuggestedUser(suggestedUsers: users, completion: completion)
                } else {
                    completion(.success(users))
                }
            } catch {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
            }
        }
    }
    
    public static func getFollowRequests(completion: @escaping (Completion<FollowRequests>) -> Void) {
        let url = "https://www.instagram.com/accounts/access_tool/current_follow_requests"

        guard let headers = getHeaders() else {
            completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
            return
        }
        
        Alamofire.request(url, method: .get, headers: headers).responseString { response in
            guard let result = response.value else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            completion(.success(FollowRequests(value: result)))
        }
    }
    
    public static func getUserInfo_graph(cookieBase64: String? = nil, id: String = "", completion: @escaping (Completion<BaseUser>) -> Void) {
        // Если сделать запрос с пустым списком айдишек то вернёт инфу о себе.
        
        let url = "https://www.instagram.com/graphql/query/"
        
        guard let headers = getHeaders(cookieBase64: cookieBase64) else {
            completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
            return
        }
        
        let parameters: [String: String] = [
            "query_hash": "aec5501414615eca36a9acf075655b1e",
            "variables": "{\"user_id\":\"\(id)\",\"include_chaining\":false,\"include_reel\":true,\"include_suggested_users\":false,\"include_logged_out_extras\":false,\"include_highlight_reels\":false}"
        ]
        
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: headers).responseJSON { response in
            guard let json = response.value as? [String: Any] else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
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
                completion(.success(BaseUser.disabled(id)))
                return
            }
            
            let baseUser = BaseUser(
                id: userDictionary["id"] as? String,
                full_name: nil,
                username: userDictionary["username"] as? String,
                profile_pic_url: userDictionary["profile_pic_url"] as? String,
                is_verified: nil,
                followers: nil)
            
            completion(.success(baseUser))
        }
    }
    
    public static func getHistory(completion: @escaping (Completion<[HistoryData]>) -> Void) {
        
        let url = "https://www.instagram.com/accounts/activity/?__a=1&include_reel=true"
        
        guard let headers = getHeaders() else { return }
        
        Alamofire.request(url, method: .get, encoding: URLEncoding(destination: .queryString), headers: headers).responseJSON { response in
            guard let json = response.value as? [String: Any] else {
                completion(.error(ErrorModel(file: #file, function: #function, line: #line)))
                return
            }
            let graphql = json["graphql"] as? [String: Any]
            let user = graphql?["user"] as? [String: Any]
            let activity_feed = user?["activity_feed"] as? [String: Any]
            let edge_web_activity_feed = activity_feed?["edge_web_activity_feed"] as? [String: Any]
            let edges = edge_web_activity_feed?["edges"] as? [[String: Any]]
            
            let historyFollowArray = edges?.filter { edge in
                let node = edge["node"] as? [String: Any]
                return (node?["__typename"] as? String) == "GraphFollowAggregatedStory"
            }
            let historyArray: [HistoryData] = historyFollowArray?.map { edge in
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
            } ?? []
            completion(.success(historyArray))
        }
    }
    
}

// MARK: - Utils
extension GraphRoutes {
    
    public static func getHeaders(XCsrftocken: Bool = false, XInstagramAjax: Bool = false, cookieBase64: String? = nil) -> HTTPHeaders? {
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
        if XInstagramAjax {
            headers["x-instagram-ajax"] = randomString(length: 12)
        }
        return headers
    }
    
    private static func randomString(length: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyz0123456789"
        let len = UInt32(letters.length)
        var randomString = ""
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        return randomString
    }
    
}

// MARK: - Utils
extension GraphRoutes {
    
    public static func getCurrentProfile(completion: @escaping (Completion<GraphProfile>) -> Void) {
        GraphRoutes.getUserInfo_graph(completion: { baseUserResult in
            GraphRoutes.getProfile(userName: baseUserResult.value?.username ?? "", completion: { result in
                completion(result)
            })
        })
    }
    
    public static func getMonthHistoryUsers(completion: @escaping (Completion<[HistoryUser]>) -> Void) {
        GraphRoutes.getHistory(completion: { result in
            switch result {
            case .success(let history):
                let monthAgoDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                let monthHistoryUsers = history.filter { ($0.date ?? Date()) > monthAgoDate }.compactMap { $0.user }
                completion(.success(monthHistoryUsers))
            case .error(let errorModel):
                completion(.error(errorModel))
            }
        })
    }
    
    public static func getGoodSuggestedUser(completion: @escaping (Completion<[GraphUser]>) -> Void) {
        GraphRoutes.getSuggestedUser(completion: { result in
            if let error = result.error {
                completion(.error(error))
                return
            }
            
            let notBadSuggestedUsers = result.value?.filter { $0.is_verified == false } ?? []
            
            var goodSuggestedUsers = notBadSuggestedUsers.filter { $0.isGoodSuggested }
            if goodSuggestedUsers.isEmpty {
                goodSuggestedUsers = notBadSuggestedUsers
            }
            
            goodSuggestedUsers = goodSuggestedUsers.map { user in
                var user2 = user
                user2.descriptionText = user2.descriptionText?.replacingOccurrences(of: "by\\s.+\\s\\+", with: "", options: [.regularExpression])
                user2.descriptionText = user2.descriptionText?.replacingOccurrences(of: "Suggested for you", with: "0 Suggested for you")
                return user2
            }
            
            goodSuggestedUsers.sort { ($0.descriptionText ?? "") > ($1.descriptionText ?? "") }
            completion(.success(goodSuggestedUsers))
        })
    }
    
    private static func getParameters() -> [String: String] {
        guard let cookies = AuthorizationManager.shared.cookies else { return [:] }
        let parameters: [String: String] = [
            "cookies" : cookies
        ]
        return parameters
    }
    
}
