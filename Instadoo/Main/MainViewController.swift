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
    
    private lazy var viewModel: MainViewModel = {
        return MainViewModel(delegate: self)
    }()
    
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
        
        setProgress(0)
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
            self?.viewModel.logOut()
            
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
        vc.limitedDataDownloadMode = viewModel.state.limitedDataDownloadMode
        vc.contentType = contentType
        vc.mainScreenInfo = viewModel.state.mainScreenInfo
        vc.followRequests = viewModel.state.followRequests
        vc.posts = viewModel.state.posts
        vc.following = viewModel.state.following
        vc.followers = viewModel.state.followers
        vc.suggestedUsers = viewModel.state.suggestedUsers
        vc.monthHistoryUsers = viewModel.state.monthHistoryUsers
        vc.blockedByYouUsernames = viewModel.state.blockedByYouUsernames
        vc.onFollow = { [weak self] onUpdate in
            let onError: (Error)->() = { error in onUpdate?(error) }
            
            GraphRoutes.getUserFollowings(limited: self?.viewModel.state.limitedDataDownloadMode == true, id: self?.viewModel.state.mainScreenInfo?.id ?? "", onSubpartLoaded: { _ in }, completion: { [weak self] result in
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
                    self?.viewModel.state.following = following
                    self?.viewModel.state.followRequests = followRequests
                    vc.following = following
                    vc.followRequests = followRequests
                    onUpdate?(nil)
                })
            })
        }
        vc.onUpdate = { [weak self] onUpdate in
            let onError: (Error)->() = { _ in onUpdate?() }
            
            let onComplete: ()->() = {
                onUpdate?()
            }
            
            switch contentType {
            case .lost_followers, .gained_followers:
                guard let userId = self?.viewModel.state.mainScreenInfo?.id else { onComplete(); return }
                GraphRoutes.getAllFollowers(limited: self?.viewModel.state.limitedDataDownloadMode == true, id: userId, onSubpartLoaded: { _ in }, completion: { [weak self] result in
                    if let error = result.error {
                        onError(error)
                        return
                    }
                    
                    let followers = result.value
                    self?.viewModel.state.followers = followers
                    vc.followers = followers
                    onComplete()
                })
            case .you_dont_follow, .unfollowers:
                guard let userId = self?.viewModel.state.mainScreenInfo?.id else { onComplete(); return }
                GraphRoutes.getAllFollowers(limited: self?.viewModel.state.limitedDataDownloadMode == true, id: userId, onSubpartLoaded: { _ in }, completion: { [weak self] result in
                    if let error = result.error {
                        onError(error)
                        return
                    }
                    
                    let followers = result.value
                    GraphRoutes.getUserFollowings(limited: self?.viewModel.state.limitedDataDownloadMode == true, id: userId, onSubpartLoaded: { _ in }, completion: { [weak self] result in
                        if let error = result.error {
                            onError(error)
                            return
                        }
                        
                        let following = result.value
                        self?.viewModel.state.followers = followers
                        self?.viewModel.state.following = following
                        vc.followers = followers
                        vc.following = following
                        onComplete()
                    })
                })
            case .blocked_by_you:
                GraphRoutes.getBlockedUsersUsernames(userName: self?.viewModel.state.mainScreenInfo?.username ?? "", completion: { [weak self] result in
                    if let error = result.error {
                        onError(error)
                        return
                    }
                    
                    let blockedUsersUsernames = result.value
                    self?.viewModel.state.blockedByYouUsernames = blockedUsersUsernames
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
                    self?.viewModel.state.suggestedUsers = goodSuggestedUser
                    vc.suggestedUsers = goodSuggestedUser
                    onComplete()
                })
            case .top_likers, .top_commenters:
                GraphRoutes.getPosts(id: self?.viewModel.state.mainScreenInfo?.id ?? "", onSubpartLoaded: { _, _ in }, completion: { [weak self] result in
                    if let error = result.error {
                        onError(error)
                        return
                    }
                    
                    let posts = result.value
                    self?.viewModel.state.posts = posts
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
    
    func fetchInfo() {
        superButtons?.forEach { $0.inProgress = true }
        setProgress(1)
        
        viewModel.fetchInfo()
    }
    
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

extension MainViewController: MainViewModelDelegate {
    
    func viewModelDidUpdateLikesCount(_ likesCount: Int) {
        let postsCount = (viewModel.state.posts?.count ?? 0)
        let likesCountBigBeauty = likesCount.bigBeauty
        likesCountLabel?.text = postsCount >= LIMITED_ANALYTICS_TOTAL_POSTS_COUNT ? "> \(likesCountBigBeauty)" : likesCountBigBeauty
    }
    
    func viewModelDidUpdateCommentsCount(_ commentsCount: Int) {
        let postsCount = (viewModel.state.posts?.count ?? 0)
        let commentsCountBigBeauty = commentsCount.bigBeauty
        commentsCountLabel?.text = postsCount >= LIMITED_ANALYTICS_TOTAL_POSTS_COUNT ? "> \(commentsCountBigBeauty)" : commentsCountBigBeauty
    }
    
    func viewModelDidUpdateMainInfo(_ mainInfo: GraphProfile) {
        followersCountLabel?.text = "\(mainInfo.follower_count?.bigBeauty ?? "0")"
        followingCountLabel?.text = "\(mainInfo.following_count?.bigBeauty ?? "0")"
        navigationItem.title = viewModel.state.mainScreenInfo?.full_name
        if let username = viewModel.state.mainScreenInfo?.username {
            loginLabel?.text = "@" + username
        } else {
            loginLabel?.text = nil
        }
        
        let bestQualityAvatarUrl = viewModel.state.mainScreenInfo?.profile_pic_url_hd ?? viewModel.state.mainScreenInfo?.profile_pic_url
        UIImage.load(bestQualityAvatarUrl) { [weak self] image, url in
            self?.avatarImageView?.imageWithFade = image
        }
    }
    
    func viewModelDidEndFetching(timeReport: [(DataPart, Date)]) {
        superButtons?.forEach { $0.inProgress = false }
        setProgress(100)
        #if DEBUG
            showTimeReport(timeReport: timeReport)
        #endif
    }
    
    func viewModelDidError(_ error: Error) {
        showErrorAlert(error) { [weak self] in
            self?.fetchDataOrAuthorization()
        }
        superButtons?.forEach { $0.inProgress = false }
        setProgress(0)
    }
    
    func viewModelDidUpdateDushboardItem(_ dushboardItem: DushboardItemType, value: String) {
        let targetButton: ActivityIndicatorButton?
        
        switch dushboardItem {
        case .blocked_by_you:   targetButton = blockedUsersButton
        case .gained_followers: targetButton = gainedFollowersButton
        case .lost_followers:   targetButton = lostFollowersButton
        case .recommendation:   targetButton = recomendationButton
        case .top_commenters:   targetButton = topCommentersButton
        case .top_likers:       targetButton = topLikersButton
        case .unfollowers:      targetButton = unfollowersButton
        case .you_dont_follow:  targetButton = youDontFollowButton
        }
        
        targetButton?.inProgress = false
        targetButton?.value = value
    }
    
    func viewModelDidUpdateProgress(_ progress: CGFloat) {
        setProgress(progress)
    }
    
}
