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
    case nilValue
    case parsing(message: String)
}

class ApiManager {
    
    static let shared = ApiManager()
    
    private let baseUrl = "https://api.instagram.com/v1/"
    
    private init() {}
    
    public func getProfileInfoAndPosts(onComplete: @escaping ((profileInfo: GraphProfile, postDataArray: [GraphPost])) -> (), onError: @escaping (Error) -> ()) {
        
        GraphAPIRoutes.getUserInfo_graph(onComplete: { baseUser in
            GraphAPIRoutes.getProfileInfo(userName: baseUser.username ?? "", onComplete: { profileInfo in
                GraphAPIRoutes.getPosts(id: baseUser.id ?? "", onComplete: { postDataArray in
                    onComplete((profileInfo, postDataArray))
                }, onError: onError)
            }, onError: onError)
        }, onError: onError)
    }
    
    /* private API */
//    public func getProfileInfo(cookieBase64: String? = nil, id: String = "me", onComplete: @escaping (ProfileInfoData) -> (), onError: @escaping (Error) -> ()) {
//        let url = "https://i-info.n44.me/user/info/" + id
//
//        let parameters: [String: String]
//        if let cookieBase64 = cookieBase64 {
//            parameters = [
//                "cookies" : cookieBase64
//            ]
//        } else {
//            parameters = getParameters()
//        }
//
//        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).response { response in
//            guard let data = response.data else { return }
//            do {
//                let decoder = JSONDecoder()
//                let container = try decoder.decode(ProfileInfoData.self, from: data)
//                print("!!! ProfileInfoData \(container)")
//                guard let _ = container.username, let _ = container.follower_count else {
//                    onError(ApiError.unknown)
//                    return
//                }
//                onComplete(container)
//            } catch {
//                onError(error)
//            }
//        }
//    }
    
//    public func getPosts(onComplete: @escaping ([PostData]) -> (), onError: @escaping (Error) -> ()) {
//        let url = "https://i-info.n44.me/user/posts/me"
//        
//        let parameters: [String: String] = getParameters()
//        
//        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).response { [weak self] response in
//            guard let data = response.data else { return }
//            do {
//                let decoder = JSONDecoder()
//                let container = try decoder.decode(PostsContainerData.self, from: data)
//                print("!!! ProfileInfoData \(container)")
//                guard let posts = container.feed else {
//                    onError(ApiError.unknown)
//                    return
//                }
//                let notNilPosts = posts.compactMap { $0 }
//                onComplete(notNilPosts)
//            } catch {
//                onError(error)
//            }
//        }
//    }
    
    public func getTopLikersFriends(myId: String?, topLikers topLikersWithMe: [ApiUser], onComplete: @escaping ([ApiUser]) -> (), onError: @escaping (Error) -> ()) {
        
        // удалить себя
        let topLikers = topLikersWithMe.filter { $0.id != myId }
        
        guard !topLikers.isEmpty else {
            onComplete([])
            return
        }
        
        print("!!! topLikers ids \(topLikers.map { $0.id })")
        
        getFollowings(limited: true, userId: topLikers.first?.id, onComplete: { [weak self] followings in
            print("!!! topLiker followings count \(followings.count)")
            
            self?.getAllFollowers(limited: true, userId: topLikers.first?.id ?? "", onComplete: { followers in
                print("!!! topLiker followers count \(followers.count)")
                let topLikerFriends = UserModel.friends(followings, followers)
                print("!!! topLiker friends count \(topLikerFriends.count)")
                
                onComplete(topLikerFriends)
            }, onError: onError)
        }, onError: onError)
    }
    
    public func getAllFollowers(limited: Bool, userId: String, onComplete: @escaping ([ApiUser]) -> (), onError: @escaping (Error) -> ()) {
        getFollowers(limited: limited, onComplete: { allFollowers in
            let ids = allFollowers.compactMap { $0.id }
            PastFollowersManager.shared.save(userId, ids)
            onComplete(allFollowers)
        }, onError: onError)
    }
    
    private func getFollowers(limited: Bool, users: [ApiUser] = [], state: String? = nil, userId: String? = nil, onComplete: @escaping ([ApiUser]) -> (), onError: @escaping (Error) -> ()) {
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
                
                if limited && followers.count > LIMITED_ANALYTICS_F_OR_F_COUNT_REQUARED_LOAD {
                    onComplete(followers)
                } else if container.state?.asDictionary?["moreAvailable"] as? Bool == true {
                    self?.getFollowers(limited: true, users: followers, state: container.state, userId: userId, onComplete: onComplete, onError: onError)
                } else {
                    onComplete(followers)
                }
            } catch {
                onError(error)
            }
        }
    }
    
    public func getFollowings(limited: Bool, users: [ApiUser] = [], state: String? = nil, userId: String? = nil, onComplete: @escaping ([ApiUser]) -> (), onError: @escaping (Error) -> ()) {
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
                
                if limited && following.count > LIMITED_ANALYTICS_F_OR_F_COUNT_REQUARED_LOAD {
                    onComplete(following)
                } else if container.state?.asDictionary?["moreAvailable"] as? Bool == true {
                    self?.getFollowings(limited: limited, users: following, state: container.state, userId: userId, onComplete: onComplete, onError: onError)
                } else {
                    onComplete(following)
                }
            } catch {
                onError(error)
            }
        }
    }
    
    public func getMonthHistoryUsers(onComplete: @escaping ([HistoryUser]) -> (), onError: @escaping (Error) -> ()) {
        GraphAPIRoutes.getHistory(onComplete: { history in
            let monthAgoDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let monthHistoryUsers = history.filter { ($0.date ?? Date()) > monthAgoDate }.compactMap { $0.user }
            onComplete(monthHistoryUsers)
        }, onError: onError)
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
        
        GraphAPIRoutes.getSuggestedUser(onComplete: { suggestedUsers in
            let notBadSuggestedUsers = suggestedUsers.filter { $0.is_verified == false }
            
            var goodSuggestedUsers = notBadSuggestedUsers.filter { isGood($0) }
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
            onComplete(goodSuggestedUsers)
        }, onError: onError)
    }
    
    private func getParameters() -> [String: String] {
        guard let cookies = AuthorizationManager.shared.cookies else { return [:] }
        let parameters: [String: String] = [
            "cookies" : cookies
        ]
        print("!!! cookiesBase64 \(cookies)")
        return parameters
    }
    
}
