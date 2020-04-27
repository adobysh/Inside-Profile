//
//  GraphUser.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 1/30/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

struct GraphUser: User, Codable, Comparable {
    private enum CodingKeys: String, CodingKey {
        case id
        case username
        case full_name
        case profile_pic_url
        case is_private
        case is_verified
        case followed_by_viewer
        case requested_by_viewer
        case edge_followed_by
        case is_viewer
    }
    
    let edge_followed_by: EdgeFollowedBy?
    let followed_by_viewer: Bool?
    let full_name: String?
    let id: String?
    let is_private: Bool?
    let is_verified: Bool?
    let is_viewer: Bool?
    let profile_pic_url: String?
    let requested_by_viewer: Bool?
    let username: String?
    var descriptionText: String?
    
    var followers: Int? {
        get {
            return edge_followed_by?.count
        }
    }
    
    var followStatus: FollowStatus?
    var yourPostsLikes: Int?
    var connectionsCount: Int?
    
    var isGoodSuggested: Bool {
        guard let description = descriptionText else { return true }
        if description.lowercased() == "suggested for you" {
            return true
        } else if description.lowercased().contains("followed by") && description.lowercased().contains("more") {
            return true
        } else {
            return false
        }
    }
    
    static func ==(lhs: GraphUser, rhs: GraphUser) -> Bool {
        return lhs.username == rhs.username
    }
    
    static func < (lhs: GraphUser, rhs: GraphUser) -> Bool {
        return (lhs.full_name ?? "") < (rhs.full_name ?? "")
    }
}

struct EdgeFollowedBy: Codable {
    let count: Int?
}
