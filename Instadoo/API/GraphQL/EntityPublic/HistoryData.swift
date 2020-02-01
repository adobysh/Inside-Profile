//
//  StoryData.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/30/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

struct HistoryData {
    let timestamp: Double?
    let user: HistoryUser?
    
    var date: Date? {
        return Date(timeIntervalSince1970: timestamp ?? 0)
    }
}

struct HistoryUser: User {
    var id: String?
    var full_name: String?
    var username: String?
    var profile_pic_url: String?
    var is_verified: Bool?
    var followers: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id, full_name, username, profile_pic_url, is_verified, followers
    }
    
    var descriptionText: String?
    var followStatus: FollowStatus?
    var yourPostsLikes: Int?
    var connectionsCount: Int?
    
    var followed_by_viewer: Bool?
}
