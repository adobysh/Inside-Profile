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
    
    @IBAction func settingsButtonAction(_ sender: Any) {
        let vc = UIViewController.settings
        vc.onLogOut = { [weak self] in
            let vc = UIViewController.getStarted
            self?.present(vc, animated: false, completion: nil)
        }
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func refreshButtonAction(_ sender: Any) {
        fetchInfo()
    }
    
    @IBAction func detailButtonAction(_ sender: UIButton) {
        guard let contentType: ContentType = ContentType(rawValue: sender.tag) else { return }
        let vc = UIViewController.detail
        vc.contentType = contentType
        vc.posts = posts
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
        guard let imageUrl = URL(string: mainScreenInfo?.profile_pic_url ?? ""), let imageData = try? Data(contentsOf: imageUrl) else { return }
        avatarImageView?.image = UIImage(data: imageData)
        followersCountLabel?.text = "\(mainScreenInfo?.follower_count ?? 0)"
        followingCountLabel?.text = "\(mainScreenInfo?.following_count ?? 0)"
        navigationItem.title = mainScreenInfo?.full_name
        loginLabel?.text = "@\(mainScreenInfo?.username ?? "")"
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
                let currentFollowersIds = followers?.compactMap { $0.id } ?? []
                let lostFollowersIds = previousFollowersIds.filter { !currentFollowersIds.contains($0) }
                setupButton(button, "\(lostFollowersIds.count)" + "\n" + "lost followers")
            default:
                setupButton(button, "1k\nLovers")
            }
        }
    }
    
}

// MARK: - Private funcs
extension MainViewController {
    
    func fetchInfo() {
        ApiManager.shared.getUserInfo(onComplete: { [weak self] info in
            self?.mainScreenInfo = info.profileInfo
            self?.posts = info.postDataArray
            self?.followers = info.followers
            self?.following = info.following
            self?.suggestedUsers = info.suggestedUsers
            self?.updateUI()
        }) { [weak self] error in
            self?.showErrorAlert(error)
        }
    }
    
}
