//
//  ViewController.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 7/8/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit
import Alamofire
import MBCircularProgressBar

class MainViewController: UIViewController {
    
    @IBOutlet var avatarImageView: UIImageView?
    @IBOutlet var followersCountLabel: UILabel?
    @IBOutlet var followingCountLabel: UILabel?
    @IBOutlet var likesCountLabel: UILabel?
    @IBOutlet var commentsCountLabel: UILabel?
    @IBOutlet var loginLabel: UILabel?
    @IBOutlet var superButtons: [ActivityIndicatorButton]?
    
    @IBOutlet var lostFollowersButton: ActivityIndicatorButton?
    @IBOutlet var gainedFollowersButton: ActivityIndicatorButton?
    @IBOutlet var youDontFollowButton: ActivityIndicatorButton?
    @IBOutlet var unfollowersButton: ActivityIndicatorButton?
    @IBOutlet var newGuestsButton: ActivityIndicatorButton?
    @IBOutlet var recomendationButton: ActivityIndicatorButton?
    @IBOutlet var topLikersButton: ActivityIndicatorButton?
    @IBOutlet var topCommentersButton: ActivityIndicatorButton?
    
    @IBOutlet var scrollView: UIScrollView?
    @IBOutlet var circularProgressView: MBCircularProgressBarView?
    private var blurEffectView: UIVisualEffectView?
    private var spinner: UIActivityIndicatorView?
    
    private var mainScreenInfo: ProfileInfoData?
    private var followRequests: FollowRequests?
    private var posts: [PostData]?
    private var followers: [ApiUser]?
    private var following: [ApiUser]?
    private var suggestedUsers: [GraphUser]?
    private var userDirectSearch: [ApiUser]?
    private var topLikersFollowers: [ApiUser]?
    private var monthHistoryUsers: [HistoryUser]?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.scale()
        
        setupLoadingBlur()
        fetchDataOrAuthorization() { [weak self] in
            self?.dismissLoadingBlur()
        }
        
        updateUI(progress: 0)
        superButtons?.forEach { button in
            button.addTapGestureRecognizer { [weak self] in
                self?.detailButtonAction(button)
            }
        }
        
