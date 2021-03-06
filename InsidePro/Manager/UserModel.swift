//
//  UserModel.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/22/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

class UserModel {
    
    // Текущий алгоритм формирования списка гостей
    //
    // Исходные данные получаемые от инсты:
    // - userId
    // - username
    // - userDirectSearch (список)
    // - topLikersFriends (список)
    // - suggestedUsers (список)
    // - myFollowing (список)
    // - myFollowers (список)
//    public static func newGuests(_ userId: String, _ username: String?, _ userDirectSearch: [BaseUser]?, _ topLikersFriends: [GraphUser]?, _ suggestedUsers: [GraphUser]?, _ myFollowing: [GraphUser]?, _ myFollowers: [GraphUser]?) -> (guests: [User]?, guestsIds: [String]?) {
//        guard myFollowing?.isEmpty == false
//            && myFollowers?.isEmpty == false
//            && userDirectSearch?.isEmpty == false else { return (nil, nil) }
//        
//        // Сразу же проверяем есть ли сохраненные гости и если есть используем их
//        let guestsIds = GuestsManager.shared.getIds(userId)
//        if !guestsIds.isEmpty {
//            return (nil, guestsIds)
//        }
//        
//        var topLikersFriendsI_dont_follow: [GraphUser] = []
//        (topLikersFriends ?? []).forEach { user in
//            if myFollowing?.first(where: { $0.id == user.id }) == nil {
//                topLikersFriendsI_dont_follow.append(user)
//            }
//        }
//        
//        
//        // ----------
//        // Вот они, 4 списка из которых мы формируем список гостей
//        // Первые 2 для тех на кого я не подписан
//        // Вторые 2 для тех на кого я подписан
//        let suggestedUsersNotNil = suggestedUsers ?? []
////        var topLikersFriendsI_dont_follow
//        let userDirectSearchCommon = (userDirectSearch?.filter { $0.is_verified == false } ?? [])
//        let myFriends = UserModel.friends(myFollowing, myFollowers)
//        
//        
//        // главные списки делим на хорошие и плохие половинки
//        let suggestedUsersTwoHalfs = suggestedUsersNotNil.split(parts: 4)
//        
//        
//        // наполняем два списка источника с упровляемым смешиванием
//        // seed для рандома будет меняться каждую неделю
//        let year = Calendar.current.component(.year, from: Date())
//        let dayOfYear = Calendar.current.component(.day, from: Date())
//        let seed = year + dayOfYear
//        var usersI_Follow: [User] = []
//        usersI_Follow.append(contentsOf: userDirectSearchCommon)
//        usersI_Follow.append(contentsOf: myFriends.shuffle(seed: seed))
//        var usersI_DontFollow: [User] = []
//        usersI_DontFollow.append(contentsOf: suggestedUsersTwoHalfs[safe: 0]?.shuffle(seed: seed) ?? [])
//        usersI_DontFollow.append(contentsOf: suggestedUsersTwoHalfs[safe: 1]?.shuffle(seed: seed) ?? [])
//        usersI_DontFollow.append(contentsOf: suggestedUsersTwoHalfs[safe: 2]?.shuffle(seed: seed) ?? [])
//        usersI_DontFollow.append(contentsOf: suggestedUsersTwoHalfs[safe: 3]?.shuffle(seed: seed) ?? [])
//        usersI_DontFollow.append(contentsOf: suggestedUsersTwoHalfs[safe: 4]?.shuffle(seed: seed) ?? [])
//        usersI_DontFollow.append(contentsOf: topLikersFriendsI_dont_follow.shuffle(seed: seed))
//        
//        
//        // количество гостей это колличество подписчеков * 0.05
//        // у Коли это соотношение 1800 : 236 но в этих гостях есть боты а ботов мы стараемся не показывать, поэтому у нас оно меньше
//        // примерно 0.5 и это примерно за 3 дня
//        let guestCount = Double(myFollowers?.count ?? 0) * Double.random(in: 0.04 ..< 0.06)
//        print("!!! ggg guestCount \(guestCount)")
//        
//        let followersAndFollowingCount = Double(myFollowing?.count ?? 0) + Double(myFollowers?.count ?? 0)
//        print("!!! ggg followersAndFollowingCount \(followersAndFollowingCount)")
//        
//        // отношение подписчиков к подпискам
//        // оно будет определять соотношение подписчиков к подпискам среди гостей
//        let followerToFollowingK = Double(myFollowers?.count ?? 0) / followersAndFollowingCount
//        print("!!! ggg followerToFollowingK \(followerToFollowingK)")
//        
//        let guests_I_do_not_following_count: Int = Int( guestCount * followerToFollowingK )
//        let guests_I_following_count: Int = Int( guestCount * (1.0 - followerToFollowingK) )
//        print("!!! ggg guests_I_do_not_following_count \(guests_I_do_not_following_count)")
//        print("!!! ggg guests_I_following_count \(guests_I_following_count)")
//        
//        var theGuestsWithDublicates: [User] = []
//        
//        // guests_I_do_not_following
//        theGuestsWithDublicates.append(contentsOf: Array(usersI_DontFollow.prefix(guests_I_do_not_following_count)))
//        
//        // guests_I_following
//        theGuestsWithDublicates.append(contentsOf: Array(usersI_Follow.prefix(guests_I_following_count)))
//        
//        // удалить меня из списка
//        theGuestsWithDublicates = theGuestsWithDublicates.filter { $0.username != username }
//        
//        
//        // удалить дубли
//        let uniqueGuestsIds = Array(Set(theGuestsWithDublicates.compactMap { $0.id }))
//        var theGuests: [User] = []
//        uniqueGuestsIds.forEach { guestId in
//            if let uniqueGuest = theGuestsWithDublicates.first(where: { $0.id == guestId }) {
//                theGuests.append(uniqueGuest)
//            }
//        }
//        
//        theGuests = theGuests.shuffle(seed: seed)
//        
//        GuestsManager.shared.save(userId, theGuests.compactMap { $0.id })
//        return (theGuests, nil)
//    }

