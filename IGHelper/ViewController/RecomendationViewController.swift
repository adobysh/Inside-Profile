//
//  RecomendationViewController.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/9/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

enum ContentType {
    case lost_followers
    case gained_followers
    case you_dont_follow
    case unfollowers
    case new_guests
    case recommendation
    case top_likers
    case top_commenters
}

class RecomendationViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView?
    
    private var users: [User] = []
    public var contentType: ContentType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let contentType = contentType else { return }
        switch contentType {
        case .recommendation:
            ApiManager.shared.getSuggestedUser(onComplete: { [weak self] users in
                self?.users = users
                self?.tableView?.reloadData()
            }) { [weak self] error in
                self?.showErrorAlert(error)
            }
        default:
            break
        }
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}

extension RecomendationViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserCell.identifier, for: indexPath) as! UserCell
        if let item = users[safe: indexPath.row] {
            cell.configure(imagePath: item.profile_pic_url, name: item.full_name, username: item.username)
        }
        return cell
    }
    
}
