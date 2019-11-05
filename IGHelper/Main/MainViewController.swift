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
        
        setProgress(0)
        superButtons?.forEach { button in
            button.addTapGestureRecognizer { [weak self] in
                self?.detailButtonAction(button)
            }
        }
        
        setupRefreshControl()
        fetchInfo()
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateUI()
        if !AuthorizationManager.shared.isLoggedIn {
            let vc = UIViewController.getStarted
            vc.onAuthorizationSuccess = { [weak self] in
                self?.fetchInfo()
            }
            present(vc, animated: false, completion: nil)
        }
    }
    
    @objc func handleRefreshControl() {
        // защита от двойного запуска обновления
        guard (superButtons?.filter { $0.inProgress } ?? []).isEmpty == true else {
            scrollView?.refreshControl?.endRefreshing()
            return
        }
        
        fetchInfo() { [weak self] in
            self?.scrollView?.refreshControl?.endRefreshing()
        }
    }
    
    @IBAction func settingsButtonAction(_ sender: Any) {
        let vc = UIViewController.settings
        vc.onLogOut = { [weak self] in
            let vc = UIViewController.getStarted
            vc.onAuthorizationSuccess = { [weak self] in
                self?.fetchInfo()
            }
            self?.present(vc, animated: true, completion: nil)
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func detailButtonAction(_ sender: ActivityIndicatorButton) {
        guard !sender.inProgress else { return }
        guard let contentType: ContentType = ContentType(rawValue: sender.tag) else { return }
        
        if !SubscriptionKeychain.isSubscribed()
            && (contentType == .new_guests
            || contentType == .recommendation
            || contentType == .top_commenters
            || contentType == .top_likers)
        {
            let vc = UIViewController.vip
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
            self?.fetchFollowRequests_and_following(onComplete: { [weak self] in
                vc.following = self?.following
                vc.followRequests = self?.followRequests
                onUpdate?()
            })
        }
        vc.onUpdate = { [weak self] onUpdate in
            switch contentType {
            case .lost_followers, .gained_followers:
                ApiManager.shared.getFollowers(onComplete: { [weak self] followers in
                    self?.followers = followers
                    vc.followers = followers
                    onUpdate?()
                }) { _ in
                    onUpdate?()
                }
            case .you_dont_follow, .unfollowers:
                ApiManager.shared.getFollowers(onComplete: { [weak self] followers in
                    ApiManager.shared.getFollowings(onComplete: { [weak self] following in
                        self?.followers = followers
                        self?.following = following
                        vc.followers = followers
                        vc.following = following
                        onUpdate?()
                    }) { _ in
                        onUpdate?()
                    }
                }) { _ in
                    onUpdate?()
                }
            case .new_guests:
                ApiManager.shared.getUserDirectSearch(onComplete: { [weak self] userDirectSearch in
                    self?.userDirectSearch = userDirectSearch
                    vc.userDirectSearch = userDirectSearch
                    onUpdate?()
                }) { _ in
                    onUpdate?()
                }
            case .recommendation:
                ApiManager.shared.getGoodSuggestedUser(onComplete: { [weak self] goodSuggestedUser in
                    self?.suggestedUsers = goodSuggestedUser
                    vc.suggestedUsers = goodSuggestedUser
                    onUpdate?()
                }) { _ in
                    onUpdate?()
                }
            case .top_likers, .top_commenters:
                ApiManager.shared.getPosts(onComplete: { [weak self] posts in
                    self?.posts = posts
                    vc.posts = posts
                    onUpdate?()
                }) { _ in
                    onUpdate?()
                }
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
    
    func updateUI() {
        updateMainInfo()
        updateLikeCount()
        updateCommentCount()
        updateButtons()
    }
    
    func updateMainInfo() {
        followersCountLabel?.text = "\(mainScreenInfo?.follower_count?.bigBeauty ?? "0")"
        followingCountLabel?.text = "\(mainScreenInfo?.following_count?.bigBeauty ?? "0")"
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
    
    func updateLikeCount() {
        guard let posts = posts else { return }
        let likesCount = posts.compactMap { $0.like_count }.reduce(0, +)
        likesCountLabel?.text = likesCount.bigBeauty
    }
    
    func updateCommentCount() {
        guard let posts = posts else { return }
        let commentsCount = posts.compactMap { $0.comment_count }.reduce(0, +)
        commentsCountLabel?.text = commentsCount.bigBeauty
    }
    
    func updateButtons() {
        superButtons?.forEach { button in
            guard let contentType: ContentType = ContentType(rawValue: button.tag) else { return }
            switch contentType {
            case .lost_followers:
                let previousFollowersIds = PastFollowersManager.shared.getIds()
                let lostFollowersIds = UserModel.lostFollowersIds(previousFollowersIds, followers, monthHistoryUsers)
                button.value = lostFollowersIds.count.bigBeauty
            case .gained_followers:
                let previousFollowersIds = PastFollowersManager.shared.getIds()
                let gainedFollowers = UserModel.gainedFollowers(previousFollowersIds, followers, monthHistoryUsers)
                button.value = gainedFollowers.count.bigBeauty
            case .you_dont_follow:
                let youDontFollow = UserModel.youDontFollow(followers: followers, following: following)
                button.value = youDontFollow.count.bigBeauty
            case .unfollowers:
                let unfollowers = UserModel.unfollowers(followers: followers, following: following)
                button.value = unfollowers.count.bigBeauty
            case .new_guests:
                let newGuests = UserModel.newGuests(mainScreenInfo?.username, userDirectSearch, topLikersFollowers, suggestedUsers, following, followers)
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
    
    func fetchFollowRequests_and_following(onComplete: (()->())? = nil) {
        ApiManager.shared.getFollowRequests(onComplete: { [weak self] followRequests in
            ApiManager.shared.getFollowings(onComplete: { [weak self] following in
                self?.following = following
                self?.followRequests = followRequests
                self?.updateUI()
                onComplete?()
            }) { [weak self] error in
                onComplete?()
                self?.showErrorAlert(error)
            }
        }) { [weak self] error in
            onComplete?()
            self?.showErrorAlert(error)
        }
    }
    
    func fetchInfo(onFetchProfileInfo: (()->())? = nil) {
        let onError: (Error)->() = { [weak self] error in
            self?.showErrorAlert(error)
            self?.superButtons?.forEach { $0.inProgress = false }
            self?.setProgress(0)
            onFetchProfileInfo?()
        }
        
        superButtons?.forEach { $0.inProgress = true }
        
        setProgress(10)
        
        ApiManager.shared.getProfileInfoAndPosts(onComplete: { [weak self] result in
            onFetchProfileInfo?()
            self?.mainScreenInfo = result.profileInfo
            self?.posts = result.postDataArray
            self?.updateUI()
            
            self?.setProgress(20)
            ApiManager.shared.getFollowers(onComplete: { [weak self] followers in
                self?.followers = followers
                ApiManager.shared.getMonthHistoryUsers(onComplete: { [weak self] monthHistoryUsers in
                    self?.monthHistoryUsers = monthHistoryUsers
                    self?.updateUI()
                    
                    self?.lostFollowersButton?.inProgress = false
                    self?.gainedFollowersButton?.inProgress = false
                    
                    self?.setProgress(40)
                    
                    ApiManager.shared.getFollowings(onComplete: { [weak self] following in
                        self?.following = following
                        self?.updateUI()
                        
                        self?.youDontFollowButton?.inProgress = false
                        self?.unfollowersButton?.inProgress = false
                        
                        self?.setProgress(60)
                        
                        ApiManager.shared.getGoodSuggestedUser(onComplete: { [weak self] suggestedUsers in
                            self?.suggestedUsers = suggestedUsers
                            self?.updateUI()
                            
                            self?.setProgress(80)
                            
                            self?.recomendationButton?.inProgress = false
                            
                            ApiManager.shared.getFollowRequests(onComplete: { [weak self] followRequests in
                                self?.followRequests = followRequests
                                ApiManager.shared.getUserDirectSearch(onComplete: { [weak self] userDirectSearch in
                                    self?.userDirectSearch = userDirectSearch
                                    self?.updateUI()
                                    
                                    self?.setProgress(90)
                                    
                                    if GuestsManager.shared.containIds() {
                                        self?.updateUI()
                                        
                                        self?.setProgress(100)
                                        self?.superButtons?.forEach { $0.inProgress = false }
                                        
                                    } else {
                                        let topLikers = UserModel.topLikers(self?.mainScreenInfo?.username, self?.posts)
                                        ApiManager.shared.getTopLikersFriends(myId: self?.mainScreenInfo?.id, topLikers: topLikers, onComplete: { [weak self] topLikersFollowers in
                                            self?.topLikersFollowers = topLikersFollowers
                                            
                                            self?.updateUI()
                                            
                                            self?.setProgress(100)
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
