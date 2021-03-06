//
//  UserCell.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/9/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

class UserCell: UITableViewCell {
    
    @IBOutlet var avatarImageView: UIImageView?
    @IBOutlet var nameLabel: UILabel?
    @IBOutlet var descriptionLabel: UILabel?
    @IBOutlet var followButton: UIButton?
    public var onFollow: ((User) -> Void)?
    
    private var user: User?
    
    func configure(user: User?, onFollow: ((User) -> Void)?) {
        self.user = user
        self.onFollow = onFollow
        
        followButton?.setTitle("wait...", for: .disabled)
        
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: { [weak self] in
            self?.nameLabel?.text = user?.username
            self?.descriptionLabel?.text = user?.descriptionText
        })
        updateFollowButton()
        avatarImageView?.imageWithFade = UIImage()
        UIImage.load(user?.profile_pic_url) { [weak self] image, url in
            if user?.profile_pic_url == url {
                self?.avatarImageView?.imageWithFade = image
            }
        }
    }
    
    func updateFollowButton() {
        guard let followStatus = user?.followStatus else {
            followButton?.alpha = 0
            return
        }
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.followButton?.alpha = 1
        }
        switch followStatus {
        case .yes:
            followButton?.setBackgroundColor(.white, for: .normal)
            followButton?.setTitleColor(.black, for: .normal)
            followButton?.setTitle("Following", for: .normal)
        case .no:
            followButton?.setBackgroundColor(UIColor(named: "followButtonColor"), for: .normal)
            followButton?.setTitleColor(.white, for: .normal)
            followButton?.setTitle("Follow", for: .normal)
        case .requested:
            followButton?.setBackgroundColor(.white, for: .normal)
            followButton?.setTitleColor(.black, for: .normal)
            followButton?.setTitle("Requested", for: .normal)
        case .disabled:
            followButton?.setBackgroundImage(UIImage(), for: .normal)
            followButton?.setTitle("", for: .normal)
        }
    }
    
    @IBAction func followButtonAction(_ sender: UIButton) {
        sender.isEnabled = false
        guard let user = user, let followStatus = user.followStatus else { return }
        switch followStatus {
        case .yes:
            GraphRoutes.unfollow(id: user.id ?? "", completion: { [weak self] result in
                sender.isEnabled = true
                if let _ = result.value {
                    self?.user?.followStatus = .no
                    self?.updateFollowButton()
                    if let user = self?.user {
                        self?.onFollow?(user)
                    }
                }
            })
        case .no:
            GraphRoutes.follow(id: user.id ?? "", username: user.username ?? "", completion: { [weak self] result in
                sender.isEnabled = true
                if let followStatus = result.value {
                    self?.user?.followStatus = followStatus
                    self?.updateFollowButton()
                    if let user = self?.user {
                        self?.onFollow?(user)
                    }
                }
            })
        case .requested:
            GraphRoutes.unfollow(id: user.id ?? "", completion: { [weak self] result in
                sender.isEnabled = true
                if let _ = result.value {
                    self?.user?.followStatus = .no
                    self?.updateFollowButton()
                    if let user = self?.user {
                        self?.onFollow?(user)
                    }
                }
            })
        case .disabled:
            sender.isEnabled = true
        }
    }
    
}
