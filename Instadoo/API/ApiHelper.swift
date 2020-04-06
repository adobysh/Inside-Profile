//
//  ApiHelper.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 3/20/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import Foundation

enum DataPart: Int, CaseIterable {
    case start
    case profileInfo
    case posts
    case followers
    case monthHistoryUsers
    case following
    case suggestedUsers
    case followRequests
    case userDirectSearch
    case blockedUsers
    case topLikersFriends
    case done
}

class ApiHelper {
    
    static func progress(_ part: DataPart, _ subpart: Int = 0, _ dangerSubpartsCount: Int = 1) -> Double {
        
        let subpartsCount = subpart < dangerSubpartsCount ? dangerSubpartsCount : subpart
        
        let partsCount: Double = Double(DataPart.allCases.count)
        let partProgress = Double(part.rawValue + 1) / partsCount
        print("!!! \(part.rawValue)/\(Int(partsCount)) partProgress    \(partProgress)")
        let subpartProgress = Double(subpart) / Double(subpartsCount)
        let subpartProgressGlobalProgress = subpartProgress / partsCount
        print("!!! \(subpart      )/\(subpartsCount  ) subpartProgress \(subpartProgress) (\(subpartProgressGlobalProgress))")
        print("!!! partProgress \(partProgress)")
        
        let totalProgress = partProgress + subpartProgressGlobalProgress
        print("!!! totalProgress \(totalProgress)")
        print("!!! -----")
        return totalProgress
    }
    
    static func fetchInfo(onProgressUpdate: @escaping (Double)->Void,
                          onMainScreenInfoLoaded: @escaping (GraphProfile?)->Void,
                          onFollowRequestsLoaded: @escaping (FollowRequests?)->Void,
                          onPostsLoaded: @escaping ([GraphPost]?)->Void,
                          onFollowersLoaded: @escaping ([GraphUser]?)->Void,
                          onFollowingLoaded: @escaping ([GraphUser]?)->Void,
                          onSuggestedUsersLoaded: @escaping ([GraphUser]?)->Void,
                          onUserDirectSearchLoaded: @escaping ([BaseUser]?)->Void,
                          onTopLikersFollowersLoaded: @escaping ([GraphUser]?)->Void,
                          onMonthHistoryUsersLoaded: @escaping ([HistoryUser]?)->Void,
                          onBlockedUsersLoaded: @escaping ([String]?)->Void,
                          onComplete: @escaping ([(step: DataPart, time: Date)])->Void,
                          onError: @escaping (Error)->Void) {
        
        var timePoints: [(step: DataPart, time: Date)] = [(.start, Date())]
        
        onProgressUpdate(progress(.start))
        GraphManager.getProfileInfo(onComplete: { profileInfo in
            onMainScreenInfoLoaded(profileInfo)
            onProgressUpdate(progress(.profileInfo))
            timePoints.append((.profileInfo, Date()))
            
            onProgressUpdate(progress(.posts))
            GraphRoutes.getPosts(id: profileInfo.id ?? "", onSubpartLoaded: { subpart, subpartCount in
                onProgressUpdate(progress(.posts, subpart, subpartCount))
            }, onComplete: { postDataArray in
                onPostsLoaded(postDataArray)
                timePoints.append((.posts, Date()))
            
                guard let userId = profileInfo.id else { onError(GraphError.nilValue); return }
                onProgressUpdate(progress(.followers))
                
                GraphRoutes.getAllFollowers(limited: profileInfo.limitedDataDownloadMode, id: userId, onSubpartLoaded: { subpart in
                    onProgressUpdate(progress(.followers, subpart, profileInfo.follower_count ?? 0))
                }, onComplete: { followers in
                    onFollowersLoaded(followers)
                    timePoints.append((.followers, Date()))
                    
                    GraphManager.getMonthHistoryUsers(onComplete: { monthHistoryUsers in
                        onMonthHistoryUsersLoaded(monthHistoryUsers)
                        onProgressUpdate(progress(.monthHistoryUsers))
                        timePoints.append((.monthHistoryUsers, Date()))
                        
                        onProgressUpdate(progress(.following))
                        GraphRoutes.getUserFollowings(limited: profileInfo.limitedDataDownloadMode, id: userId, onSubpartLoaded: { subpart in
                            onProgressUpdate(progress(.following, subpart, profileInfo.following_count ?? 0))
                        }, onComplete: { following in
                            onFollowingLoaded(following)
                            timePoints.append((.following, Date()))
                            
                            GraphManager.getGoodSuggestedUser(onComplete: { suggestedUsers in
                                onSuggestedUsersLoaded(suggestedUsers)
                                onProgressUpdate(progress(.suggestedUsers))
                                timePoints.append((.suggestedUsers, Date()))
                                
                                GraphRoutes.getFollowRequests(onComplete: { followRequests in
                                    onFollowRequestsLoaded(followRequests)
                                    onProgressUpdate(progress(.followRequests))
                                    timePoints.append((.followRequests, Date()))
                                    
                                    GraphRoutes.getUserDirectSearch(onComplete: { userDirectSearch in
                                        onUserDirectSearchLoaded(userDirectSearch)
                                        onProgressUpdate(progress(.userDirectSearch))
                                        timePoints.append((.userDirectSearch, Date()))
                                        
                                        GraphRoutes.getBlockedUsersUsernames(userName: profileInfo.username ?? "", onComplete: { blockedUsersUsernames in
                                            onBlockedUsersLoaded(blockedUsersUsernames)
                                            onProgressUpdate(progress(.blockedUsers))
                                            timePoints.append((.blockedUsers, Date()))
                                        
                                            if GuestsManager.shared.containIds(userId) {
                                                onProgressUpdate(progress(.done))
                                                onComplete(timePoints)
                                            } else {
                                                let topLikers = UserModel.topLikers(profileInfo.username, postDataArray)
                                                GraphManager.getTopLikersFriends(myId: userId, topLikers: topLikers, onComplete: { topLikersFollowers in
                                                    onTopLikersFollowersLoaded(topLikersFollowers)
                                                    timePoints.append((.topLikersFriends, Date()))
                                                    
                                                    onProgressUpdate(progress(.done))
                                                    onComplete(timePoints)
                                                }, onError: onError)
                                            }
                                        }, onError: onError)
                                    }, onError: onError)
                                }, onError: onError)
                            }, onError: onError)
                        }, onError: onError)
                    }, onError: onError)
                }, onError: onError)
            }, onError: onError)
        }, onError: onError)
    }
    
}
