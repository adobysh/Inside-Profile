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
        let result = Int(Double(followerCount) * 0.001)
        return Int(Double(result) / 10.0) * 10
    }
    
    static func gainedFollowersApproxCount(_ followerCount: Int?) -> Int? {
        guard let followerCount = followerCount else { return nil }
        let result = Int(Double(followerCount) * 0.008)
        return Int(Double(result) / 10.0) * 10
    }
    
    static func youDontFollowApproxCount(followerCount: Int?, followingCount: Int?) -> Int? {
        guard let followingCount = followingCount, let followerCount = followerCount else { return nil }
        
        let a = abs(followerCount - followingCount)
        
        let result = Int( Double(a) * 1.01 )
        return Int(Double(result) / 10.0) * 10
    }
    
    static func unfollowersApproxCount(followingCount: Int?) -> Int? {
        guard let followingCount = followingCount else { return nil }
        let result = Int(Double(followingCount) * 0.029)
        return Int(Double(result) / 10.0) * 10
    }
    
}
