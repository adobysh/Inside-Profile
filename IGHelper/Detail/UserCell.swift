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
    @IBOutlet var followButton: UIButton?
    public var onFollow: ((_ isFollowing: Bool)->())?
    
    private var isFollowing = false
    
    func configure(imagePath: String?, name: String?, username: String?, isFollowing: Bool, onFollow: ((_ isFollowing: Bool)->())?) {
        self.isFollowing = isFollowing
        if isFollowing {
            followButton?.setBackgroundColor(.white, for: .normal)
            followButton?.setTitleColor(.black, for: .normal)
            followButton?.setTitle("Unfollow", for: .normal)
        } else {
            followButton?.setBackgroundColor(UIColor(named: "followButtonColor"), for: .normal)
            followButton?.setTitleColor(.white, for: .normal)
            followButton?.setTitle("Follow", for: .normal)
        }
        nameLabel?.text = username
        
        avatarImageView?.image = nil
        UIImage.load(imagePath) { [weak self] image, url in
            if imagePath == url {
                self?.avatarImageView?.image = image
            }
        }
    }
    
}