    #warning("незначительная проблема")
    // незначительная проблема: это выборка не из всех коментаторов а только из тех что видны в превьюшках постов, примерно каждые 3 комментария поста
    // Из спецификации:
    // 5. Фича «Топ лайкеры»
    // Алгоритм высчитывает общее колиечств лайков на всех постах и показывает топ 10
    // человек с наибольшим количеством лайков
    // 6. Фича «Топ комментаторов»
    // Аналогично с пунктом 5 только дело касается комментов а не лайков
    public static func topCommenters(_ username: String?, _ posts: [GraphPost]?, completion: @escaping ([User]) -> Void) {
        DispatchQueue.global().async {
            let usersWithDublicates = posts?.compactMap { $0.commenters }.flatMap { $0 } ?? []
            let userIds = Array(Set(usersWithDublicates.compactMap { $0.id }))
            var users: [(user: User, count: Int)] = []
            userIds.forEach { userId in
                let count = usersWithDublicates.filter { $0.id == userId }.count
                if let uniqueUser = usersWithDublicates.first(where: { $0.id == userId }) {
                    users.append((uniqueUser, count))
                }
            }
            users = users.sorted(by: { $0.count > $1.count  })
            users = users.filter { $0.user.username != username } // remove own account
            let result = Array(users.map { $0.user }.prefix(50)) // first 10 elements
            
            DispatchQueue.main.async {
                 completion(result)
            }
        }
    }
    
    #warning("незначительная проблема")
    // незначительная проблема: проверить являются ли topLikers из терминалогии api инстаграма действительно людьми которые тебя чаще лайкают
    public static func topLikers(_ username: String?, _ posts: [GraphPost]?, completion: @escaping ([GraphUser]) -> Void) {
        DispatchQueue.global().async {
            let usersWithDublicates = posts?.compactMap { $0.likers }.flatMap { $0 } ?? []
            let userIds = Array(Set(usersWithDublicates.compactMap { $0.id }))
            var users: [(user: GraphUser, count: Int)] = []
            userIds.forEach { userId in
                let count = usersWithDublicates.filter { $0.id == userId }.count
                if var uniqueUser = usersWithDublicates.first(where: { $0.id == userId }) {
                    uniqueUser.yourPostsLikes = count
                    users.append((uniqueUser, count))
                }
            }
            users = users.sorted(by: { $0.count > $1.count  })
            users = users.filter { $0.user.username != username } // remove own account
            let result = Array(users.map { $0.user }.prefix(50)) // first 10 elements
            
            DispatchQueue.main.async {
                 completion(result)
            }
        }
    }
    
