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
    
    @IBOutlet var textProgressLabel: UILabel?
    @IBOutlet var avatarImageView: UIImageView?
    @IBOutlet var avatarBlur: UIVisualEffectView?
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
    @IBOutlet var blockedUsersButton: ActivityIndicatorButton?
    @IBOutlet var recomendationButton: ActivityIndicatorButton?
    @IBOutlet var topLikersButton: ActivityIndicatorButton?
    @IBOutlet var topCommentersButton: ActivityIndicatorButton?
    
    @IBOutlet var scrollView: UIScrollView?
    @IBOutlet var circularProgressView: MBCircularProgressBarView?
    private var blurEffectView: UIVisualEffectView?
    private var spinner: UIActivityIndicatorView?
    
    private var mainScreenInfo: GraphProfile?
    private var followRequests: FollowRequests?
    private var posts: [GraphPost]?
    private var followers: [GraphUser]?
    private var following: [GraphUser]?
    private var suggestedUsers: [GraphUser]?
//    private var userDirectSearch: [BaseUser]?
//    private var topLikersFollowers: [GraphUser]?
    private var monthHistoryUsers: [HistoryUser]?
    private var blockedByYouUsernames: [String]?
    
    private var limitedDataDownloadMode: Bool? { // "режиме ограниченного показа"
        return mainScreenInfo?.limitedDataDownloadMode
    }
    
    private let viewModel = MainViewModel()
    
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
        AuthorizationManager.shared.isAuthorized(completion: { [weak self] result in
            if let error = result.error {
                self?.showErrorAlert(error) { [weak self] in
                    self?.fetchDataOrAuthorization(onSuccess: onSuccess)
                }
            } else {
                if let isAuthorized = result.value, isAuthorized {
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
            self?.monthHistoryUsers = nil
            self?.blockedByYouUsernames = nil
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
        let contentType: DushboardItemType
        switch sender.descriptionLabel?.text {
        case "top likers":
            contentType = .top_likers
        case "top commenters":
            contentType = .top_commenters
        case "lost followers":
            contentType = .lost_followers
        case "gained followers":
            contentType = .gained_followers
        case "you don't follow":
            contentType = .you_dont_follow
        case "unfollowers":
            contentType = .unfollowers
        case "blocked accounts":
            contentType = .blocked_by_you
        case "recommendation":
            contentType = .recommendation
        default:
            contentType = .recommendation
        }
        
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
        case .blocked_by_you:
            eventSource = .blocked_by_you
            eventButton = .blocked_by_you
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
            && (contentType == .blocked_by_you
            || contentType == .recommendation)
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
    
    private func openDetailScreen(_ contentType: DushboardItemType) {
        let vc = UIViewController.detail
        vc.limitedDataDownloadMode = limitedDataDownloadMode
        vc.contentType = contentType
        vc.mainScreenInfo = mainScreenInfo
        vc.followRequests = followRequests
        vc.posts = posts
        vc.following = following
        vc.followers = followers
        vc.suggestedUsers = suggestedUsers
        vc.monthHistoryUsers = monthHistoryUsers
        vc.blockedByYouUsernames = blockedByYouUsernames
        vc.onFollow = { [weak self] onUpdate in
            let onError: (Error)->() = { error in onUpdate?(error) }
            
            GraphRoutes.getUserFollowings(limited: self?.limitedDataDownloadMode == true, id: self?.mainScreenInfo?.id ?? "", onSubpartLoaded: { _ in }, completion: { [weak self] result in
                guard let following = result.value else {
                    onError(result.error ?? ErrorModel(file: #file, function: #function, line: #line))
                    return
                }
                
                GraphRoutes.getFollowRequests(completion: { [weak self] result in
                    if let error = result.error {
                        onError(error)
                        return
                    }
                    
                    guard let followRequests = result.value else { return }
                    self?.following = following
                    self?.followRequests = followRequests
                    vc.following = following
                    vc.followRequests = followRequests
                    self?.updateUI()
                    onUpdate?(nil)
                })
            })
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
                GraphRoutes.getAllFollowers(limited: self?.limitedDataDownloadMode == true, id: userId, onSubpartLoaded: { _ in }, completion: { [weak self] result in
                    if let error = result.error {
                        onError(error)
                        return
                    }
                    
                    let followers = result.value
                    self?.followers = followers
                    vc.followers = followers
                    onComplete()
                })
            case .you_dont_follow, .unfollowers:
                guard let userId = self?.mainScreenInfo?.id else { onComplete(); return }
                GraphRoutes.getAllFollowers(limited: self?.limitedDataDownloadMode == true, id: userId, onSubpartLoaded: { _ in }, completion: { [weak self] result in
                    if let error = result.error {
                        onError(error)
                        return
                    }
                    
                    let followers = result.value
                    GraphRoutes.getUserFollowings(limited: self?.limitedDataDownloadMode == true, id: userId, onSubpartLoaded: { _ in }, completion: { [weak self] result in
                        if let error = result.error {
                            onError(error)
                            return
                        }
                        
                        let following = result.value
                        self?.followers = followers
                        self?.following = following
                        vc.followers = followers
                        vc.following = following
                        onComplete()
                    })
                })
//            case .new_guests:
//                GraphRoutes.getUserDirectSearch(onComplete: { [weak self] userDirectSearch in
//                    self?.userDirectSearch = userDirectSearch
//                    vc.userDirectSearch = userDirectSearch
//                    onComplete()
//                }, onError: onError)
            case .blocked_by_you:
                GraphRoutes.getBlockedUsersUsernames(userName: self?.mainScreenInfo?.username ?? "", completion: { [weak self] result in
                    if let error = result.error {
                        onError(error)
                        return
                    }
                    
                    let blockedUsersUsernames = result.value
                    self?.blockedByYouUsernames = blockedUsersUsernames
                    vc.blockedByYouUsernames = blockedUsersUsernames
                    onComplete()
                })
            case .recommendation:
                GraphRoutes.getGoodSuggestedUser(completion: { [weak self] result in
                    if let error = result.error {
                        onError(error)
                        return
                    }
                    
                    let goodSuggestedUser = result.value
                    self?.suggestedUsers = goodSuggestedUser
                    vc.suggestedUsers = goodSuggestedUser
                    onComplete()
                })
            case .top_likers, .top_commenters:
                GraphRoutes.getPosts(id: self?.mainScreenInfo?.id ?? "", onSubpartLoaded: { _, _ in }, completion: { [weak self] result in
                    if let error = result.error {
                        onError(error)
                        return
                    }
                    
                    let posts = result.value
                    self?.posts = posts
                    vc.posts = posts
                    onComplete()
                })
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func setProgress(_ value: CGFloat) {
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            self?.circularProgressView?.value = value
            self?.textProgressLabel?.text = "\(String(format: "%.1f", value))%\nloading..."
        })
        
        if value == 100 || value == 0 {
            UIView.animate(withDuration: 0.3, delay: 1.0, animations: { [weak self] in
                self?.circularProgressView?.alpha = 0
                self?.textProgressLabel?.alpha = 0
                self?.avatarBlur?.alpha = 0
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                self?.circularProgressView?.alpha = 1
                self?.textProgressLabel?.alpha = 1
                self?.avatarBlur?.alpha = 1
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
        var lostFollowers: Int?
        var gainedFollowers_count: Int?
//        var newGuests_count: Int?
        if let userId = mainScreenInfo?.id {
            if limitedDataDownloadMode == true {
                lostFollowers = LimitedUserModel.lostFollowersApproxCount(follower_count)
                gainedFollowers_count = LimitedUserModel.gainedFollowersApproxCount(follower_count)
            } else {
                let previousFollowersIds = PastFollowersManager.shared.getIds(userId)
                let lostFollowersIds = UserModel.lostFollowersIds(previousFollowersIds, followers, monthHistoryUsers)
                lostFollowers = lostFollowersIds.count
            
                let gainedFollowers = UserModel.gainedFollowers(previousFollowersIds, followers, monthHistoryUsers)
                gainedFollowers_count = gainedFollowers.count
            }
            
//            let newGuests = UserModel.newGuests(userId, mainScreenInfo?.username, userDirectSearch, topLikersFollowers, suggestedUsers, following, followers)
//            newGuests_count = newGuests.guests?.count ?? newGuests.guestsIds?.count
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
//                let newGuests_count = newGuests_count,
                let recomendation = recomendation,
                let topLikers_count = topLikers_count,
                let topCommenters_count = topCommenters_count {
            AppAnalytics.setValues(followers: follower_count, following: following_count, likes: likes, comments: comments, lostFollowers: lostFollowers, gainedFollowers: gainedFollowers_count, youDontFollow: youDontFollow_count, unfollowers: unfollowers_count, profileViewers: 0 /* newGuests_count */, recomendation: recomendation, topLikers: topLikers_count, topCommenters: topCommenters_count)
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
        
        let bestQualityAvatarUrl = mainScreenInfo?.profile_pic_url_hd ?? mainScreenInfo?.profile_pic_url
        UIImage.load(bestQualityAvatarUrl) { [weak self] image, url in
            self?.avatarImageView?.imageWithFade = image
        }
    }
    
    func updateLikeCount(likesCount: Int?) {
        let postsCount = (posts?.count ?? 0)
        let likesCountBigBeauty = likesCount?.bigBeauty ?? "0"
        likesCountLabel?.text = postsCount >= LIMITED_ANALYTICS_TOTAL_POSTS_COUNT ? "> \(likesCountBigBeauty)" : likesCountBigBeauty
    }
    
    func updateCommentCount(commentsCount: Int?) {
        let postsCount = (posts?.count ?? 0)
        let commentsCountBigBeauty = commentsCount?.bigBeauty ?? "0"
        commentsCountLabel?.text = postsCount >= LIMITED_ANALYTICS_TOTAL_POSTS_COUNT ? "> \(commentsCountBigBeauty)" : commentsCountBigBeauty
    }
    
    func updateButtons() {
        superButtons?.forEach { button in
            let contentType: DushboardItemType
            switch button.descriptionLabel?.text {
            case "top likers":
                contentType = .top_likers
            case "top commenters":
                contentType = .top_commenters
            case "lost followers":
                contentType = .lost_followers
            case "gained followers":
                contentType = .gained_followers
            case "you don't follow":
                contentType = .you_dont_follow
            case "unfollowers":
                contentType = .unfollowers
            case "blocked accounts":
                contentType = .blocked_by_you
            case "recommendation":
                contentType = .recommendation
            default:
                contentType = .recommendation
            }
            
            switch contentType {
            case .lost_followers:
                guard let userId = mainScreenInfo?.id else { return }
                if limitedDataDownloadMode == true {
                    let lostFollowersCount = LimitedUserModel.lostFollowersApproxCount(mainScreenInfo?.follower_count) ?? 0
                    button.value = "≈ \(lostFollowersCount)"    
                } else {
                    let previousFollowersIds = PastFollowersManager.shared.getIds(userId)
                    let lostFollowersIds = UserModel.lostFollowersIds(previousFollowersIds, followers, monthHistoryUsers)
                    button.value = lostFollowersIds.count.bigBeauty
                }
            case .gained_followers:
                guard let userId = mainScreenInfo?.id else { return }
                if limitedDataDownloadMode == true {
                    let gainedFollowersCount = LimitedUserModel.gainedFollowersApproxCount(mainScreenInfo?.follower_count) ?? 0
                    button.value = "≈ \(gainedFollowersCount)"
                } else {
                    let previousFollowersIds = PastFollowersManager.shared.getIds(userId)
                    let gainedFollowers = UserModel.gainedFollowers(previousFollowersIds, followers, monthHistoryUsers)
                    button.value = gainedFollowers.count.bigBeauty
                }
            case .you_dont_follow:
                if limitedDataDownloadMode == true {
                    let youDontFollow = LimitedUserModel.youDontFollowApproxCount(followerCount: mainScreenInfo?.follower_count, followingCount: mainScreenInfo?.following_count) ?? 0
                    button.value = "≈ \(youDontFollow)"
                } else {
                    let youDontFollow = UserModel.youDontFollow(followers: followers, following: following)
                    button.value = youDontFollow.count.bigBeauty
                }
            case .unfollowers:
                if limitedDataDownloadMode == true {
                    let unfollowers = LimitedUserModel.unfollowersApproxCount(followingCount: mainScreenInfo?.following_count) ?? 0
                    button.value = "≈ \(unfollowers)"
                } else {
                    let unfollowers = UserModel.unfollowers(followers: followers, following: following)
                    button.value = unfollowers.count.bigBeauty
                }
            case .blocked_by_you:
                if let blockedUsersCount = blockedByYouUsernames?.count {
                    button.value = blockedUsersCount.bigBeauty
                } else {
                    button.value = (blockedByYouUsernames?.count ?? 0).bigBeauty
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
        superButtons?.forEach { $0.inProgress = true }
        setProgress(1)
        
        ApiHelper.fetchInfoAsync(onProgressUpdate: { [weak self] progress in
            self?.updateUI(progress: CGFloat(progress * 100))
        }, onMainScreenInfoLoaded: { [weak self] mainScreenInfo in
            self?.mainScreenInfo = mainScreenInfo
        }, onFollowRequestsLoaded: { [weak self] followRequests in
            self?.followRequests = followRequests
        }, onPostsLoaded: { [weak self] posts in
            self?.posts = posts
            self?.topLikersButton?.inProgress = false
            self?.topCommentersButton?.inProgress = false
        }, onFollowersLoaded: { [weak self] followers in
            self?.followers = followers
        }, onFollowingLoaded: { [weak self] following in
            self?.following = following
            self?.youDontFollowButton?.inProgress = false
            self?.unfollowersButton?.inProgress = false
        }, onSuggestedUsersLoaded: { [weak self] suggestedUsers in
            self?.suggestedUsers = suggestedUsers
            self?.recomendationButton?.inProgress = false
        }, onUserDirectSearchLoaded: { [weak self] userDirectSearch in
//            self?.userDirectSearch = userDirectSearch
        }, onTopLikersFollowersLoaded: { [weak self] topLikersFollowers in
//            self?.topLikersFollowers = topLikersFollowers
        }, onMonthHistoryUsersLoaded: { [weak self] monthHistoryUsers in
            self?.monthHistoryUsers = monthHistoryUsers
            self?.lostFollowersButton?.inProgress = false
            self?.gainedFollowersButton?.inProgress = false
        }, onBlockedUsersLoaded: { [weak self] blockedUsers in
            self?.blockedByYouUsernames = blockedUsers
            self?.blockedUsersButton?.inProgress = false
        }, onComplete: { [weak self] timeReport in
            self?.superButtons?.forEach { $0.inProgress = false }
            self?.setProgress(100)
            #if DEBUG
                self?.showTimeReport(timeReport: timeReport)
            #endif
        }) { [weak self] error in
            self?.showErrorAlert(error) { [weak self] in
                self?.fetchDataOrAuthorization()
            }
            self?.superButtons?.forEach { $0.inProgress = false }
            self?.setProgress(0)
        }
    }
    
}

// MARK: - Time Report
extension MainViewController {
    
    func showTimeReport(timeReport: [(DataPart, Date)]) {
        var reportText = ""
        if let startTime = timeReport.first(where: { $0.0 == DataPart.start } )?.1 {
            timeReport.forEach { step in
                switch step.0 {
                case .start:
                    break
                case .profileInfo:
                    let seconds = String(format: "%.2f", CGFloat(step.1.timeIntervalSince(startTime)))
                    reportText = reportText + "\(seconds) - Профиль\n"
                case .posts:
                    let seconds = String(format: "%.2f", CGFloat(step.1.timeIntervalSince(startTime)))
                    reportText = reportText + "\(seconds) - Посты с лайками\n"
                case .followers:
                    let seconds = String(format: "%.2f", CGFloat(step.1.timeIntervalSince(startTime)))
                    reportText = reportText + "\(seconds) - Фолловеры\n"
                case .monthHistoryUsers:
                    let seconds = String(format: "%.2f", CGFloat(step.1.timeIntervalSince(startTime)))
                    reportText = reportText + "\(seconds) - История\n"
                case .following:
                    let seconds = String(format: "%.2f", CGFloat(step.1.timeIntervalSince(startTime)))
                    reportText = reportText + "\(seconds) - Подписки\n"
                case .suggestedUsers:
                    let seconds = String(format: "%.2f", CGFloat(step.1.timeIntervalSince(startTime)))
                    reportText = reportText + "\(seconds) - Рекомендуемые\n"
                case .followRequests:
                    let seconds = String(format: "%.2f", CGFloat(step.1.timeIntervalSince(startTime)))
                    reportText = reportText + "\(seconds) - Запросы на подписку\n"
                case .blockedUsers:
                    let seconds = String(format: "%.2f", CGFloat(step.1.timeIntervalSince(startTime)))
                    reportText = reportText + "\(seconds) - Заблокированные\n"
                }
            }
        }
        showAlert(title: "Отчёт загрузки (сек.)", message: reportText)
    }
    
}
