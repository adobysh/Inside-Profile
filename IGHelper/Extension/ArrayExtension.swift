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
}
