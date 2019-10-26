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
        return suggestedUser?.filter { $0.is_verified == false } ?? []
    }

    #warning("незначительная проблема")
    // незначительная проблема: это выборка не из всех коментаторов а только из тех что видны в превьюшках постов, примерно каждые 3 комментария поста
    // Из спецификации:
    // 5. Фича «Топ лайкеры»
    // Алгоритм высчитывает общее колиечств лайков на всех постах и показывает топ 10
    // человек с наибольшим количеством лайков
    // 6. Фича «Топ комментаторов»
    // Аналогично с пунктом 5 только дело касается комментов а не лайков
    public static func topCommenters(_ username: String?, _ posts: [PostData]?) -> [ApiUser] {
        let usersWithDublicates = posts?.compactMap { $0.preview_comments }.flatMap { $0 }.compactMap { $0.user } ?? []
        let userIds = Array(Set(usersWithDublicates.compactMap { $0.id }))
        var users: [(user: ApiUser, count: Int)] = []
        userIds.forEach { userId in
            let count = usersWithDublicates.filter { $0.id == userId }.count
            if let uniqueUser = usersWithDublicates.first(where: { $0.id == userId }) {
                users.append((uniqueUser, count))
            }
        }
        users = users.sorted(by: { $0.count > $1.count  })
        users = users.filter { $0.user.username != username } // remove own account
        return Array(users.map { $0.user }.prefix(10)) // first 10 elements
    }
    
    #warning("незначительная проблема")
    // незначительная проблема: проверить являются ли topLikers из терминалогии api инстаграма действительно людьми которые тебя чаще лайкают
    public static func topLikers(_ username: String?, _ posts: [PostData]?) -> [ApiUser] {
        let usersWithDublicates = posts?.compactMap { $0.facepile_top_likers }.flatMap { $0 } ?? []
        let userIds = Array(Set(usersWithDublicates.compactMap { $0.id }))
        var users: [(user: ApiUser, count: Int)] = []
        userIds.forEach { userId in
            let count = usersWithDublicates.filter { $0.id == userId }.count
            if let uniqueUser = usersWithDublicates.first(where: { $0.id == userId }) {
                users.append((uniqueUser, count))
            }
        }
        users = users.sorted(by: { $0.count > $1.count  })
        users = users.filter { $0.user.username != username } // remove own account
        return Array(users.map { $0.user }.prefix(10)) // first 10 elements
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
        guard let followers = followers else { return [] }
        let currentFollowersIds = followers.compactMap { $0.id }
        return previousFollowersIds.filter { !currentFollowersIds.contains($0) }
    }
    
}

// MARK: - For Single User
extension UserModel {
    
    public static func addFollowStatus(_ user: User, _ following: [ApiUser]?, _ followRequests: FollowRequests?) -> User {
        let isFollowing: Bool = following?.first { $0.id == user.id } != nil
        let isRequested: Bool = followRequests?.contain(username: user.username ?? "") == true
    
        let followStatus: FollowStatus
        if isFollowing {
            followStatus = .yes
        } else if isRequested {
            followStatus = .requested
        } else {
            followStatus = .no
        }
        var userWithFollowStatus = user
        userWithFollowStatus.followStatus = followStatus
        return userWithFollowStatus
    }
    
}
