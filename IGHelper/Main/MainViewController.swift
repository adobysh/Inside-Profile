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
    
    var mainScreenInfo: ProfileInfoData?
    var posts: [PostData]?
    var followers: [ApiUser]?
    var following: [ApiUser]?
    var suggestedUsers: [GraphUser]?
    
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
        vc.posts = posts
        vc.following = following
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
        guard let imageUrl = URL(string: mainScreenInfo?.profile_pic_url ?? ""), let imageData = try? Data(contentsOf: imageUrl) else { return }
        avatarImageView?.image = UIImage(data: imageData)
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
                var lostFollowersIds: [String] = []
                if let followers = followers {
                    let previousFollowersIds = PastFollowersManager.shared.getIds()
                    let currentFollowersIds = followers.compactMap { $0.id } 
                    lostFollowersIds = previousFollowersIds.filter { !currentFollowersIds.contains($0) }
                }
                setupButton(button, "\(lostFollowersIds.count)" + "\n" + "lost followers")
            case .gained_followers:
                let previousFollowersIds = PastFollowersManager.shared.getIds()
                let gainedFollowers = followers?.filter { !previousFollowersIds.contains($0.id ?? "") } ?? []
                setupButton(button, "\(gainedFollowers.count)" + "\n" + "gained followers")
            case .you_dont_follow:
                let youDontFollow = followers?.filter({ !(following ?? []).contains($0) }) ?? []
                setupButton(button, "\(youDontFollow.count)" + "\n" + "you dont follow")
            case .unfollowers:
                let unfollowers = following?.filter({ !(followers ?? []).contains($0) }) ?? []
                setupButton(button, "\(unfollowers.count)" + "\n" + "unfollowers")
            case .new_guests:
                // пока показываем рекомендуемых пользователей кроме:
                // 1. подтверждённых аккаунтов
                // 2. пользователи с более чем 1к подписчиков
                let newGuests = suggestedUsers?.filter { $0.is_verified == false && ($0.followers ?? 0) < 1000 } ?? []
                setupButton(button, "\(newGuests.count)" + "\n" + "new guests")
            case .recommendation:
                setupButton(button, "\(suggestedUsers?.count ?? 0)" + "\n" + "recommendation")
            case .top_likers:
                let usersWithDublicates = posts?.compactMap { $0.facepile_top_likers }.flatMap { $0 } ?? []
                let userIds = Array(Set(usersWithDublicates.compactMap { $0.id }))
                setupButton(button, "\(userIds.count)" + "\n" + "top likers")
            case .top_commenters:
                // Пока считаем просто всех коментаторов
                let usersWithDublicates = posts?.compactMap { $0.preview_comments }.flatMap { $0 }.compactMap { $0.user } ?? []
                let userIds = Array(Set(usersWithDublicates.compactMap { $0.id }))
                setupButton(button, "\(userIds.count)" + "\n" + "top commenters")
            }
        }
    }
    
}

// MARK: - Private funcs
extension MainViewController {
    
    func fetchInfo(onComplete: (()->())? = nil) {
        setupLoadingBlur()
        ApiManager.shared.getUserInfo(onComplete: { [weak self] info in
            self?.mainScreenInfo = info.profileInfo
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