        setupRefreshControl()
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear
    }
    
    private func fetchDataOrAuthorization(onSuccess: (()->())? = nil) {
        AuthorizationManager.shared.isAuthorized(onResult: { [weak self] (error, isAuthorized) in
            if let _ = error {
                self?.showErrorAlert() { [weak self] in
                    self?.fetchDataOrAuthorization(onSuccess: onSuccess)
                }
            } else {
                if isAuthorized == true {
                    AppAnalytics.logDashboardOpen()
                    self?.fetchInfo()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                        let vc = UIViewController.getStarted
                        vc.onAuthorizationSuccess = { [weak self] in
                            AppAnalytics.logDashboardOpen()
                            self?.fetchInfo()
                        }
                        let nv = UINavigationController(rootViewController: vc)
                        nv.modalPresentationStyle = .fullScreen
                        self?.present(nv, animated: false)
                    }
                }
                onSuccess?()
            }
        })
    }
    
    private func setupLoadingBlur() {
        let blurEffect = UIBlurEffect(style: .extraLight)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        spinner = UIActivityIndicatorView(style: .gray)
        
        guard let blurEffectView = blurEffectView, let spinner = spinner else { return }
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        
        view.addSubview(spinner)
        spinner.center = view.center
        spinner.startAnimating()
    }
    
    private func dismissLoadingBlur() {
        blurEffectView?.removeFromSuperview()
        spinner?.stopAnimating()
        spinner?.removeFromSuperview()
    }
    
    @objc func handleRefreshControl() {
        // защита от двойного запуска обновления
        guard (superButtons?.filter { $0.inProgress } ?? []).isEmpty == true else {
            scrollView?.refreshControl?.endRefreshing()
            return
        }
        
        fetchDataOrAuthorization() { [weak self] in
            self?.scrollView?.refreshControl?.endRefreshing()
        }
    }
    
    @IBAction func settingsButtonAction(_ sender: Any) {
        let vc = UIViewController.settings
        vc.onLogOut = { [weak self] in
            self?.mainScreenInfo = nil
            self?.followRequests = nil
            self?.posts = nil
            self?.followers = nil
            self?.following = nil
            self?.suggestedUsers = nil
            self?.userDirectSearch = nil
            self?.topLikersFollowers = nil
            self?.monthHistoryUsers = nil
            self?.updateUI()
            
            let vc = UIViewController.getStarted
            vc.onAuthorizationSuccess = { [weak self] in
                self?.fetchInfo()
            }
            let nv = UINavigationController(rootViewController: vc)
            nv.modalPresentationStyle = .fullScreen
            self?.present(nv, animated: true, completion: nil)
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func detailButtonAction(_ sender: ActivityIndicatorButton) {
        guard let contentType: ContentType = ContentType(rawValue: sender.tag) else { return }
        
        let eventSource: EventSource
        let eventButton: EventButton
        switch contentType {
        case .gained_followers:
            eventSource = .gained_followers
            eventButton = .gained_followers
        case .lost_followers:
            eventSource = .lost_followers
            eventButton = .lost_followers
        case .you_dont_follow:
            eventSource = .you_dont_follow
            eventButton = .you_dont_follow
        case .unfollowers:
            eventSource = .unfollowers
            eventButton = .unfollowers
        case .new_guests:
            eventSource = .new_guests
            eventButton = .new_guests
        case .recommendation:
            eventSource = .recommendation
            eventButton = .recommendation
        case .top_commenters:
            eventSource = .top_commenters
            eventButton = .top_commenters
        case .top_likers:
            eventSource = .top_likers
            eventButton = .top_likers
        }
        AppAnalytics.logClick(button: eventButton, isDisabled: sender.inProgress)
        
        guard !sender.inProgress else { return }
        
        if !SubscriptionKeychain.isSubscribed()
            && (contentType == .new_guests
            || contentType == .recommendation
            || contentType == .top_commenters
            || contentType == .top_likers)
        {
            let vc = UIViewController.vip
            vc.source = eventSource
            vc.onClose = {
                vc.dismiss(animated: true)
            }
            vc.onPaymentSuccess = { [weak self] in
                vc.dismiss(animated: true)
                
                if SubscriptionKeychain.isSubscribed() {
                    self?.openDetailScreen(contentType)
                }
            }
            present(vc, animated: true)
        } else {
            openDetailScreen(contentType)
        }
    }
    
    private func openDetailScreen(_ contentType: ContentType) {
        let vc = UIViewController.detail
        vc.contentType = contentType
        vc.mainScreenInfo = mainScreenInfo
        vc.followRequests = followRequests
        vc.posts = posts
        vc.following = following
        vc.followers = followers
        vc.suggestedUsers = suggestedUsers
        vc.userDirectSearch = userDirectSearch
        vc.topLikersFollowers = topLikersFollowers
        vc.monthHistoryUsers = monthHistoryUsers
        vc.onFollow = { [weak self] onUpdate in
            let onError: (Error)->() = { error in onUpdate?(error) }
            
            ApiManager.shared.getFollowings(onComplete: { [weak self] following in
                ApiManager.shared.getFollowRequests(onComplete: { [weak self] followRequests in
                    self?.following = following
                    self?.followRequests = followRequests
                    vc.following = following
                    vc.followRequests = followRequests
                    self?.updateUI()
                    onUpdate?(nil)
                }, onError: onError)
            }, onError: onError)
        }
        vc.onUpdate = { [weak self] onUpdate in
            let onError: (Error)->() = { _ in onUpdate?() }
            
            let onComplete: ()->() = { [weak self] in
                self?.updateUI()
                onUpdate?()
            }
            
            switch contentType {
            case .lost_followers, .gained_followers:
                guard let userId = self?.mainScreenInfo?.id else { onComplete(); return }
                ApiManager.shared.getAllFollowers(userId: userId, onComplete: { [weak self] followers in
                    self?.followers = followers
                    vc.followers = followers
                    onComplete()
                }, onError: onError)
            case .you_dont_follow, .unfollowers:
                guard let userId = self?.mainScreenInfo?.id else { onComplete(); return }
                ApiManager.shared.getAllFollowers(userId: userId, onComplete: { [weak self] followers in
                    ApiManager.shared.getFollowings(onComplete: { [weak self] following in
                        self?.followers = followers
                        self?.following = following
                        vc.followers = followers
                        vc.following = following
                        onComplete()
                    }, onError: onError)
                }, onError: onError)
            case .new_guests:
                ApiManager.shared.getUserDirectSearch(onComplete: { [weak self] userDirectSearch in
                    self?.userDirectSearch = userDirectSearch
                    vc.userDirectSearch = userDirectSearch
                    onComplete()
                }, onError: onError)
            case .recommendation:
                ApiManager.shared.getGoodSuggestedUser(onComplete: { [weak self] goodSuggestedUser in
                    self?.suggestedUsers = goodSuggestedUser
                    vc.suggestedUsers = goodSuggestedUser
                    onComplete()
                }, onError: onError)
            case .top_likers, .top_commenters:
                ApiManager.shared.getPosts(onComplete: { [weak self] posts in
                    self?.posts = posts
                    vc.posts = posts
                    onComplete()
                }, onError: onError)
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func setProgress(_ value: CGFloat) {
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            self?.circularProgressView?.value = value
        })
        
        if value == 100 || value == 0 {
            UIView.animate(withDuration: 0.3, delay: 1.0, animations: { [weak self] in
                self?.circularProgressView?.alpha = 0
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                self?.circularProgressView?.alpha = 1
            })
        }
    }
    
}

// MARK: - Setup
extension MainViewController {
    
    func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .white
        scrollView?.refreshControl = refreshControl
        scrollView?.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
    }
    
}

// MARK: - Update UI
extension MainViewController {
    
    func updateUI(progress: CGFloat? = nil) {
        if let progress = progress {
            setProgress(progress)
        }
        
        let follower_count: Int? = mainScreenInfo?.follower_count
        let following_count: Int? = mainScreenInfo?.following_count
        let likes: Int? = UserModel.likeCount(posts: posts)
        let comments: Int? = UserModel.commentCount(posts: posts)
        var lostFollowers: Int? = nil
        var gainedFollowers_count: Int? = nil
        var newGuests_count: Int? = nil
        if let userId = mainScreenInfo?.id {
            let previousFollowersIds = PastFollowersManager.shared.getIds(userId)
            let lostFollowersIds = UserModel.lostFollowersIds(previousFollowersIds, followers, monthHistoryUsers)
            lostFollowers = lostFollowersIds.count
            
            let gainedFollowers = UserModel.gainedFollowers(previousFollowersIds, followers, monthHistoryUsers)
            gainedFollowers_count = gainedFollowers.count
            
            let newGuests = UserModel.newGuests(userId, mainScreenInfo?.username, userDirectSearch, topLikersFollowers, suggestedUsers, following, followers)
            newGuests_count = newGuests.guests?.count ?? newGuests.guestsIds?.count
        }
        let youDontFollow = UserModel.youDontFollow(followers: followers, following: following)
        let youDontFollow_count: Int? = youDontFollow.count
        let unfollowers = UserModel.unfollowers(followers: followers, following: following)
        let unfollowers_count: Int? = unfollowers.count
        let recomendation: Int? = suggestedUsers?.count
        let topLikers = UserModel.topLikers(mainScreenInfo?.username, posts)
        let topLikers_count: Int? = topLikers.count
        let topСommenters = UserModel.topCommenters(mainScreenInfo?.username, posts)
        let topCommenters_count: Int? = topСommenters.count
        
        updateMainInfo(follower_count: follower_count, following_count: following_count)
        updateLikeCount(likesCount: likes)
        updateCommentCount(commentsCount: comments)
        updateButtons()
        
        if let follower_count = follower_count,
                let following_count = following_count,
                let likes = likes,
                let comments = comments,
                let lostFollowers = lostFollowers,
                let gainedFollowers_count = gainedFollowers_count,
                let youDontFollow_count = youDontFollow_count,
                let unfollowers_count = unfollowers_count,
                let newGuests_count = newGuests_count,
                let recomendation = recomendation,
                let topLikers_count = topLikers_count,
                let topCommenters_count = topCommenters_count {
            AppAnalytics.setValues(followers: follower_count, following: following_count, likes: likes, comments: comments, lostFollowers: lostFollowers, gainedFollowers: gainedFollowers_count, youDontFollow: youDontFollow_count, unfollowers: unfollowers_count, profileViewers: newGuests_count, recomendation: recomendation, topLikers: topLikers_count, topCommenters: topCommenters_count)
        }
    }
    
    func updateMainInfo(follower_count: Int?, following_count: Int?) {
        followersCountLabel?.text = "\(follower_count?.bigBeauty ?? "0")"
        followingCountLabel?.text = "\(following_count?.bigBeauty ?? "0")"
        navigationItem.title = mainScreenInfo?.full_name
        if let username = mainScreenInfo?.username {
            loginLabel?.text = "@" + username
        } else {
            loginLabel?.text = nil
        }
        
        let bestQualityAvatarUrl = mainScreenInfo?.hd_profile_pic_url_info?.url ?? mainScreenInfo?.profile_pic_url
        UIImage.load(bestQualityAvatarUrl) { [weak self] image, url in
            self?.avatarImageView?.imageWithFade = image
        }
    }
    
    func updateLikeCount(likesCount: Int?) {
        likesCountLabel?.text = likesCount?.bigBeauty ?? "0"
    }
    
    func updateCommentCount(commentsCount: Int?) {
        commentsCountLabel?.text = commentsCount?.bigBeauty ?? "0"
    }
    
    func updateButtons() {
        superButtons?.forEach { button in
            guard let contentType: ContentType = ContentType(rawValue: button.tag) else { return }
            switch contentType {
            case .lost_followers:
                guard let userId = mainScreenInfo?.id else { return }
                let previousFollowersIds = PastFollowersManager.shared.getIds(userId)
                let lostFollowersIds = UserModel.lostFollowersIds(previousFollowersIds, followers, monthHistoryUsers)
                button.value = lostFollowersIds.count.bigBeauty
            case .gained_followers:
                guard let userId = mainScreenInfo?.id else { return }
                let previousFollowersIds = PastFollowersManager.shared.getIds(userId)
                let gainedFollowers = UserModel.gainedFollowers(previousFollowersIds, followers, monthHistoryUsers)
                button.value = gainedFollowers.count.bigBeauty
            case .you_dont_follow:
                let youDontFollow = UserModel.youDontFollow(followers: followers, following: following)
                button.value = youDontFollow.count.bigBeauty
            case .unfollowers:
                let unfollowers = UserModel.unfollowers(followers: followers, following: following)
                button.value = unfollowers.count.bigBeauty
            case .new_guests:
                guard let userId = mainScreenInfo?.id else { return }
                let newGuests = UserModel.newGuests(userId, mainScreenInfo?.username, userDirectSearch, topLikersFollowers, suggestedUsers, following, followers)
                if let newGuestsCount = newGuests.guests?.count {
                    button.value = newGuestsCount.bigBeauty
                } else {
                    button.value = (newGuests.guestsIds?.count ?? 0).bigBeauty
                }
            case .recommendation:
                button.value = (suggestedUsers?.count ?? 0).bigBeauty
            case .top_likers:
                let topLikers = UserModel.topLikers(mainScreenInfo?.username, posts)
                button.value = topLikers.count.bigBeauty
            case .top_commenters:
                let topСommenters = UserModel.topCommenters(mainScreenInfo?.username, posts)
                button.value = topСommenters.count.bigBeauty
            }
        }
    }
    
}

// MARK: - Info Fetching
extension MainViewController {
    
    func fetchInfo() {
        let onError: (Error)->() = { [weak self] error in
            self?.showErrorAlert() { [weak self] in
                self?.fetchDataOrAuthorization()
            }
            self?.superButtons?.forEach { $0.inProgress = false }
            self?.setProgress(0)
        }
        
        superButtons?.forEach { $0.inProgress = true }
        
        setProgress(10)
        
        ApiManager.shared.getProfileInfoAndPosts(onComplete: { [weak self] result in
            self?.mainScreenInfo = result.profileInfo
            self?.posts = result.postDataArray
            self?.updateUI(progress: 20)
            
            guard let userId = result.profileInfo.id else { onError(ApiError.nilValue); return }
            ApiManager.shared.getAllFollowers(userId: userId, onComplete: { [weak self] followers in
                self?.followers = followers
                ApiManager.shared.getMonthHistoryUsers(onComplete: { [weak self] monthHistoryUsers in
                    self?.monthHistoryUsers = monthHistoryUsers
                    self?.updateUI(progress: 40)
                    
                    self?.lostFollowersButton?.inProgress = false
                    self?.gainedFollowersButton?.inProgress = false
                    
                    ApiManager.shared.getFollowings(onComplete: { [weak self] following in
                        self?.following = following
                        self?.updateUI(progress: 60)
                        
                        self?.youDontFollowButton?.inProgress = false
                        self?.unfollowersButton?.inProgress = false
                        
                        ApiManager.shared.getGoodSuggestedUser(onComplete: { [weak self] suggestedUsers in
                            self?.suggestedUsers = suggestedUsers
                            self?.updateUI(progress: 80)
                            
                            self?.recomendationButton?.inProgress = false
                            
                            ApiManager.shared.getFollowRequests(onComplete: { [weak self] followRequests in
                                self?.followRequests = followRequests
                                ApiManager.shared.getUserDirectSearch(onComplete: { [weak self] userDirectSearch in
                                    self?.userDirectSearch = userDirectSearch
                                    self?.updateUI(progress: 90)
                                    
                                    guard let userId = self?.mainScreenInfo?.id else { onError(ApiError.nilValue); return }
                                    if GuestsManager.shared.containIds(userId) {
                                        self?.updateUI(progress: 100)
                                        self?.superButtons?.forEach { $0.inProgress = false }
                                    } else {
                                        let topLikers = UserModel.topLikers(self?.mainScreenInfo?.username, self?.posts)
                                        ApiManager.shared.getTopLikersFriends(myId: self?.mainScreenInfo?.id, topLikers: topLikers, onComplete: { [weak self] topLikersFollowers in
                                            self?.topLikersFollowers = topLikersFollowers
                                            
                                            self?.updateUI(progress: 100)
                                            self?.superButtons?.forEach { $0.inProgress = false }
                                        }, onError: onError)
                                    }
                                }, onError: onError)
                            }, onError: onError)
                        }, onError: onError)
                    }, onError: onError)
                }, onError: onError)
            }, onError: onError)
        }, onError: onError)
    }
    
}
