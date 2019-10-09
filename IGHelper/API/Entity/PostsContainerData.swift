//
//  PostsContainerData.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/8/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

struct PostsContainerData: Codable {
    let itemsCount: Int?
    let feed: [PostData?]?
    let state: String?
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
//        "id": 12963841448,
//        "moreAvailable": false
//    }
//}

// --------

struct PostData: Codable {
    let like_count: Int?
    let comment_count: Int?
}

//{
//    "taken_at": 1563571693,
//    "pk": "2091713432717620072",
//    "id": "2091713432717620072_12963841448",
//    "device_timestamp": "1563571202396725",
//    "media_type": 1,
//    "code": "B0HQkjhC_No",
//    "client_cache_key": "MjA5MTcxMzQzMjcxNzYyMDA3Mg==.2",
//    "filter_type": 0,
//    "image_versions2": {
//        "candidates": [
//            {
//                "width": 1080,
//                "height": 1078,
//                "url": "https://scontent-frt3-1.cdninstagram.com/vp/4b9ed7af8dfa0dd4ef82bbba0462d4c7/5E18D31C/t51.2885-15/e35/s1080x1080/66817405_144605743299840_2148967914902969235_n.jpg?_nc_ht=scontent-frt3-1.cdninstagram.com&_nc_cat=100&ig_cache_key=MjA5MTcxMzQzMjcxNzYyMDA3Mg%3D%3D.2",
//                "estimated_scans_sizes": [
//                    18988,
//                    37976,
//                    56964,
//                    75952,
//                    94940,
//                    106238,
//                    135192,
//                    153652,
//                    170893
//                ]
//            },
//            {
//                "width": 320,
//                "height": 319,
//                "url": "https://scontent-frt3-1.cdninstagram.com/vp/a625d235fec8d6af0f30dbfb115b200c/5E3AFCFC/t51.2885-15/e35/s320x320/66817405_144605743299840_2148967914902969235_n.jpg?_nc_ht=scontent-frt3-1.cdninstagram.com&_nc_cat=100&ig_cache_key=MjA5MTcxMzQzMjcxNzYyMDA3Mg%3D%3D.2",
//                "estimated_scans_sizes": [
//                    2562,
//                    5124,
//                    7686,
//                    10248,
//                    12810,
//                    15422,
//                    445063,
//                    23058,
//                    23058
//                ]
//            }
//        ]
//    },
//    "original_width": 1440,
//    "original_height": 1438,
//    "location": {
//        "pk": 404963956917552,
//        "name": "The United Pub",
//        "address": "",
//        "city": "",
//        "short_name": "The United Pub",
//        "lng": 27.652656222763,
//        "lat": 53.934583569325,
//        "external_source": "facebook_places",
//        "facebook_places_id": 404963956917552
//    },
//    "lat": 53.934583569325,
//    "lng": 27.652656222763,
//    "user": {
//        "pk": 12963841448,
//        "username": "andrey_dobysh",
//        "full_name": "Андрей Добыш",
//        "is_private": false,
//        "profile_pic_url": "https://scontent-frt3-1.cdninstagram.com/vp/ba74a3d9af0377b16894a727e31f0082/5E22E2F6/t51.2885-19/s150x150/57939602_320190515311158_851945645500530688_n.jpg?_nc_ht=scontent-frt3-1.cdninstagram.com",
//        "profile_pic_id": "2025454396212902320_12963841448",
//        "is_verified": false,
//        "has_anonymous_profile_picture": false,
//        "can_boost_post": false,
//        "can_see_organic_insights": false,
//        "show_insights_terms": false,
//        "reel_auto_archive": "on",
//        "is_unpublished": false,
//        "allowed_commenter_type": "any",
//        "latest_reel_media": 0
//    },
//    "can_viewer_reshare": true,
//    "caption_is_edited": false,
//    "direct_reply_to_author_enabled": true,
//    "comment_likes_enabled": true,
//    "comment_threading_enabled": true,
//    "has_more_comments": false,
//    "max_num_visible_preview_comments": 2,
//    "preview_comments": [],
//    "can_view_more_preview_comments": false,
//    "comment_count": 0,
//    "inline_composer_display_condition": "impression_trigger",
//    "inline_composer_imp_trigger_time": 4,
//    "like_count": 19,
//    "has_liked": false,
//    "top_likers": [
//        "_nickolas.kelly"
//    ],
//    "facepile_top_likers": [
//        {
//            "pk": 1558495788,
//            "username": "_nickolas.kelly",
//            "full_name": "Николай",
//            "is_private": false,
//            "profile_pic_url": "https://scontent-frt3-1.cdninstagram.com/vp/f1c3bf9804a8898a377e42020781eaff/5E38ED6C/t51.2885-19/s150x150/67799247_1277871082387477_8623727506354077696_n.jpg?_nc_ht=scontent-frt3-1.cdninstagram.com",
//            "profile_pic_id": "2115410185501270602_1558495788",
//            "is_verified": false
//        },
//        {
//            "pk": 2009321819,
//            "username": "lizaveta_glazina",
//            "full_name": "lizaveta glazina",
//            "is_private": false,
//            "profile_pic_url": "https://scontent-frt3-1.cdninstagram.com/vp/0920b4e23ea250b38b8ead743b1df528/5E1A62BB/t51.2885-19/s150x150/21149560_789395047906554_7038732815755640832_a.jpg?_nc_ht=scontent-frt3-1.cdninstagram.com",
//            "profile_pic_id": "1592222128555764427_2009321819",
//            "is_verified": false
//        },
//        {
//            "pk": 9643832965,
//            "username": "dmelnichenok",
//            "full_name": "Дмитрий Анатольевич",
//            "is_private": true,
//            "profile_pic_url": "https://scontent-frt3-1.cdninstagram.com/vp/247c84531550748b708025d41e2726d7/5E2C7B9D/t51.2885-19/s150x150/46991028_278291939536208_6265641863571570688_n.jpg?_nc_ht=scontent-frt3-1.cdninstagram.com",
//            "profile_pic_id": "1936971125003149265_9643832965",
//            "is_verified": false
//        }
//    ],
//    "photo_of_you": false,
//    "caption": {
//        "pk": "17894252209361939",
//        "user_id": 12963841448,
//        "text": "Bitter truth or sweet lie 🤷🏽‍♂️ Горькая правда или сладкая ложь (The Matrix ❤️)",
//        "type": 1,
//        "created_at": 1563571696,
//        "created_at_utc": 1563571696,
//        "content_type": "comment",
//        "status": "Active",
//        "bit_flags": 0,
//        "user": {
//            "pk": 12963841448,
//            "username": "andrey_dobysh",
//            "full_name": "Андрей Добыш",
//            "is_private": false,
//            "profile_pic_url": "https://scontent-frt3-1.cdninstagram.com/vp/ba74a3d9af0377b16894a727e31f0082/5E22E2F6/t51.2885-19/s150x150/57939602_320190515311158_851945645500530688_n.jpg?_nc_ht=scontent-frt3-1.cdninstagram.com",
//            "profile_pic_id": "2025454396212902320_12963841448",
//            "is_verified": false,
//            "has_anonymous_profile_picture": false,
//            "can_boost_post": false,
//            "can_see_organic_insights": false,
//            "show_insights_terms": false,
//            "reel_auto_archive": "on",
//            "is_unpublished": false,
//            "allowed_commenter_type": "any",
//            "latest_reel_media": 0
//        },
//        "did_report_as_spam": false,
//        "share_enabled": false,
//        "media_id": "2091713432717620072",
//        "has_translation": true
//    },
//    "fb_user_tags": {
//        "in": []
//    },
//    "can_viewer_save": true,
//    "organic_tracking_token": "eyJ2ZXJzaW9uIjo1LCJwYXlsb2FkIjp7ImlzX2FuYWx5dGljc190cmFja2VkIjpmYWxzZSwidXVpZCI6IjhkOWJjYzdjYTJiZDQ5ZmVhZTE0MmI4YWRhZDNjNzdhMjA5MTcxMzQzMjcxNzYyMDA3MiIsInNlcnZlcl90b2tlbiI6IjE1NzA1MTgxNTk5MzR8MjA5MTcxMzQzMjcxNzYyMDA3MnwxMjk2Mzg0MTQ0OHw0MTIyYjNkMTgzYjM1NDAzZTkxNzFmOTdkN2FkMWVmYTkwNmZlNmI4ZWIwYTBkNTI5ODFjMmY4YTVhN2FjYzkyIn0sInNpZ25hdHVyZSI6IiJ9"
//}
