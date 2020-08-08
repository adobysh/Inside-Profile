//
//  BaseUser.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 2/1/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import Foundation

struct BaseUser: User {
    var id: String?
    var full_name: String?
    var username: String?
    var profile_pic_url: String?
    var is_verified: Bool?
    var followers: Int?
    var descriptionText: String?
    
    var followStatus: FollowStatus?
    var yourPostsLikes: Int?
    var connectionsCount: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id, full_name, username, profile_pic_url, is_verified, followers
    }
    
    static func disabled(_ id: String?) -> BaseUser {
        return BaseUser(id: id, full_name: nil, username: "Account disabled", profile_pic_url: nil, is_verified: nil, followers: nil, descriptionText: nil, followStatus: .disabled, yourPostsLikes: nil, connectionsCount: nil)
    }
}
