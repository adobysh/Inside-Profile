//
//  UserModel.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/22/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

class UserModel {
    
    // пока показываем рекомендуемых пользователей кроме:
    // 1. подтверждённых аккаунтов
    // 2. пользователи с более чем 1к подписчиков
    #warning("нужна серьёзная доработка")
    public static func newGuests(_ suggestedUser: [GraphUser]?) -> [GraphUser] {
        return suggestedUser?.filter { $0.is_verified == false && ($0.followers ?? 0) < 500 } ?? []
    }

    #warning("Пока считаем просто всех коментаторов")
    public static func topCommenters(_ posts: [PostData]?) -> [ApiUser] {
        let usersWithDublicates = posts?.compactMap { $0.preview_comments }.flatMap { $0 }.compactMap { $0.user } ?? []
        let userIds = Array(Set(usersWithDublicates.compactMap { $0.id }))
        var users: [ApiUser] = []
        userIds.forEach { userId in
            if let uniqueUser = usersWithDublicates.first(where: { $0.id == userId }) {
                users.append(uniqueUser)
            }
        }
        return users
    }
    
    // незначительная проблема: проверить являются ли topLikers из терминалогии api инстаграма действительно людьми которые тебя чаще лайкают
    public static func topLikers(_ posts: [PostData]?) -> [ApiUser] {
        let usersWithDublicates = posts?.compactMap { $0.facepile_top_likers }.flatMap { $0 } ?? []
        let userIds = Array(Set(usersWithDublicates.compactMap { $0.id }))
        var users: [ApiUser] = []
        userIds.forEach { userId in
            if let uniqueUser = usersWithDublicates.first(where: { $0.id == userId }) {
                users.append(uniqueUser)
            }
        }
        return users
    }
    
    public static func youDontFollow(followers: [ApiUser]?, following: [ApiUser]?) -> [ApiUser] {
        return followers?.filter({ !(following ?? []).contains($0) }) ?? []
    }
    
    public static func unfollowers(followers: [ApiUser]?, following: [ApiUser]?) -> [ApiUser] {
        return following?.filter({ !(followers ?? []).contains($0) }) ?? []
    }
    
    public static func gainedFollowers(_ previousFollowersIds: [String], _ followers: [ApiUser]?) -> [ApiUser] {
        return followers?.filter { !previousFollowersIds.contains($0.id ?? "") } ?? []
    }
    
    public static func lostFollowersIds(_ previousFollowersIds: [String], _ followers: [ApiUser]?) -> [String] {
        let currentFollowersIds = followers?.compactMap { $0.id } ?? []
        return previousFollowersIds.filter { !currentFollowersIds.contains($0) }
    }
    
}
