//
//  RecomendationViewController.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/9/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

enum ContentType: Int {
    case lost_followers
    case gained_followers
    case you_dont_follow
    case unfollowers
    case new_guests
    case recommendation
    case top_likers
    case top_commenters
}

class DetailViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView?
    @IBOutlet var emptyTableLabel: UILabel?
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView?
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: UIControl.Event.valueChanged)
        refreshControl.tintColor = .white
        return refreshControl
    }()
    
    private var usersId: [String] = []
    private var users: [User] = []
    private var usersCache: [String: User] = [:]
    public var mainScreenInfo: ProfileInfoData?
    public var contentType: ContentType?
    public var followRequests: FollowRequests?
    public var posts: [PostData]?
    public var followers: [ApiUser]?
    public var following: [ApiUser]?
    public var suggestedUsers: [GraphUser]?
    public var userDirectSearch: [ApiUser]?
    public var topLikersFollowers: [ApiUser]?
    
    public var onFollow: (( _ onUpdate: (()->Void)? )->())?
    public var onUpdate: (( _ onUpdate: (()->Void)? )->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emptyTableLabel?.alpha = 0
        
        tableView?.addSubview(self.refreshControl)
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        updateUsers(showProgress: true)
    }
    
    func updateUsers(showProgress: Bool = false, onComplete: (()->())? = nil) {
        guard let contentType = contentType else { return }
        switch contentType {
        case .new_guests:
            navigationItem.title = "New Guests"
            let guestsResult = UserModel.newGuests(mainScreenInfo?.username, userDirectSearch, topLikersFollowers, suggestedUsers, following, followers)
            users = guestsResult.guests ?? []
            usersId = guestsResult.guestsIds ?? []
        case .recommendation:
            navigationItem.title = "Recommendation"
            users = suggestedUsers ?? []
        case .top_likers:
            navigationItem.title = "Top Likers"
            users = UserModel.topLikers(mainScreenInfo?.username, posts)
        case .top_commenters:
            navigationItem.title = "Top Commenters"
            users = UserModel.topCommenters(mainScreenInfo?.username, posts)
        case .you_dont_follow: // followers
            navigationItem.title = "You Dont Follow"
            users = UserModel.youDontFollow(followers: followers, following: following)
        case .unfollowers: // following
            navigationItem.title = "Unfollowers"
            users = UserModel.unfollowers(followers: followers, following: following)
        case .gained_followers:
            navigationItem.title = "Gained Followers"
            let previousFollowersIds = PastFollowersManager.shared.getIds()
            users = UserModel.gainedFollowers(previousFollowersIds, followers)
        case .lost_followers:
            navigationItem.title = "Lost Followers"
            let previousFollowersIds = PastFollowersManager.shared.getIds()
            let lostFollowersIds = UserModel.lostFollowersIds(previousFollowersIds, followers)
            usersId = lostFollowersIds
        }
        tableView?.reloadData()
        onComplete?()
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        usersCache = [:]
        onUpdate?() { [weak self] in
            self?.updateUsers() {
                refreshControl.endRefreshing()
            }
        }
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}

extension DetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !users.isEmpty {
            return users.count
        } else {
            emptyTableLabel?.alpha = usersId.isEmpty ? 1 : 0
            return usersId.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        func configureCell(_ cell: UserCell, _ userWithoutFollowStatus: User) {
            var user = userWithoutFollowStatus
            user = UserModel.addFollowStatus(user, following, followRequests)
            cell.configure(user: user, onFollow: { [weak self] onFollow in
                self?.onFollow?() {
                    user = UserModel.addFollowStatus(user, self?.following, self?.followRequests)
                    guard let followStatus = user.followStatus else { return }
                    onFollow?(followStatus)
                }
            })
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: UserCell.identifier, for: indexPath) as! UserCell
        if let user = users[safe: indexPath.row] ?? usersCache[usersId[safe: indexPath.row] ?? ""] {
            configureCell(cell, user)
        } else if let userId = usersId[safe: indexPath.row] {
            cell.configure(user: nil, onFollow: { _ in }) // to reset cell
            ApiManager.shared.getUserInfoArray_graph(ids: [userId], onComplete: { [weak self] users in
                if let user = users.first {
                    self?.usersCache[userId] = user
                    configureCell(cell, user)
                }
            }, onError: { _ in
                configureCell(cell, BaseUser.disabled(userId))
            })
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let item = users[safe: indexPath.row] ?? usersCache[usersId[safe: indexPath.row] ?? ""] {
            let instagramHooks = "instagram://user?username=" + (item.username ?? "")
            if let instagramUrl = URL(string: instagramHooks), UIApplication.shared.canOpenURL(instagramUrl) {
                UIApplication.shared.open(instagramUrl)
            } else {
                //redirect to safari because the user doesn't have Instagram
                guard let instagramUrl = URL(string: "https://instagram.com/" + (item.username ?? "") + "/") else { return }
                UIApplication.shared.open(instagramUrl)
            }
        }
    }
    
}

extension DetailViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
