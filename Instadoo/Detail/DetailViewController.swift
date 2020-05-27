//
//  RecomendationViewController.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/9/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

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
    
    /* main data */
    private var usersId: [String] = []
    private var usersUsernames: [String] = []
    private var users: [User] = []
    
    private var usersCache: [String: User] = [:]
    public var mainScreenInfo: GraphProfile?
    public var contentType: DushboardItemType?
    public var followRequests: FollowRequests?
    public var posts: [GraphPost]?
    public var followers: [GraphUser]?
    public var following: [GraphUser]?
    public var suggestedUsers: [GraphUser]?
    public var userDirectSearch: [BaseUser]?
    public var topLikersFollowers: [GraphUser]?
    public var monthHistoryUsers: [HistoryUser]?
    public var blockedByYouUsernames: [String]?
    
    public var limitedDataDownloadMode: Bool? {
        return mainScreenInfo?.limitedDataDownloadMode
    }
    
    public var onFollow: (( _ onUpdate: ((Error?)->Void)? )->())?
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
        func dataCalculated() {
            if refreshControl.isRefreshing {
                refreshControl.endRefreshing()
            }
            tableView?.reloadData()
            onComplete?()
        }
        
        guard let contentType = contentType else { return }
        switch contentType {
        case .blocked_by_you:
            navigationItem.title = "Accounts You Blocked"
            usersUsernames = blockedByYouUsernames ?? []
            dataCalculated()
        case .recommendation:
            navigationItem.title = "Recommendation"
            users = suggestedUsers ?? []
            dataCalculated()
        case .top_likers:
            navigationItem.title = "Top Likers"
            
            refreshControl.beginRefreshing()
            UserModel.topLikers(mainScreenInfo?.username, posts) { [weak self] users in
                self?.users = users
                dataCalculated()
            }
        case .top_commenters:
            navigationItem.title = "Top Commenters"
            
            refreshControl.beginRefreshing()
            UserModel.topCommenters(mainScreenInfo?.username, posts) { [weak self] users in
                self?.users = users
                dataCalculated()
            }
        case .you_dont_follow: // followers
            navigationItem.title = "You Dont Follow"
            if limitedDataDownloadMode == false {
                
                refreshControl.beginRefreshing()
                UserModel.youDontFollow(followers: followers, following: following) { [weak self] users in
                    self?.users = users
                    dataCalculated()
                }
            }
        case .unfollowers: // following
            navigationItem.title = "Unfollowers"
            if limitedDataDownloadMode == false {
                
                refreshControl.beginRefreshing()
                UserModel.unfollowers(followers: followers, following: following) { [weak self] users in
                    self?.users = users
                    dataCalculated()
                }
            }
        case .gained_followers:
            navigationItem.title = "Gained Followers"
            guard let userId = mainScreenInfo?.id else { return }
            if limitedDataDownloadMode == false {
                let previousFollowersIds = PastFollowersManager.shared.getIds(userId)
                
                refreshControl.beginRefreshing()
                UserModel.gainedFollowers(previousFollowersIds, followers, monthHistoryUsers) { [weak self] users in
                    self?.users = users
                    dataCalculated()
                }
            }
        case .lost_followers:
            navigationItem.title = "Lost Followers"
            guard let userId = mainScreenInfo?.id else { return }
            if limitedDataDownloadMode == false {
                let previousFollowersIds = PastFollowersManager.shared.getIds(userId)
                
                refreshControl.beginRefreshing()
                UserModel.lostFollowersIds(previousFollowersIds, followers, monthHistoryUsers) { [weak self] lostFollowersIds in
                    self?.usersId = lostFollowersIds
                    dataCalculated()
                }
            }
        }
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
    
    func updateEmptyView() {
        let isEmpty = usersId.isEmpty && usersUsernames.isEmpty && users.isEmpty
        
        emptyTableLabel?.alpha = refreshControl.isRefreshing ? 0 : 1
        
        if refreshControl.isRefreshing {
            emptyTableLabel?.text = ""
        } else {
            if limitedDataDownloadMode == true {
                switch contentType {
                case .gained_followers, .lost_followers, .you_dont_follow, .unfollowers:
                    emptyTableLabel?.text = "Can't analyze\nToo many followers and followings"
                default:
                    emptyTableLabel?.text = ""
                }
            } else {
                if isEmpty {
                    switch contentType {
                    case .gained_followers, .lost_followers:
                        emptyTableLabel?.text = "Need more data\nTry to update tomorrow"
                    case .blocked_by_you:
                        emptyTableLabel?.text = "You don't have blocked accounts"
                    case .recommendation:
                        emptyTableLabel?.text = "You don't have recommended users"
                    case .top_likers:
                        emptyTableLabel?.text = "You don't have top likers"
                    case .top_commenters:
                        emptyTableLabel?.text = "You don't have top commenters"
                    case .you_dont_follow:
                        emptyTableLabel?.text = "You don’t have followers that you don't follow back"
                    case .unfollowers:
                        emptyTableLabel?.text = "You don't have unfollowers"
                    default:
                        emptyTableLabel?.text = "You don't have users in this category"
                    }
                } else {
                    emptyTableLabel?.text = ""
                }
            }
        }
    }
    
}

extension DetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        updateEmptyView()
        
        if !users.isEmpty {
            return users.count
        } else if !usersUsernames.isEmpty {
            return usersUsernames.count
        } else {
            return usersId.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        func configureCell(_ cell: UserCell, _ userWithoutFollowStatus: User) {
            var user = userWithoutFollowStatus
            if limitedDataDownloadMode == false && contentType != .blocked_by_you {
                user = UserModel.addFollowStatus(user, following, followRequests)
            }
            cell.configure(user: user, onFollow: { [weak self] onFollow in
                self?.onFollow?() { [weak self] error in
                    if let _ = error {
                        self?.showErrorAlert()
                        return
                    }
                    
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
            GraphRoutes.getUserInfo_graph(id: userId, completion: { [weak self] result in
                guard let user = result.value else { return }
                self?.usersCache[userId] = user
                configureCell(cell, user)
            })
        } else if let userUsername = usersUsernames[safe: indexPath.row] {
            cell.configure(user: nil, onFollow: { _ in }) // to reset cell
            GraphRoutes.getProfile(userName: userUsername, completion: { [weak self] result in
                guard let graphProfile = result.value else { return }
                let user = BaseUser(id: graphProfile.id, full_name: graphProfile.full_name, username: graphProfile.username, profile_pic_url: graphProfile.profile_pic_url, is_verified: nil, followers: nil, descriptionText: nil, followStatus: nil, yourPostsLikes: nil, connectionsCount: nil)
                self?.usersCache[userUsername] = user
                configureCell(cell, user)
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
