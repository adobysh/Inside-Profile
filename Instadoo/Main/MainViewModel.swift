//
//  MainViewModel.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 4/16/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import UIKit

enum DushboardItemType: String {
    case lost_followers
    case gained_followers
    case you_dont_follow
    case unfollowers
    case blocked_by_you
    case recommendation
    case top_likers
    case top_commenters
}

struct ProfileStateBundle: Codable {
    var mainScreenInfo: GraphProfile?
    var followRequests: FollowRequests?
    var posts: [GraphPost]?
    var followers: [GraphUser]?
    var following: [GraphUser]?
    var suggestedUsers: [GraphUser]?
    var monthHistoryUsers: [HistoryUser]?
    var blockedByYouUsernames: [String]?
    
    var limitedDataDownloadMode: Bool? { // "режиме ограниченного показа"
        return mainScreenInfo?.limitedDataDownloadMode
    }
    
    static let empty = ProfileStateBundle()
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

protocol MainViewModelDelegate: class {
    func viewModelDidEndFetching(timeReport: [(DataPart, Date)])
    func viewModelDidUpdateProgress(_ progress: CGFloat)
    func viewModelDidUpdateDushboardItem(_ dushboardItem: DushboardItemType, value: String)
    func viewModelDidUpdateMainInfo(_ mainInfo: GraphProfile)
    func viewModelDidUpdateLikesCount(_ likersCount: Int)
    func viewModelDidUpdateCommentsCount(_ commentsCount: Int)
    func viewModelDidError(_ error: Error)
}

class MainViewModel {
    
    public weak var delegate: MainViewModelDelegate?
    
    public var state: ProfileStateBundle = .empty // todo: make private after refactor
    
    private var likes: Int = 0
    private var comments: Int = 0
    private var lostFollowers_count: Int = 0
    private var gainedFollowers_count: Int = 0
    private var youDontFollow_count: Int = 0
    private var unfollowers_count: Int = 0
    private var topLikers_count: Int = 0
    private var topCommenters_count: Int = 0
    
    init(delegate: MainViewModelDelegate) {
        self.delegate = delegate
    }
    
    public func logOut() {
        state = .empty
    }
    
