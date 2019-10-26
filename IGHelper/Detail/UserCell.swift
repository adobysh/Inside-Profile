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
    public var onFollow: (( ((FollowStatus)->Void)? )->())?
    
    private var user: User?
    
    func configure(user: User, onFollow: (( ((FollowStatus)->Void)? )->())?) {
        self.user = user
        self.onFollow = onFollow
        
        followButton?.setTitle("wait...", for: .disabled)
        nameLabel?.text = user.username
        descriptionLabel?.text = user.descriptionText
        updateFollowButton()
        avatarImageView?.image = nil
        UIImage.load(user.profile_pic_url) { [weak self] image, url in
            if user.profile_pic_url == url {
                self?.avatarImageView?.image = image
            }
        }
    }
    
    func updateFollowButton() {
        guard let followStatus = user?.followStatus else { return }
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
        }
    }
    
    @IBAction func followButtonAction(_ sender: UIButton) {
        sender.isEnabled = false
        guard let user = user, let followStatus = user.followStatus else { return }
        switch followStatus {
        case .yes:
            ApiManager.shared.unfollow(id: user.id ?? "", onComplete: { [weak self] in
                self?.onFollow?() { [weak self] followStatus in
                    self?.user?.followStatus = followStatus
                    self?.updateFollowButton()
                    sender.isEnabled = true
                }
            }) { (error) in
                sender.isEnabled = true
            }
        case .no:
            ApiManager.shared.follow(id: user.id ?? "", username: user.username ?? "", onComplete: { [weak self] in
                self?.onFollow?() { [weak self] followStatus in
                    self?.user?.followStatus = followStatus
                    self?.updateFollowButton()
                    sender.isEnabled = true
                }
            }) { (error) in
                sender.isEnabled = true
            }
        case .requested:
            ApiManager.shared.unfollow(id: user.id ?? "", onComplete: { [weak self] in
                self?.onFollow?() { [weak self] followStatus in
                    self?.user?.followStatus = followStatus
                    self?.updateFollowButton()
                    sender.isEnabled = true
                }
            }) { (error) in
                sender.isEnabled = true
            }
        }
    }
    
}
