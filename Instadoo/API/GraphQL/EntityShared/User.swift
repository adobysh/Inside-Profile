//
//  User.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 2/1/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import Foundation

enum FollowStatus {
    case yes
    case no
    case requested
    case disabled
}

protocol User: Codable {
    var id: String? { get }
    var full_name: String? { get }
    var username: String? { get }
    var profile_pic_url: String? { get }
    var is_verified: Bool? { get }
    var followers: Int? { get }
    var descriptionText: String? { get }
    
    var followStatus: FollowStatus? { get set }
    var yourPostsLikes: Int? { get set }
    var connectionsCount: Int? { get set }
}
