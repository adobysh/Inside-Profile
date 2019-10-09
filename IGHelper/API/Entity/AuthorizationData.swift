//
//  AuthorizationData.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/6/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

struct AuthorizationData: Codable {
    
    let ok: Int?
    let pk: Int?
    let cookies: String?
    let session: String?
    let error: String? // "bad_password" "invalid_user"
    
}
