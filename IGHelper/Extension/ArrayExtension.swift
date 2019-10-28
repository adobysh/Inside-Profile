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
    
}