    public static func youDontFollow(followers: [GraphUser]?, following: [GraphUser]?, completion: @escaping ([GraphUser]) -> Void) {
        DispatchQueue.global().async {
            let result = followers?.filter({ !(following ?? []).contains($0) }) ?? []
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    public static func unfollowers(followers: [GraphUser]?, following: [GraphUser]?, completion: @escaping ([GraphUser]) -> Void) {
        DispatchQueue.global().async {
            let result = following?.filter({ !(followers ?? []).contains($0) }) ?? []
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    // История инстаграма самых прям последних подписчиков не отдаёт.
    // Примерно от недели до 50 последних недель.
    // По этому есть смысл пользоваться моим старым алгоритмом.
    public static func gainedFollowers(_ previousFollowersIds: [String], _ followers: [User]?, _ monthHistoryUsers: [HistoryUser]?, completion: @escaping ([User]) -> Void) {
        DispatchQueue.global().async {
            let list1 = followers?.filter { !previousFollowersIds.contains($0.id ?? "") } ?? []
            
            let monthHistoryUsersIds = monthHistoryUsers?.compactMap { $0.id } ?? []
            let list2 = followers?.filter { user in
                let userId = user.id ?? ""
                return monthHistoryUsersIds.contains(userId)
            } ?? []
            
            var gainedFollowers: [User] = list1
            gainedFollowers.append(contentsOf: list2)
            let result = gainedFollowers.uniqueUsers()
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    public static func lostFollowersIds(_ previousFollowersIds: [String], _ followers: [User]?, _ monthHistoryUsers: [HistoryUser]?, completion: @escaping ([String]) -> Void) {
        guard let followers = followers else {
            completion([])
            return
        }
        
        DispatchQueue.global().async {
            let currentFollowersIds = followers.compactMap { $0.id }
            let list1 = previousFollowersIds.filter { !currentFollowersIds.contains($0) }
            
            let monthHistoryUsersIds = monthHistoryUsers?.compactMap { $0.id } ?? []
            let list2 = monthHistoryUsersIds.filter { !currentFollowersIds.contains($0) }
            
            var lostFollowersIds = list1
            lostFollowersIds.append(contentsOf: list2)
            let result = Array(Set(lostFollowersIds))
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    public static func commentCount(posts: [GraphPost]?, completion: @escaping (Int?) -> Void) {
        DispatchQueue.global().async {
            let commentsCount = posts?.compactMap { $0.comment_count }.reduce(0, +)
            
            DispatchQueue.main.async {
                completion(commentsCount)
            }
        }
    }
    
    public static func likeCount(posts: [GraphPost]?, completion: @escaping (Int?) -> Void) {
        DispatchQueue.global().async {
            let likesCount = posts?.compactMap { $0.like_count }.reduce(0, +)
            
            DispatchQueue.main.async {
                completion(likesCount)
            }
        }
    }
    
}

// MARK: - For Single User
extension UserModel {
    
    public static func addFollowStatus(_ user: User, _ following: [GraphUser]?, _ followRequests: FollowRequests?) -> User {
        if let followStatus = user.followStatus, followStatus == .disabled { // пользователь уже имеет статус подписки
            return user
        }
        
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
    
//    public static func friends(_ following: [GraphUser]?, _ followers: [GraphUser]?) -> [GraphUser] {
//        guard let following = following, let followers = followers else { return [] }
//
//        var friendsWithDublicates: [GraphUser] = []
//        friendsWithDublicates.append(contentsOf: following)
//        friendsWithDublicates.append(contentsOf: followers)
//
//        let userIds = Array(Set(friendsWithDublicates.map { $0.id }))
//        var friends: [GraphUser] = []
//        userIds.forEach { userId in
//            let count = friendsWithDublicates.filter { $0.id == userId }.count
//            if count == 2, let uniqueUser = friendsWithDublicates.first(where: { $0.id == userId }) {
//                friends.append(uniqueUser)
//            }
//        }
//        return friends
//    }
    
}
