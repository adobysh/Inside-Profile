//
//  GraphApiManager.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 1/28/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import Foundation

class GraphManager {
 
    public static func getProfileInfoAndPosts(onComplete: @escaping ((profileInfo: GraphProfile, postDataArray: [GraphPost])) -> (), onError: @escaping (Error) -> ()) {
        
        GraphRoutes.getUserInfo_graph(onComplete: { baseUser in
            GraphRoutes.getProfileInfo(userName: baseUser.username ?? "", onComplete: { profileInfo in
                GraphRoutes.getPosts(id: baseUser.id ?? "", onComplete: { postDataArray in
                    onComplete((profileInfo, postDataArray))
                }, onError: onError)
            }, onError: onError)
        }, onError: onError)
    }
    
    public static func getTopLikersFriends(myId: String?, topLikers topLikersWithMe: [GraphUser], onComplete: @escaping ([GraphUser]) -> (), onError: @escaping (Error) -> ()) {
        
        // удалить себя
        let topLikers = topLikersWithMe.filter { $0.id != myId }
        
        guard !topLikers.isEmpty else {
            onComplete([])
            return
        }
        
        GraphRoutes.getUserFollowings(limited: true, id: topLikers.first?.id ?? "", onComplete: { followings in
            
            GraphRoutes.getUserFollowers(limited: true, id: topLikers.first?.id ?? "", onComplete: { followers in
                let topLikerFriends = UserModel.friends(followings, followers)
                
                onComplete(topLikerFriends)
            }, onError: onError)
        }, onError: onError)
    }
    
    public static func getMonthHistoryUsers(onComplete: @escaping ([HistoryUser]) -> (), onError: @escaping (Error) -> ()) {
        GraphRoutes.getHistory(onComplete: { history in
            let monthAgoDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let monthHistoryUsers = history.filter { ($0.date ?? Date()) > monthAgoDate }.compactMap { $0.user }
            onComplete(monthHistoryUsers)
        }, onError: onError)
    }
    
    public static func getGoodSuggestedUser(onComplete: @escaping ([GraphUser]) -> (), onError: @escaping (Error) -> ()) {
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
        
        GraphRoutes.getSuggestedUser(onComplete: { suggestedUsers in
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
    
    private static func getParameters() -> [String: String] {
        guard let cookies = AuthorizationManager.shared.cookies else { return [:] }
        let parameters: [String: String] = [
            "cookies" : cookies
        ]
        return parameters
    }
    
}
