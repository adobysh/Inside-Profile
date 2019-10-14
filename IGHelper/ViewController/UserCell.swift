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
    @IBOutlet var usernameLabel: UILabel?
    
    func configure(imagePath: String?, name: String?, username: String?) {
        nameLabel?.text = name
        usernameLabel?.text = "@" + (username ?? "")
        if let imagePath = imagePath, let imageUrl = URL(string: imagePath), let imageData = try? Data(contentsOf: imageUrl) {
            avatarImageView?.image = UIImage(data: imageData)
        }
    }
    
}
