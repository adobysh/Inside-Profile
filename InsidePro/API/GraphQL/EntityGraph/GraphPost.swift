//
//  GraphPost.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 1/28/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import Foundation

struct GraphPostsContainer: Codable {
    let data: GraphPostsContainerLevel1?
    let status: String? // "ok"
    
    var has_next_page: Bool? {
        return data?.user?.edge_owner_to_timeline_media?.page_info?.has_next_page
    }
    
    var end_cursor: String? {
        return data?.user?.edge_owner_to_timeline_media?.page_info?.end_cursor
    }
    
    var posts: [GraphPost]? {
        return data?.user?.edge_owner_to_timeline_media?.edges?.compactMap { $0?.node }
    }
}

struct GraphPostsContainerLevel1: Codable {
    let user: GraphPostsContainerLevel2?
}

struct GraphPostsContainerLevel2: Codable {
    let edge_owner_to_timeline_media: GraphPostsContainerLevel3?
}

struct GraphPostsContainerLevel3: Codable {
    let count: Int?
    let page_info: PageInfo?
    let edges: [Edge?]?
}

struct PageInfo: Codable {
    let has_next_page: Bool?
    let end_cursor: String? // "QVFES1J3ZDhvRm1mTDB4bktEX19wMElWZHFVR1BIQTBKOXM0UXBzYmpYelN5bHNOVFZ6V2dJd3BpaXJWTUlWSURWb2xqd0Y4WGpGdTRzYjNLZV9oS2RRYg=="
}

struct Edge: Codable {
    let node: GraphPost?
}

struct GraphPost: Codable {
    let shortcode: String? // "B3RbPq8pqQx" something like post id
    let edge_media_to_comment: Edge_media_to_comment?
    let edge_media_preview_like: Edge_media_preview_like?
    
    var like_count: Int? {
        return edge_media_preview_like?.count
    }
    
    var comment_count: Int? {
        return edge_media_to_comment?.count
    }
    
    var commenters: [CommentOwner]? {
        return edge_media_to_comment?.edges?.compactMap { $0?.node?.owner }
    }
    
    var likers: [GraphUser]?
}

struct Edge_media_to_comment: Codable {
    let count: Int?
//    "page_info": {
//        "has_next_page": false,
//        "end_cursor": null
//    },
    let edges: [CommentEdge?]?
}

struct CommentEdge: Codable {
    let node: CommentNode?
}

struct CommentNode: Codable {
//    "id": "17889146125412943",
//    "text": "Любимые места 😻",
//    "created_at": 1570375872,
//    "did_report_as_spam": false,
//    "owner": {
//        "id": "1520199998",
//        "is_verified": false,
//        "profile_pic_url": "https://blablabla",
//        "username": "a.aysberg"
//    },
//    "viewer_has_liked": false
    let owner: CommentOwner?
}

struct CommentOwner: User, Codable {
    var full_name: String?
    var followers: Int?
    var descriptionText: String?
    var followStatus: FollowStatus?
    var yourPostsLikes: Int?
    var connectionsCount: Int?
    
    let id: String?
    let is_verified: Bool?
    let profile_pic_url: String?
    let username: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case is_verified
        case profile_pic_url
        case username
    }
}

struct Edge_media_preview_like: Codable {
    let count: Int?
//    let edges: [LikeEdge?]? forever empty
}
