//
//  GraphProfileInfoData.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 1/23/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import Foundation

struct GraphProfile: Codable {
    let profile_pic_url: String?
    let follower_count: Int?
    let following_count: Int?
    let username: String?
    let full_name: String?
    let profile_pic_url_hd: String?
    let id: String?
    
    var limitedDataDownloadMode: Bool {
        let followerCount = follower_count ?? 0
        let followingCount = following_count ?? 0
        let limitedDataDownloadMode = isLimitedMode(followerCount, followingCount)
        return limitedDataDownloadMode
    }
    
}
