//
//  MainViewModel.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 4/16/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import Foundation

enum DushboardItemType {
    case lost_followers
    case gained_followers
    case you_dont_follow
    case unfollowers
    case blocked_by_you
    case recommendation
    case top_likers
    case top_commenters
}

struct DushboardItem {
    let title: String
    let type: DushboardItemType
}

typealias ProfileInfoCompletion = (Completion<GraphProfile>) -> Void
typealias TopLikersCompletion = (Completion<[User]>) -> Void
typealias TopCommentersCompletion = (Completion<[User]>) -> Void
typealias LostFollowersCompletion = (Completion<[User]>) -> Void
typealias GainedFollowersCompletion = (Completion<[User]>) -> Void
typealias YouDontFollowCompletion = (Completion<[User]>) -> Void
typealias UnfollowersCompletion = (Completion<[User]>) -> Void
typealias BlockedAccountsCompletion = (Completion<[String]>) -> Void
typealias SuggestionsCompletion = (Completion<[User]>) -> Void
typealias FetchCompletion = (Completion<[(step: DataPart, time: Date)]>) -> Void

class MainViewModel {
    
    private let dushboardItems: [DushboardItem] = [
        DushboardItem(title: "top likers", type: .top_likers),
        DushboardItem(title: "top commenters", type: .top_commenters),
        DushboardItem(title: "lost followers", type: .lost_followers),
        DushboardItem(title: "gained followers", type: .gained_followers),
        DushboardItem(title: "you don't follow", type: .you_dont_follow),
        DushboardItem(title: "unfollowers", type: .unfollowers),
        DushboardItem(title: "blocked accounts", type: .blocked_by_you),
        DushboardItem(title: "recommendation", type: .recommendation)
    ]
    
//    private var mainScreenInfo: GraphProfile?
//    private var followRequests: FollowRequests?
//    private var posts: [GraphPost]?
//    private var followers: [GraphUser]?
//    private var following: [GraphUser]?
//    private var suggestedUsers: [GraphUser]?
//    private var monthHistoryUsers: [HistoryUser]?
//    private var blockedByYouUsernames: [String]?
//    
//    
//    
//    public func fetchData(profileInfoCompletion: ProfileInfoCompletion,
//                          topLikersCompletion: TopLikersCompletion,
//                          topCommentersCompletion: TopCommentersCompletion,
//                          lostFollowersCompletion: LostFollowersCompletion,
//                          gainedFollowersCompletion: GainedFollowersCompletion,
//                          youDontFollowCompletion: YouDontFollowCompletion,
//                          unfollowersCompletion: UnfollowersCompletion,
//                          blockedAccountsCompletion: BlockedAccountsCompletion,
//                          suggestionsCompletion: SuggestionsCompletion,
//                          completion: FetchCompletion,
//                          progress: @escaping (Double) -> Void) {
//        
//        mainScreenInfo = nil
//        followRequests = nil
//        posts = nil
//        followers = nil
//        following = nil
//        suggestedUsers = nil
//        monthHistoryUsers = nil
//        blockedByYouUsernames = nil
//        
//        func followersAndFollowingLoaded() {
//            
//        }
//        
//        ApiHelper.fetchInfoAsync(onProgressUpdate: progress,
//                                 onMainScreenInfoLoaded: { [weak self] graphProfile in
//                                    self?.mainScreenInfo = graphProfile
//                                    if let graphProfile = graphProfile {
//                                        profileInfoCompletion(.success(graphProfile))
//                                    }
//                                 },
//                                 onFollowRequestsLoaded: { [weak self] followRequests in
//                                    self?.followRequests = followRequests
//                                 },
//                                 onPostsLoaded: { [weak self] posts in
//                                    self?.posts = posts
//                                    let topLikers = UserModel.topLikers(self?.mainScreenInfo?.username, posts)
//                                    let topСommenters = UserModel.topCommenters(self?.mainScreenInfo?.username, posts)
//                                    topLikersCompletion(.success(topLikers))
//                                    topCommentersCompletion(.success(topСommenters))
//                                 },
//                                 onFollowersLoaded: { [weak self] followers in
//                                    self?.followers = followers
//                                    if self?.mainScreenInfo?.limitedDataDownloadMode == true {
//                                        lostFollowers = LimitedUserModel.lostFollowersApproxCount(follower_count)
//                                        gainedFollowers_count = LimitedUserModel.gainedFollowersApproxCount(follower_count)
//                                    } else {
//                                        let previousFollowersIds = PastFollowersManager.shared.getIds(userId)
//                                        let lostFollowersIds = UserModel.lostFollowersIds(previousFollowersIds, followers, monthHistoryUsers)
//                                        lostFollowers = lostFollowersIds.count
//                                    
//                                        let gainedFollowers = UserModel.gainedFollowers(previousFollowersIds, followers, monthHistoryUsers)
//                                        gainedFollowers_count = gainedFollowers.count
//                                    }
//                                 },
//                                 onFollowingLoaded: <#T##([GraphUser]?) -> Void#>,
//                                 onSuggestedUsersLoaded: { [weak self] suggestedUsers in
//                                    self?.suggestedUsers = suggestedUsers
//                                    suggestionsCompletion(.success(suggestedUsers ?? []))
//                                 },
//                                 onUserDirectSearchLoaded: { _ in },
//                                 onTopLikersFollowersLoaded: { _ in },
//                                 onMonthHistoryUsersLoaded: <#T##([HistoryUser]?) -> Void#>,
//                                 onBlockedUsersLoaded: { [weak self] blockedByYouUsernames in
//                                    self?.blockedByYouUsernames = blockedByYouUsernames
//                                    blockedAccountsCompletion(.success(blockedByYouUsernames ?? []))
//                                 },
//                                 onComplete: { fetchReport in
//                                    completion(.success(fetchReport))
//                                 },
//                                 onError: { error in
//                                    completion(.error(error))
//                                 })
//    }
    
}
