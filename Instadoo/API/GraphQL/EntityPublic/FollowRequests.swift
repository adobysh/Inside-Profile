//
//  FollowRequests.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/23/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

struct FollowRequests {
    let value: String
    
    public func contain(username: String) -> Bool {
        return value.contains("\"text\":\"\(username)\"")
    }
}