    public func fetchInfo(completion: (() -> Void)? = nil) {
        if let profileStateBundle = ProfileStateBundleManager().load() {
            state = profileStateBundle
            
            DispatchQueue.global().async {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.viewModelDidUpdateProgress(CGFloat(50))
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                if let mainInfo = profileStateBundle.mainScreenInfo {
                    self?.delegate?.viewModelDidUpdateMainInfo(mainInfo)
                }
                
                UserModel.topLikers(self?.state.mainScreenInfo?.username, self?.state.posts) { topLikers in
                    self?.topLikers_count = topLikers.count
                    self?.delegate?.viewModelDidUpdateDushboardItem(.top_likers, value: topLikers.count.bigBeauty)
                }
                UserModel.topCommenters(self?.state.mainScreenInfo?.username, self?.state.posts) { topСommenters in
                    self?.topCommenters_count = topСommenters.count
                    self?.delegate?.viewModelDidUpdateDushboardItem(.top_commenters, value: topСommenters.count.bigBeauty)
                }
                
                UserModel.likeCount(posts: self?.state.posts) { likes in
                    self?.likes = likes ?? 0
                    self?.delegate?.viewModelDidUpdateLikesCount(likes ?? 0)
                }
                UserModel.commentCount(posts: self?.state.posts) { comments in
                    self?.comments = comments ?? 0
                    self?.delegate?.viewModelDidUpdateCommentsCount(comments ?? 0)
                }
                
                tryToUpdate_youDontFollow_n_unfollowers()
                tryToUpdate_lost_followers_n_gained_followers()
                
                self?.delegate?.viewModelDidUpdateDushboardItem(.recommendation, value: (self?.state.suggestedUsers?.count ?? 0).bigBeauty)
                
                self?.delegate?.viewModelDidUpdateDushboardItem(.blocked_by_you, value: (self?.state.blockedByYouUsernames?.count ?? 0).bigBeauty)
                
                self?.delegate?.viewModelDidEndFetching(timeReport: [])
                
                completion?()
            }
            
            return
        }
        
        
        func tryToUpdate_youDontFollow_n_unfollowers() {
            guard state.limitedDataDownloadMode == true || state.followers != nil && state.following != nil else {
                return
            }
            
            if state.limitedDataDownloadMode == true {
                let youDontFollow = LimitedUserModel.youDontFollowApproxCount(followerCount: state.mainScreenInfo?.follower_count, followingCount: state.mainScreenInfo?.following_count) ?? 0
                self.youDontFollow_count = youDontFollow
                delegate?.viewModelDidUpdateDushboardItem(.you_dont_follow, value: "≈ \(youDontFollow)")
            } else {
                UserModel.youDontFollow(followers: state.followers, following: state.following) { [weak self] youDontFollow in
                    self?.youDontFollow_count = youDontFollow.count
                    self?.delegate?.viewModelDidUpdateDushboardItem(.you_dont_follow, value: youDontFollow.count.bigBeauty)
                }
            }
            
            if state.limitedDataDownloadMode == true {
                let unfollowers = LimitedUserModel.unfollowersApproxCount(followingCount: state.mainScreenInfo?.following_count) ?? 0
                self.unfollowers_count = unfollowers
                delegate?.viewModelDidUpdateDushboardItem(.unfollowers, value: "≈ \(unfollowers)")
            } else {
                UserModel.unfollowers(followers: state.followers, following: state.following) { [weak self] unfollowers in
                    self?.unfollowers_count = unfollowers.count
                    self?.delegate?.viewModelDidUpdateDushboardItem(.unfollowers, value: unfollowers.count.bigBeauty)
                }
            }
        }
        
        func tryToUpdate_lost_followers_n_gained_followers() {
            guard state.limitedDataDownloadMode == true || state.followers != nil && state.monthHistoryUsers != nil else {
                return
            }
            
            guard let userId = self.state.mainScreenInfo?.id else { return }
            
            if self.state.limitedDataDownloadMode == true {
                let lostFollowersCount = LimitedUserModel.lostFollowersApproxCount(self.state.mainScreenInfo?.follower_count) ?? 0
                self.lostFollowers_count = lostFollowersCount
                self.delegate?.viewModelDidUpdateDushboardItem(.lost_followers, value: "≈ \(lostFollowersCount.bigBeauty)")
            } else {
                let previousFollowersIds = PastFollowersManager.shared.getIds(userId)
                UserModel.lostFollowersIds(previousFollowersIds, self.state.followers, self.state.monthHistoryUsers) { [weak self] lostFollowersIds in
                    self?.lostFollowers_count = lostFollowersIds.count
                    self?.delegate?.viewModelDidUpdateDushboardItem(.lost_followers, value: lostFollowersIds.count.bigBeauty)
                }
            }
    
            if self.state.limitedDataDownloadMode == true {
                let gainedFollowersCount = LimitedUserModel.gainedFollowersApproxCount(self.state.mainScreenInfo?.follower_count) ?? 0
                self.gainedFollowers_count = gainedFollowersCount
                self.delegate?.viewModelDidUpdateDushboardItem(.gained_followers, value: "≈ \(gainedFollowersCount.bigBeauty)")
            } else {
                let previousFollowersIds = PastFollowersManager.shared.getIds(userId)
                UserModel.gainedFollowers(previousFollowersIds, self.state.followers, self.state.monthHistoryUsers) { [weak self] gainedFollowers in
                    self?.gainedFollowers_count = gainedFollowers.count
                    self?.delegate?.viewModelDidUpdateDushboardItem(.gained_followers, value: gainedFollowers.count.bigBeauty)
                }
            }
        }
        
        state = .empty
        
        ApiHelper.fetchInfoAsync(onProgressUpdate: { [weak self] progress in
            self?.delegate?.viewModelDidUpdateProgress(CGFloat(progress * 100))
            
        }, onMainScreenInfoLoaded: { [weak self] mainScreenInfo in
            self?.state.mainScreenInfo = mainScreenInfo
            if let mainInfo = mainScreenInfo {
                self?.delegate?.viewModelDidUpdateMainInfo(mainInfo)
            }
        }, onFollowRequestsLoaded: { [weak self] followRequests in
            self?.state.followRequests = followRequests
            
        }, onPostsLoaded: { [weak self] posts in
            self?.state.posts = posts
            UserModel.topLikers(self?.state.mainScreenInfo?.username, self?.state.posts) { topLikers in
                self?.topLikers_count = topLikers.count
                self?.delegate?.viewModelDidUpdateDushboardItem(.top_likers, value: topLikers.count.bigBeauty)
            }
            UserModel.topCommenters(self?.state.mainScreenInfo?.username, self?.state.posts) { topСommenters in
                self?.topCommenters_count = topСommenters.count
                self?.delegate?.viewModelDidUpdateDushboardItem(.top_commenters, value: topСommenters.count.bigBeauty)
            }
            
            UserModel.likeCount(posts: self?.state.posts) { likes in
                self?.likes = likes ?? 0
                self?.delegate?.viewModelDidUpdateLikesCount(likes ?? 0)
            }
            UserModel.commentCount(posts: self?.state.posts) { comments in
                self?.comments = comments ?? 0
                self?.delegate?.viewModelDidUpdateCommentsCount(comments ?? 0)
            }
            
        }, onFollowersLoaded: { [weak self] followers in
            self?.state.followers = followers
            
            tryToUpdate_youDontFollow_n_unfollowers()
            tryToUpdate_lost_followers_n_gained_followers()
            
        }, onFollowingLoaded: { [weak self] following in
            self?.state.following = following
            tryToUpdate_youDontFollow_n_unfollowers()
            
        }, onSuggestedUsersLoaded: { [weak self] suggestedUsers in
            self?.state.suggestedUsers = suggestedUsers
            self?.delegate?.viewModelDidUpdateDushboardItem(.recommendation, value: (suggestedUsers?.count ?? 0).bigBeauty)
            
        }, onUserDirectSearchLoaded: { _ in
        }, onTopLikersFollowersLoaded: { _ in
        }, onMonthHistoryUsersLoaded: { [weak self] monthHistoryUsers in
            self?.state.monthHistoryUsers = monthHistoryUsers
            
            tryToUpdate_lost_followers_n_gained_followers()
            
        }, onBlockedUsersLoaded: { [weak self] blockedUsers in
            self?.state.blockedByYouUsernames = blockedUsers
            self?.delegate?.viewModelDidUpdateDushboardItem(.blocked_by_you, value: (blockedUsers?.count ?? 0).bigBeauty)
            
        }, onComplete: { [weak self] timeReport in
            self?.delegate?.viewModelDidEndFetching(timeReport: timeReport)
            
            if let profileStateBundle = self?.state {
                ProfileStateBundleManager().save(profileStateBundle)
            }
            
            completion?()
            
        }) { [weak self] error in
            self?.delegate?.viewModelDidError(error)
            
            completion?()
        }
        
        logAnalytics()
    }
    
    private func logAnalytics() {
        if let follower_count = state.followers?.count,
            let following_count = state.following?.count,
            let recomendation = state.suggestedUsers?.count {
            AppAnalytics.setValues(followers: follower_count,
                                   following: following_count,
                                   likes: likes,
                                   comments: comments,
                                   lostFollowers: lostFollowers_count,
                                   gainedFollowers: gainedFollowers_count,
                                   youDontFollow: youDontFollow_count,
                                   unfollowers: unfollowers_count,
                                   profileViewers: 0 /* newGuests_count */,
                                   recomendation: recomendation,
                                   topLikers: topLikers_count,
                                   topCommenters: topCommenters_count)
        }
    }
    
}
