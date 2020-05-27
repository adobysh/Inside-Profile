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
    case blockedUsers
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
    
    static func progressAsync(_ noSubpartsCount: Double,
                              _ noSubpartsLoaded: Double,
                              _ postsCount: Double,
                              _ postsLoaded: Double,
                              _ followersCount: Double,
                              _ followersLoaded: Double,
                              _ followingCount: Double,
                              _ followingLoaded: Double) -> Double {
        
        let onePartProgress = 1.0 / (noSubpartsCount + 3.0)
        
        // sub parts
        let posts =     (postsLoaded > postsCount ? 1.0 : postsLoaded / postsCount)                 * onePartProgress
        let followers = (followersLoaded > followersCount ? 1.0 : followersLoaded / followersCount) * onePartProgress
        let following = (followingLoaded > followingCount ? 1.0 : followingLoaded / followingCount) * onePartProgress
        
        var totalProgress = 0.0
        totalProgress += onePartProgress * noSubpartsLoaded
        totalProgress += posts
        totalProgress += followers
        totalProgress += following
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
        GraphRoutes.getCurrentProfile(completion: { result in
            if let error = result.error {
                onError(error)
                return
            }
            
            let profileInfo  = result.value
            onMainScreenInfoLoaded(profileInfo)
            onProgressUpdate(progress(.profileInfo))
            timePoints.append((.profileInfo, Date()))
            
            onProgressUpdate(progress(.posts))
            
            GraphRoutes.getPosts(id: profileInfo?.id ?? "", onSubpartLoaded: { subpart, subpartCount in
                onProgressUpdate(progress(.posts, subpart, subpartCount))
            }, completion: { result in
                if let error = result.error {
                    onError(error)
                    return
                }
                
                let postDataArray = result.value
                onPostsLoaded(postDataArray)
                timePoints.append((.posts, Date()))
           
                guard let userId = profileInfo?.id else {
                    onError(ErrorModel(file: #file, function: #function, line: #line))
                    return
                }
                onProgressUpdate(progress(.followers))
                
                GraphRoutes.getAllFollowers(limited: profileInfo?.limitedDataDownloadMode == true, id: userId, onSubpartLoaded: { subpart in
                    onProgressUpdate(progress(.followers, subpart, profileInfo?.follower_count ?? 0))
                }, completion: { result in
                    if let error = result.error {
                        onError(error)
                        return
                    }
                    
                    let followers = result.value
                    onFollowersLoaded(followers)
                    timePoints.append((.followers, Date()))
                    
                    GraphRoutes.getMonthHistoryUsers(completion: { result in
                        let monthHistoryUsers = result.value
                        onMonthHistoryUsersLoaded(monthHistoryUsers)
                        onProgressUpdate(progress(.monthHistoryUsers))
                        timePoints.append((.monthHistoryUsers, Date()))
                        
                        onProgressUpdate(progress(.following))
                        GraphRoutes.getUserFollowings(limited: profileInfo?.limitedDataDownloadMode == true, id: userId, onSubpartLoaded: { subpart in
                            onProgressUpdate(progress(.following, subpart, profileInfo?.following_count ?? 0))
                        }, completion: { result in
                            if let error = result.error {
                                onError(error)
                                return
                            }
                            
                            let following = result.value
                            onFollowingLoaded(following)
                            timePoints.append((.following, Date()))
                            
                            GraphRoutes.getGoodSuggestedUser(completion: { result in
                                if let error = result.error {
                                    onError(error)
                                    return
                                }
                                
                                let suggestedUsers = result.value
                                onSuggestedUsersLoaded(suggestedUsers)
                                onProgressUpdate(progress(.suggestedUsers))
                                timePoints.append((.suggestedUsers, Date()))
                                
                                GraphRoutes.getFollowRequests(completion: { result in
                                    if let error = result.error {
                                        onError(error)
                                        return
                                    }
                                    
                                    let followRequests = result.value
                                    onFollowRequestsLoaded(followRequests)
                                    onProgressUpdate(progress(.followRequests))
                                    timePoints.append((.followRequests, Date()))
                                        
                                    GraphRoutes.getBlockedUsersUsernames(userName: profileInfo?.username ?? "", completion: { result in
                                        if let error = result.error {
                                            onError(error)
                                            return
                                        }
                                        
                                        let blockedUsersUsernames = result.value
                                        onBlockedUsersLoaded(blockedUsersUsernames)
                                        onProgressUpdate(progress(.blockedUsers))
                                        timePoints.append((.blockedUsers, Date()))
                                        onComplete(timePoints)
                                    })
                                })
                            })
                        })
                    })
                })
            })
        })
    }
    
    static func fetchInfoAsync(onProgressUpdate: @escaping (Double)->Void,
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
                              onError: @escaping (ErrorModel)->Void) {
        
        var timePoints: [(step: DataPart, time: Date)] = [(.start, Date())]
        
        var isPostsLoaded = false
        var isFollowersAndFollowingLoaded = false
        var isSuggestedUsersLoaded = false
        var isFollowRequestsLoaded = false
        var isBlockedUsersLoaded = false
        
        var isFailed = false
        
        func isComplete() -> Bool {
            return !isFailed &&
                isPostsLoaded &&
                isFollowersAndFollowingLoaded &&
                isSuggestedUsersLoaded &&
                isFollowRequestsLoaded &&
                isBlockedUsersLoaded
        }
        
        GraphRoutes.getCurrentProfile(completion: { result in
            if let error = result.error {
                onError(error)
                return
            }
            
            let profileInfo = result.value
            onMainScreenInfoLoaded(profileInfo)
            timePoints.append((.profileInfo, Date()))
            
            let noSubpartsCount: Double = 3
            var noSubpartsLoaded: Double = 0
            let postsCount: Double = Double(LIMITED_ANALYTICS_TOTAL_POSTS_COUNT)
            var postsLoaded: Double = 0.0
            let followersCount: Double = Double(profileInfo?.follower_count ?? 0)
            var followersLoaded: Double = 0.0
            let followingCount: Double = Double(profileInfo?.following_count ?? 0)
            var followingLoaded: Double = 0.0
            
            GraphRoutes.getPosts(id: profileInfo?.id ?? "", onSubpartLoaded: { subpart, subpartCount in
                postsLoaded = Double(subpart)
                onProgressUpdate(progressAsync(noSubpartsCount, noSubpartsLoaded, postsCount, postsLoaded, followersCount, followersLoaded, followingCount, followingLoaded))
            }, completion: { result in
                if let error = result.error {
                    onError(error)
                    isFailed = true
                    return
                }
                
                let postDataArray = result.value
                onPostsLoaded(postDataArray)
                timePoints.append((.posts, Date()))
                
                isPostsLoaded = true
                if isComplete() {
                    onComplete(timePoints)
                }
            })
            
            GraphRoutes.getMonthHistoryUsers(completion: { result in
                let monthHistoryUsers = result.value
                onMonthHistoryUsersLoaded(monthHistoryUsers)
//                onProgressUpdate(progressAsync(.monthHistoryUsers))
                timePoints.append((.monthHistoryUsers, Date()))
                
                if isComplete() {
                    onComplete(timePoints)
                }
            })
            
            GraphRoutes.getBlockedUsersUsernames(userName: profileInfo?.username ?? "", completion: { result in
                if let error = result.error {
                    onError(error)
                    isFailed = true
                    return
                }
                
                let blockedUsersUsernames = result.value
                onBlockedUsersLoaded(blockedUsersUsernames)
                
                noSubpartsLoaded += 1
                onProgressUpdate(progressAsync(noSubpartsCount, noSubpartsLoaded, postsCount, postsLoaded, followersCount, followersLoaded, followingCount, followingLoaded))
                
                timePoints.append((.blockedUsers, Date()))
                
                isBlockedUsersLoaded = true
                if isComplete() {
                    onComplete(timePoints)
                }
            })
            
            GraphRoutes.getFollowRequests(completion: { result in
                if let error = result.error {
                    onError(error)
                    isFailed = true
                    return
                }
                
                let followRequests = result.value
                onFollowRequestsLoaded(followRequests)
                
                noSubpartsLoaded += 1
                onProgressUpdate(progressAsync(noSubpartsCount, noSubpartsLoaded, postsCount, postsLoaded, followersCount, followersLoaded, followingCount, followingLoaded))
                
                timePoints.append((.followRequests, Date()))
                    
                isFollowRequestsLoaded = true
                if isComplete() {
                    onComplete(timePoints)
                }
            })
            
            GraphRoutes.getGoodSuggestedUser(completion: { result in
                if let error = result.error {
                    onError(error)
                    isFailed = true
                    return
                }
                
                let suggestedUsers = result.value
                onSuggestedUsersLoaded(suggestedUsers)
                
                noSubpartsLoaded += 1
                onProgressUpdate(progressAsync(noSubpartsCount, noSubpartsLoaded, postsCount, postsLoaded, followersCount, followersLoaded, followingCount, followingLoaded))
                
                timePoints.append((.suggestedUsers, Date()))
                
                isSuggestedUsersLoaded = true
                if isComplete() {
                    onComplete(timePoints)
                }
            })
            
            guard let userId = profileInfo?.id else {
                onError(ErrorModel(file: #file, function: #function, line: #line))
                return
            }
            GraphRoutes.getAllFollowers(limited: profileInfo?.limitedDataDownloadMode == true, id: userId, onSubpartLoaded: { subpart in
                followersLoaded = Double(subpart)
                onProgressUpdate(progressAsync(noSubpartsCount, noSubpartsLoaded, postsCount, postsLoaded, followersCount, followersLoaded, followingCount, followingLoaded))
            }, completion: { result in
                if let error = result.error {
                    onError(error)
                    isFailed = true
                    return
                }
                
                let followers = result.value
                onFollowersLoaded(followers)
                timePoints.append((.followers, Date()))
                
                GraphRoutes.getUserFollowings(limited: profileInfo?.limitedDataDownloadMode == true, id: userId, onSubpartLoaded: { subpart in
                    followingLoaded = Double(subpart)
                    onProgressUpdate(progressAsync(noSubpartsCount, noSubpartsLoaded, postsCount, postsLoaded, followersCount, followersLoaded, followingCount, followingLoaded))
                }, completion: { result in
                    if let error = result.error {
                        onError(error)
                        isFailed = true
                        return
                    }
                    
                    let following = result.value
                    onFollowingLoaded(following)
                    timePoints.append((.following, Date()))
                    
                    isFollowersAndFollowingLoaded = true
                    if isComplete() {
                        onComplete(timePoints)
                    }
                })
            })
        })
    }
    
}
