//
//  SuggestedUserData.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/9/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

struct SuggestedUserContainerData: Codable {
//    let itemsCount: Int?
    let feed: [SuggestedUserData?]?
//    let state: String?
    //let stateObject: StateObjectData?
}

//{
//    "itemsCount": 10,
//    "feed": [],
//    "state": "{\"moreAvailable\":false,\"rankToken\":\"63e8d12e-51b7-584b-8d2e-b693075c88f0\"}",
//    "stateObject": {
//        "attemptOptions": {
//            "delay": 60000,
//            "factor": 1.5,
//            "maxAttempts": 10,
//            "minDelay": 60000,
//            "maxDelay": 300000,
//            "jitter": true
//        },
//        "rankToken": "63e8d12e-51b7-584b-8d2e-b693075c88f0",
//        "moreAvailable": false
//    }
//}

// ---

struct SuggestedUserData: Codable {
    let user: UserData?
}

//{
//    "user": {
//        "pk": "1247439238",
//        "username": "slivkiby",
//        "full_name": "Сливки | Скидки | Распродажи",
//        "is_private": false,
//        "profile_pic_url": "https://scontent-frt3-1.cdninstagram.com/vp/56dd93d11a15286e4d32676433ec28d7/5E21B92E/t51.2885-19/s150x150/36596711_1591433554301346_2339149810579275776_n.jpg?_nc_ht=scontent-frt3-1.cdninstagram.com",
//        "profile_pic_id": "1824668046801150961_1247439238",
//        "is_verified": false,
//        "has_anonymous_profile_picture": false
//    },
//    "algorithm": "tfidf_city_algorithm",
//    "social_context": "Followed by _mallinovskaya_ + 8 more",
//    "icon": "",
//    "caption": "",
//    "media_ids": [],
//    "thumbnail_urls": [],
//    "large_urls": [],
//    "media_infos": [],
//    "value": 0.00021297,
//    "followed_by": false,
//    "is_new_suggestion": false,
//    "uuid": "12963841448|1570630163"
//},

// ---

struct UserData: Codable {
    let pk: String? // user id
    let username: String?
    let full_name: String?
    let profile_pic_url: String?
}

//    "user": {
//        "pk": "1247439238",
//        "username": "slivkiby",
//        "full_name": "Сливки | Скидки | Распродажи",
//        "is_private": false,
//        "profile_pic_url": "https://scontent-frt3-1.cdninstagram.com/vp/56dd93d11a15286e4d32676433ec28d7/5E21B92E/t51.2885-19/s150x150/36596711_1591433554301346_2339149810579275776_n.jpg?_nc_ht=scontent-frt3-1.cdninstagram.com",
//        "profile_pic_id": "1824668046801150961_1247439238",
//        "is_verified": false,
//        "has_anonymous_profile_picture": false
//    },
