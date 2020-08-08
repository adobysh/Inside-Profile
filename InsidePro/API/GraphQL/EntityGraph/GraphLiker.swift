//
//  GraphLiker.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 1/28/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import Foundation

struct GraphLikersContainer: Codable {
    let data: GraphLikersContainer_Data?
    let status: String? // "ok"
    
    var has_next_page: Bool? {
        return data?.shortcode_media?.edge_liked_by?.page_info?.has_next_page
    }
    
    var end_cursor: String? {
        return data?.shortcode_media?.edge_liked_by?.page_info?.end_cursor
    }
    
    var likers: [GraphUser]? {
        return data?.shortcode_media?.edge_liked_by?.edges?.compactMap { $0?.node }
    }
}

struct GraphLikersContainer_Data: Codable {
    let shortcode_media: GraphLikersContainer_Data_ShortcodeMedia?
}

struct GraphLikersContainer_Data_ShortcodeMedia: Codable {
//    let id: String? // "2148618321395098673",
//    let shortcode: String? // "B3RbPq8pqQx",
    let edge_liked_by: GraphLikersContainer_Data_ShortcodeMedia_EdgeLikedBy?
}

struct GraphLikersContainer_Data_ShortcodeMedia_EdgeLikedBy: Codable {
    let count: Int?
    let page_info: GraphLikersContainer_Data_ShortcodeMedia_EdgeLikedBy_PageInfo?
    let edges: [GraphLikersContainer_Data_ShortcodeMedia_EdgeLikedBy_Edge?]?
}

struct GraphLikersContainer_Data_ShortcodeMedia_EdgeLikedBy_PageInfo: Codable {
    let has_next_page: Bool?
    let end_cursor: String?
}

struct GraphLikersContainer_Data_ShortcodeMedia_EdgeLikedBy_Edge: Codable {
    let node: GraphUser?
}

//struct GraphLiker: User, Codable {
//    var profile_pic_url: String?
//    var is_verified: Bool?
//    var followers: Int?
//    var descriptionText: String?
//    var followStatus: FollowStatus?
//    var yourPostsLikes: Int?
//    var connectionsCount: Int?
//
//    let id: String? // "18049047967",
//    let username: String? // "elenah2904",
//    let full_name: String? // "elena",
//
//    enum CodingKeys: String, CodingKey {
//        case id
//        case username
//        case full_name
//    }
//}
