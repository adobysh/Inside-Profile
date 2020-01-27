//
//  ProfileInfoData.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/6/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

struct ProfileInfoData: Codable {
    let pk: Int?
    let profile_pic_url: String?
    let follower_count: Int?
    let following_count: Int?
    let username: String?
    let full_name: String?
    let hd_profile_pic_url_info: HDProfilePicUrlInfo?
    
    var id: String? {
        get {
            guard let pk = pk else { return nil }
            return "\(pk)"
        }
    }
}

struct HDProfilePicUrlInfo: Codable {
    let width: Int?
    let height: Int?
    let url: String?
}

//{
//    "pk": 12963841448,
//    "username": "andrey_dobysh",
//    "full_name": "Андрей Добыш",
//    "is_private": false,
//    "profile_pic_url": "https://scontent-frt3-1.cdninstagram.com/vp/ba74a3d9af0377b16894a727e31f0082/5E22E2F6/t51.2885-19/s150x150/57939602_320190515311158_851945645500530688_n.jpg?_nc_ht=scontent-frt3-1.cdninstagram.com",
//    "profile_pic_id": "2025454396212902320_12963841448",
//    "is_verified": false,
//    "has_anonymous_profile_picture": false,
//    "media_count": 10,
//    "follower_count": 54,
//    "following_count": 58,
//    "following_tag_count": 0,
//    "biography": "",
//    "can_link_entities_in_bio": true,
//    "biography_with_entities": {
//        "raw_text": "",
//        "entities": []
//    },
//    "external_url": "",
//    "can_boost_post": false,
//    "can_see_organic_insights": false,
//    "show_insights_terms": false,
//    "can_convert_to_business": true,
//    "can_create_sponsor_tags": false,
//    "can_be_tagged_as_sponsor": false,
//    "total_igtv_videos": 0,
//    "total_ar_effects": 0,
//    "reel_auto_archive": "on",
//    "is_profile_action_needed": false,
//    "usertags_count": 0,
//    "usertag_review_enabled": false,
//    "is_needy": true,
//    "is_interest_account": false,
//    "has_recommend_accounts": false,
//    "has_chaining": true,
//    "hd_profile_pic_versions": [
//        {
//            "width": 320,
//            "height": 320,
//            "url": "https://scontent-frt3-1.cdninstagram.com/vp/b6ab0d66b06caa5f4073ef1fe90f4081/5E2798FB/t51.2885-19/s320x320/57939602_320190515311158_851945645500530688_n.jpg?_nc_ht=scontent-frt3-1.cdninstagram.com"
//        },
//        {
//            "width": 640,
//            "height": 640,
//            "url": "https://scontent-frt3-1.cdninstagram.com/vp/f6b716204b543982bef9d838665ce073/5E251296/t51.2885-19/s640x640/57939602_320190515311158_851945645500530688_n.jpg?_nc_ht=scontent-frt3-1.cdninstagram.com"
//        }
//    ],
//    "hd_profile_pic_url_info": {
//        "url": "https://scontent-frt3-1.cdninstagram.com/vp/f131dcd8a29bfc31f727303219bd8b0e/5E1B0D42/t51.2885-19/57939602_320190515311158_851945645500530688_n.jpg?_nc_ht=scontent-frt3-1.cdninstagram.com",
//        "width": 1080,
//        "height": 1080
//    },
//    "has_placed_orders": false,
//    "can_tag_products_from_merchants": false,
//    "show_conversion_edit_entry": true,
//    "aggregate_promote_engagement": true,
//    "allowed_commenter_type": "any",
//    "is_video_creator": false,
//    "has_profile_video_feed": false,
//    "has_highlight_reels": true,
//    "is_eligible_to_show_fb_cross_sharing_nux": true,
//    "page_id_for_new_suma_biz_account": null,
//    "eligible_shopping_signup_entrypoints": [],
//    "can_be_reported_as_fraud": false,
//    "is_business": false,
//    "account_type": 1,
//    "is_call_to_action_enabled": null,
//    "linked_fb_info": {
//        "linked_fb_user": {
//            "id": 100001686710114,
//            "name": "Andrei Dobysh"
//        }
//    },
//    "include_direct_blacklist_status": true,
//    "can_follow_hashtag": true,
//    "is_potential_business": false,
//    "feed_post_reshare_disabled": false,
//    "besties_count": 0,
//    "show_besties_badge": true,
//    "recently_bestied_by_count": 0,
//    "nametag": {
//        "mode": 1,
//        "gradient": 0,
//        "emoji": "😀",
//        "selfie_sticker": 0
//    },
//    "existing_user_age_collection_enabled": false,
//    "auto_expand_chaining": false,
//    "highlight_reshare_disabled": false,
//    "show_post_insights_entry_point": false,
//    "about_your_account_bloks_entrypoint_enabled": false
//}
