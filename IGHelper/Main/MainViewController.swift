//
//  ViewController.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 7/8/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit
import Alamofire

class MainViewController: UIViewController {
    
    @IBOutlet var avatarImageView: UIImageView?
    @IBOutlet var followersCountLabel: UILabel?
    @IBOutlet var followingCountLabel: UILabel?
    @IBOutlet var likesCountLabel: UILabel?
    @IBOutlet var commentsCountLabel: UILabel?
    @IBOutlet var loginLabel: UILabel?
    @IBOutlet var buttons: [UIButton]?
    private var blurEffectView: UIVisualEffectView?
    private var spinner: UIActivityIndicatorView?
    
    private var mainScreenInfo: ProfileInfoData?
    private var followRequests: FollowRequests?
    private var posts: [PostData]?
    private var followers: [ApiUser]?
    private var following: [ApiUser]?
    private var suggestedUsers: [GraphUser]?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    private func setupLoadingBlur() {
        let blurEffect = UIBlurEffect(style: .light)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        spinner = UIActivityIndicatorView(style: .white)
        
        guard let blurEffectView = blurEffectView, let spinner = spinner else { return }
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationController?.view.addSubview(blurEffectView)
        
        navigationController?.view.addSubview(spinner)
        spinner.center = view.center
        spinner.startAnimating()
    }
    
    func dismissLoadingBlur() {
        blurEffectView?.removeFromSuperview()
        spinner?.stopAnimating()
        spinner?.removeFromSuperview()
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
    
    @IBAction func refreshButtonAction(_ sender: Any) {
        fetchInfo()
    }
    
    @IBAction func detailButtonAction(_ sender: UIButton) {
        guard let contentType: ContentType = ContentType(rawValue: sender.tag) else { return }
        let vc = UIViewController.detail
        vc.contentType = contentType
        vc.followRequests = followRequests
        vc.posts = posts
        vc.following = following
        vc.followers = followers
        vc.suggestedUsers = suggestedUsers
        vc.onFollow = { [weak self] onUpdate in
            self?.fetchFollowRequests_and_following(onComplete: { [weak self] in
                vc.following = self?.following
                vc.followRequests = self?.followRequests
                onUpdate?()
            })
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

// MARK: - Setup
extension MainViewController {
    
    func updateUI() {
        updateMainInfo()
        updateLikeCount()
        updateCommentCount()
        updateButtons()
    }
    
    func updateMainInfo() {
        followersCountLabel?.text = "\(mainScreenInfo?.follower_count ?? 0)"
        followingCountLabel?.text = "\(mainScreenInfo?.following_count ?? 0)"
        navigationItem.title = mainScreenInfo?.full_name
        if let username = mainScreenInfo?.username {
            loginLabel?.text = "@" + username
        } else {
            loginLabel?.text = nil
        }
        
        UIImage.load(mainScreenInfo?.profile_pic_url) { [weak self] image, url in
            self?.avatarImageView?.image = image
        }
    }
    
    func updateLikeCount() {
        guard let posts = posts else { return }
        let likesCount = posts.compactMap { $0.like_count }.reduce(0, +)
        likesCountLabel?.text = "\(likesCount)"
    }
    
    func updateCommentCount() {
        guard let posts = posts else { return }
        let commentsCount = posts.compactMap { $0.comment_count }.reduce(0, +)
        commentsCountLabel?.text = "\(commentsCount)"
    }
    
    func updateButtons() {
        func setupButton(_ button: UIButton, _ title: String) {
            button.setTitle(nil, for: .normal)

            let style = NSMutableParagraphStyle()
            style.alignment = .center
            let attributedTitle = NSAttributedString(
                string: title,
                attributes: [
                    NSAttributedString.Key.foregroundColor: UIColor.black,
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .bold),
                    NSAttributedString.Key.paragraphStyle: style])
            button.setAttributedTitle(attributedTitle, for: .normal)
        }
        
        buttons?.forEach { button in
            guard let contentType: ContentType = ContentType(rawValue: button.tag) else { return }
            switch contentType {
            case .lost_followers:
                let previousFollowersIds = PastFollowersManager.shared.getIds()
                let lostFollowersIds = UserModel.lostFollowersIds(previousFollowersIds, followers)
                setupButton(button, "\(lostFollowersIds.count)" + "\n" + "lost followers")
            case .gained_followers:
                let previousFollowersIds = PastFollowersManager.shared.getIds()
                let gainedFollowers = UserModel.gainedFollowers(previousFollowersIds, followers)
                setupButton(button, "\(gainedFollowers.count)" + "\n" + "gained followers")
            case .you_dont_follow:
                let youDontFollow = UserModel.youDontFollow(followers: followers, following: following)
                setupButton(button, "\(youDontFollow.count)" + "\n" + "you dont follow")
            case .unfollowers:
                let unfollowers = UserModel.unfollowers(followers: followers, following: following)
                setupButton(button, "\(unfollowers.count)" + "\n" + "unfollowers")
            case .new_guests:
                let newGuests = UserModel.newGuests(suggestedUsers)
                setupButton(button, "\(newGuests.count)" + "\n" + "new guests")
            case .recommendation:
                setupButton(button, "\(suggestedUsers?.count ?? 0)" + "\n" + "recommendation")
            case .top_likers:
                let topLikers = UserModel.topLikers(posts)
                setupButton(button, "\(topLikers.count)" + "\n" + "top likers")
            case .top_commenters:
                let topСommenters = UserModel.topCommenters(posts)
                setupButton(button, "\(topСommenters.count)" + "\n" + "top commenters")
            }
        }
    }
    
}

// MARK: - Info Fetching
extension MainViewController {
    
    func fetchFollowRequests_and_following(onComplete: (()->())? = nil) {
        ApiManager.shared.getFollowRequests(onComplete: { [weak self] followRequests in
            ApiManager.shared.getFollowing(onComplete: { [weak self] following in
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
    
    func fetchInfo(onComplete: (()->())? = nil) {
        setupLoadingBlur()
        ApiManager.shared.getUserInfo(onComplete: { [weak self] info in
            self?.mainScreenInfo = info.profileInfo
            self?.followRequests = info.followRequests
            self?.posts = info.postDataArray
            self?.followers = info.followers
            self?.following = info.following
            self?.suggestedUsers = info.suggestedUsers
            self?.updateUI()
            self?.dismissLoadingBlur()
        }) { [weak self] error in
            self?.showErrorAlert(error)
            self?.dismissLoadingBlur()
        }
    }
    
}
