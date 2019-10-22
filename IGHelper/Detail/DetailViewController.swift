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
    
    private var users: [User] = []
    public var contentType: ContentType?
    public var posts: [PostData]?
    public var following: [ApiUser]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        guard let contentType = contentType else { return }
        switch contentType {
        case .new_guests:
            // пока показываем рекомендуемых пользователей кроме:
            // 1. подтверждённых аккаунтов
            // 2. пользователи с более чем 1к подписчиков
            navigationItem.title = "New Guests"
            ApiManager.shared.getSuggestedUser(onComplete: { [weak self] users in
                self?.users = users.filter { $0.is_verified == false && ($0.followers ?? 0) < 1000 }
                self?.tableView?.reloadData()
            }) { [weak self] error in
                self?.showErrorAlert(error)
            }
        case .recommendation:
            navigationItem.title = "Recommendation"
            ApiManager.shared.getSuggestedUser(onComplete: { [weak self] users in
                self?.users = users
                self?.tableView?.reloadData()
            }) { [weak self] error in
                self?.showErrorAlert(error)
            }
        case .top_likers:
            navigationItem.title = "Top Likers"
            let usersWithDublicates = posts?.compactMap { $0.facepile_top_likers }.flatMap { $0 } ?? []
            let userIds = Array(Set(usersWithDublicates.compactMap { $0.id }))
            userIds.forEach { userId in
                if let uniqueUser = usersWithDublicates.first(where: { $0.id == userId }) {
                    users.append(uniqueUser)
                }
            }
            tableView?.reloadData()
        case .top_commenters:
            navigationItem.title = "Top Commenters"
            let usersWithDublicates = posts?.compactMap { $0.preview_comments }.flatMap { $0 }.compactMap { $0.user } ?? []
            let userIds = Array(Set(usersWithDublicates.compactMap { $0.id }))
            userIds.forEach { userId in
                if let uniqueUser = usersWithDublicates.first(where: { $0.id == userId }) {
                    users.append(uniqueUser)
                }
            }
            tableView?.reloadData()
        case .you_dont_follow: // followers
            navigationItem.title = "You Dont Follow"
            ApiManager.shared.getFollowers(onComplete: { [weak self] followers in
                ApiManager.shared.getFollowing(onComplete: { [weak self] following in
                    self?.users = followers.filter({ !following.contains($0) })
                    self?.tableView?.reloadData()
                }) { [weak self] error in
                    self?.showErrorAlert(error)
                }
            }) { [weak self] error in
                self?.showErrorAlert(error)
            }
        case .unfollowers: // following
            navigationItem.title = "Unfollowers"
            ApiManager.shared.getFollowers(onComplete: { [weak self] followers in
                ApiManager.shared.getFollowing(onComplete: { [weak self] following in
                    self?.users = following.filter({ !followers.contains($0) })
                    self?.tableView?.reloadData()
                }) { [weak self] error in
                    self?.showErrorAlert(error)
                }
            }) { [weak self] error in
                self?.showErrorAlert(error)
            }
        case .gained_followers:
            navigationItem.title = "Gained Followers"
            ApiManager.shared.getFollowers(onComplete: { [weak self] followers in
                let previousFollowersIds = PastFollowersManager.shared.getIds()
                self?.users = followers.filter { !previousFollowersIds.contains($0.id ?? "") }
                self?.tableView?.reloadData()
            }) { [weak self] error in
                self?.showErrorAlert(error)
            }
        case .lost_followers:
            navigationItem.title = "Lost Followers"
            ApiManager.shared.getFollowers(onComplete: { [weak self] followers in
                let previousFollowersIds = PastFollowersManager.shared.getIds()
                let currentFollowersIds = followers.compactMap { $0.id }
                let lostFollowersIds = previousFollowersIds.filter { !currentFollowersIds.contains($0) }
                
                ApiManager.shared.getUserInfoArray_graph(ids: lostFollowersIds, onComplete: { [weak self] users in
                    self?.users = users
                    self?.tableView?.reloadData()
                }) { error in
                    self?.showErrorAlert(error)
                }
            }) { [weak self] error in
                self?.showErrorAlert(error)
            }
        }
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}

extension DetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserCell.identifier, for: indexPath) as! UserCell
        if let item = users[safe: indexPath.row], let following = following {
            let isFollowing: Bool = following.first { $0.id == item.id } != nil
            cell.configure(imagePath: item.profile_pic_url, name: item.full_name, username: item.username, isFollowing: isFollowing, onFollow: { isFollowing in
                #warning("put onFollow logic here")
            })
        }
        return cell
    }
    
}

extension DetailViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
