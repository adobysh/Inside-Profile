//
//  LimitedUserModel.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 1/4/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import Foundation

class LimitedUserModel {

    static func lostFollowersApproxCount(_ followerCount: Int?) -> Int? {
        guard let followerCount = followerCount else { return nil }
        return Int(Double(followerCount) * 0.029)
    }
    
    static func gainedFollowersApproxCount(_ followerCount: Int?) -> Int? {
        guard let followerCount = followerCount else { return nil }
        return Int(Double(followerCount) * 0.073)
    }
    
    static func youDontFollowApproxCount(_ followingCount: Int?) -> Int? {
        guard let followingCount = followingCount else { return nil }
        return Int(Double(followingCount) * 0.206)
    }
    
    static func unfollowersApproxCount(_ followerCount: Int?) -> Int? {
        guard let followerCount = followerCount else { return nil }
        return Int(Double(followerCount) * 0.118)
    }
    
}
