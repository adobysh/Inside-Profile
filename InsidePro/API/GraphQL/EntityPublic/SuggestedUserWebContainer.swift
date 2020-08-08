//
//  SuggestedUserContainerWebData.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/16/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

struct SuggestedUsersWebContainer: Codable {
    let data: SuggestedUsersWebContainerData?
    let status: String? // "ok"
}

struct SuggestedUsersWebContainerData: Codable {
    let user: SuggestedUsersWebContainerUser?
}

struct SuggestedUsersWebContainerUser: Codable {
//    let connected_fbid: String? // null
//    let edge_facebook_friends: ?
    let edge_suggested_users: EdgeSuggestedUsers?
}

struct EdgeSuggestedUsers: Codable {
    let page_info: SuggestedUsersPageInfo?
    let edges: [SuggestedUserContainer]?
}

struct SuggestedUsersPageInfo: Codable {
    let has_next_page: Bool?
}

struct SuggestedUserContainer: Codable {
    let node: SuggestedUserNode?
}

struct SuggestedUserNode: Codable {
    let user: GraphUser?
    let description: String? // Followed by lizaveta_glazina
}
