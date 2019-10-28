//
//  UserModel.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/22/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

class UserModel {
    
    #warning("первый рабочий вариант гостей. нужна доработка")
    public static func newGuests(_ username: String?, _ userDirectSearch: [ApiUser]?, _ topLikersFriends: [ApiUser]?, _ suggestedUsers: [GraphUser]?, _ myFollowing: [ApiUser]?, _ myFollowers: [ApiUser]?) -> (guests: [User]?, guestsIds: [String]?) {
        guard (myFollowing?.count ?? 0) != 0
            && (myFollowers?.count ?? 0) != 0
            && (userDirectSearch?.count ?? 0) != 0 else { return (nil, nil) }
        
        let guestsIds = GuestsManager.shared.getIds()
        if !guestsIds.isEmpty {
            return (nil, guestsIds)
        }
        
        print("!!! topLiker friends finish total count \(topLikersFriends?.count ?? 0)")
        
        var topLikersFriendsI_dont_follow: [ApiUser] = []
        (topLikersFriends ?? []).forEach { user in
            if myFollowing?.first(where: { $0.id == user.id }) == nil {
                topLikersFriendsI_dont_follow.append(user)
            }
        }
        
        
        // ----------
        // Вот они, 4 списка из которых мы формируем список гостей
        // Первые 2 для тех на кого я не подписан
        // Вторые 2 для тех на кого я подписан
        let suggestedUsersNotNil = suggestedUsers ?? []
//        var topLikersFriendsI_dont_follow
        let userDirectSearchCommon = (userDirectSearch?.filter { $0.is_verified == false } ?? [])
        let myFriends = UserModel.friends(myFollowing, myFollowers)
        
        
        // главные списки делим на хорошие и плохие половинки
        let suggestedUsersTwoHalfs = suggestedUsersNotNil.split()
        let userDirectSearchTwoHalfs = userDirectSearchCommon.split()
        
        
        // наполняем два списка источника с упровляемым смешиванием
        // seed для рандома будет меняться каждую неделю
        let year = Calendar.current.component(.year, from: Date())
        let weekOfYear = Calendar.current.component(.weekOfYear, from: Date())
        let seed = year + weekOfYear
        var usersI_DontFollow: [User] = []
        usersI_DontFollow.append(contentsOf: suggestedUsersTwoHalfs.first?.shuffle(seed: seed) ?? [])
        usersI_DontFollow.append(contentsOf: suggestedUsersTwoHalfs.last?.shuffle(seed: seed) ?? [])
        usersI_DontFollow.append(contentsOf: topLikersFriendsI_dont_follow.shuffle(seed: seed))
        var usersI_Follow: [User] = []
        usersI_Follow.append(contentsOf: userDirectSearchTwoHalfs.first?.shuffle(seed: seed) ?? [])
        usersI_Follow.append(contentsOf: userDirectSearchTwoHalfs.last?.shuffle(seed: seed) ?? [])
        usersI_Follow.append(contentsOf: myFriends.shuffle(seed: seed))
        
        
        // количество гостей это колличество подписчеков * 0.05
        // у Коли это соотношение 1800 : 236 но в этих гостях есть боты а ботов мы стараемся не показывать, поэтому у нас оно меньше
        let guestCount = Double(myFollowers?.count ?? 0) * Double.random(in: 0.1 ..< 0.15)
        print("!!! ggg guestCount \(guestCount)")
        
        let followersAndFollowingCount = Double(myFollowing?.count ?? 0) + Double(myFollowers?.count ?? 0)
        print("!!! ggg followersAndFollowingCount \(followersAndFollowingCount)")
        
        // отношение подписчиков к подпискам
        // оно будет определять соотношение подписчиков к подпискам среди гостей
        let followerToFollowingK = Double(myFollowers?.count ?? 0) / followersAndFollowingCount
        print("!!! ggg followerToFollowingK \(followerToFollowingK)")
        
        let guests_I_do_not_following_count: Int = Int( guestCount * followerToFollowingK )
        let guests_I_following_count: Int = Int( guestCount * (1.0 - followerToFollowingK) )
        print("!!! ggg guests_I_do_not_following_count \(guests_I_do_not_following_count)")
        print("!!! ggg guests_I_following_count \(guests_I_following_count)")
        
        var theGuestsWithDublicates: [User] = []
        
        // guests_I_do_not_following
        theGuestsWithDublicates.append(contentsOf: Array(usersI_DontFollow.prefix(guests_I_do_not_following_count)))
        
        // guests_I_following
        theGuestsWithDublicates.append(contentsOf: Array(usersI_Follow.prefix(guests_I_following_count)))
        
        // удалить меня из списка
        theGuestsWithDublicates = theGuestsWithDublicates.filter { $0.username != username }
        
        
        // удалить дубли
        let uniqueGuestsIds = Array(Set(theGuestsWithDublicates.compactMap { $0.id }))
        var theGuests: [User] = []
        uniqueGuestsIds.forEach { guestId in
            if let uniqueGuest = theGuestsWithDublicates.first(where: { $0.id == guestId }) {
                theGuests.append(uniqueGuest)
            }
        }
        
        GuestsManager.shared.save(theGuests.compactMap { $0.id })
        return (theGuests, nil)
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
            if var uniqueUser = usersWithDublicates.first(where: { $0.id == userId }) {
                uniqueUser.yourPostsLikes = count
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

// MARK: - For Array Of Users
extension UserModel {
    
    public static func friends(_ following: [ApiUser]?, _ followers: [ApiUser]?) -> [ApiUser] {
        guard let following = following, let followers = followers else { return [] }
        
        var friendsWithDublicates: [ApiUser] = []
        friendsWithDublicates.append(contentsOf: following)
        friendsWithDublicates.append(contentsOf: followers)
        
        let userIds = Array(Set(friendsWithDublicates.map { $0.id }))
        var friends: [ApiUser] = []
        userIds.forEach { userId in
            let count = friendsWithDublicates.filter { $0.id == userId }.count
            if count == 2, let uniqueUser = friendsWithDublicates.first(where: { $0.id == userId }) {
                friends.append(uniqueUser)
            }
        }
        return friends
    }
    
}
