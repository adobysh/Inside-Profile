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
    @IBOutlet var recomendationButton: UIButton?
    
    var mainScreenInfo: ProfileInfoData? {
        didSet {
            guard let imageUrl = URL(string: mainScreenInfo?.profile_pic_url ?? ""), let imageData = try? Data(contentsOf: imageUrl) else { return }
            avatarImageView?.image = UIImage(data: imageData)
            followersCountLabel?.text = "\(mainScreenInfo?.follower_count ?? 0)"
            followingCountLabel?.text = "\(mainScreenInfo?.following_count ?? 0)"
            navigationItem.title = mainScreenInfo?.full_name
            loginLabel?.text = "@\(mainScreenInfo?.username ?? "")"
        }
    }
    var posts: [PostData]? {
        didSet {
            guard let posts = posts else { return }
            let likesCount = posts.compactMap { $0.like_count }.reduce(0, +)
            let commentsCount = posts.compactMap { $0.comment_count }.reduce(0, +)
            likesCountLabel?.text = "\(likesCount)"
            commentsCountLabel?.text = "\(commentsCount)"
        }
    }
    var users: [UserData]?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.fetchInfo()
        }
        
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !AuthorizationManager.shared.isLoggedIn {
            let vc = UIViewController.getStarted
            present(vc, animated: false, completion: nil)
        }
    }
    
    @IBAction func refreshButtonAction(_ sender: Any) {
        fetchInfo()
    }
    
    @IBAction func recomendationButtonAction(_ sender: Any) {
        let vc = UIViewController.recomendation
        ApiManager.shared.getSuggestedUser(onComplete: { users in
            vc.users = users
            self.navigationController?.pushViewController(vc, animated: true)
        }) { error in
            self.showErrorAlert(error)
        }
    }
    
}

// MARK: - Private funcs
extension MainViewController {
    
    func fetchInfo() {
        ApiManager.shared.getUserInfo(onComplete: { [weak self] info in
            self?.mainScreenInfo = info.profileInfo
            self?.posts = info.postDataArray
            ApiManager.shared.getSuggestedUser(onComplete: { users in
                self?.recomendationButton?.setTitle("\(users.count ?? 0)\nrecomendations", for: .normal)
                self?.users = users
            }) { error in
                self?.showErrorAlert(error)
            }
        }) { (error) in
            self.showErrorAlert(error)
        }
    }
    
}
