//
//  GraphFollowers.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 1/30/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import Foundation

struct GraphFollowersContainer: Codable {
    let data: GraphFollowersContainer_Data?
    let status: String? // "ok"
    
    var has_next_page: Bool? {
        return data?.user?.edge_followed_by?.page_info?.has_next_page
    }
    
    var  end_cursor: String? {
        return data?.user?.edge_followed_by?.page_info?.end_cursor
    }
    
    var followers: [GraphUser]? {
        return data?.user?.edge_followed_by?.edges.compactMap { $0?.node }
    }
}

struct GraphFollowersContainer_Data: Codable {
    let user: GraphFollowersContainer_Data_User?
}

struct GraphFollowersContainer_Data_User: Codable {
    let edge_followed_by: GraphFollowersContainer_Data_User_EdgeFollowedBy?
}

struct GraphFollowersContainer_Data_User_EdgeFollowedBy: Codable {
    let count: Int?
    let page_info: GraphFollowersContainer_Data_User_EdgeFollowedBy_PageInfo?
    let edges: [GraphFollowersContainer_Data_User_EdgeFollowedBy_Edge?]
}

struct GraphFollowersContainer_Data_User_EdgeFollowedBy_PageInfo: Codable {
    let has_next_page: Bool?
    let end_cursor: String?
}

struct GraphFollowersContainer_Data_User_EdgeFollowedBy_Edge: Codable {
    let node: GraphUser?
}
