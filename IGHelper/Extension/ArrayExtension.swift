//
//  ArrayExtension.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/15/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

extension Array {
    
    subscript(safe index: Int) -> Element? {
        get {
            return indices.contains(index) ? self[index] : nil
        }
        set {
            if let newValue = newValue, indices.contains(index) {
                self[index] = newValue
            }
        }
    }
    
    func shuffle(seed: Int) -> [Element] {
        srand48(seed)
        var shuffled: [(element: Element, index: Double)] = []
        self.forEach { shuffled.append(($0, Double(drand48()))) }
        shuffled.sort { $0.index > $1.index }
        let shuffledElements = shuffled.map { $0.element }
        return shuffledElements
    }
    
    func split() -> [[Element]] {
        let half = count / 2
        let leftSplit = self[0 ..< half]
        let rightSplit = self[half ..< count]
        return [Array(leftSplit), Array(rightSplit)]
    }
    
    // Метод работает дерьмово зато надёжно.
    // Иногда когда делишь на 4 может выдать 5 массивов.
    // Первые массивы вообще могут быть пустыми.
    func split(parts: Int) -> [[Element]] {
        let partCount = count / parts
        var newArray: [[Element]] = []
        for i in 0..<parts {
            newArray.append(Array(self[(i * partCount) ..< (i * partCount + partCount)]))
        }
        newArray.append(Array(self[(partCount * parts) ..< count]))
        return newArray
    }
    
}

extension Array where Element == User {

    func uniqueUsers() -> [User] {
        var usersWithoutDublicates: [User] = []
        self.forEach { user in
            let addedUser = usersWithoutDublicates.first(where: { $0.id == user.id })
            if let _ = addedUser {
                // пользователь уже добавлен - игнорим
            } else {
                usersWithoutDublicates.append(user)
            }
        }
        return usersWithoutDublicates
    }
    
    func uniqueUsersWithCounts() -> [(element: User, count: Int)] {
        var usersWithoutDublicates: [(element: User, count: Int)] = []
        self.forEach { user in
            let addedUser = usersWithoutDublicates.first(where: { $0.element.id == user.id })
            if let _ = addedUser {
                // пользователь уже добавлен - игнорим
            } else {
                let count = self.filter { $0.id == user.id }.count
                usersWithoutDublicates.append((user, count))
            }
        }
        return usersWithoutDublicates
    }
    
}
