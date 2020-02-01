//
//  GraphFollowing.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 1/30/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import Foundation

struct GraphFollowingsContainer: Codable {
    let data: GraphFollowingsContainer_Data?
    let status: String? // "ok"
    
    var has_next_page: Bool? {
        return data?.user?.edge_follow?.page_info?.has_next_page
    }
    
    var  end_cursor: String? {
        return data?.user?.edge_follow?.page_info?.end_cursor
    }
    
    var followings: [GraphUser]? {
        return data?.user?.edge_follow?.edges.compactMap { $0?.node }
    }
}

struct GraphFollowingsContainer_Data: Codable {
    let user: GraphFollowingsContainer_Data_User?
}

struct GraphFollowingsContainer_Data_User: Codable {
    let edge_follow: GraphFollowingsContainer_Data_User_EdgeFollow?
}

struct GraphFollowingsContainer_Data_User_EdgeFollow: Codable {
    let count: Int?
    let page_info: GraphFollowingsContainer_Data_User_EdgeFollow_PageInfo?
    let edges: [GraphFollowingsContainer_Data_User_EdgeFollow_Edge?]
}

struct GraphFollowingsContainer_Data_User_EdgeFollow_PageInfo: Codable {
    let has_next_page: Bool?
    let end_cursor: String?
}

struct GraphFollowingsContainer_Data_User_EdgeFollow_Edge: Codable {
    let node: GraphUser?
}
