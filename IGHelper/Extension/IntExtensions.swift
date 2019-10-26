//
//  IntExtensions.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/26/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

extension Int {
    
    // Int32.max == 2147483647
    // Int.max == 9,223,372,036,854,775,807 начиная с 5s все процы 64 битные
    var bigBeauty: String {
        if self >= 1_000_000_000_000_000 {
            let newNumber = Double(self) / 1_000_000_000_000_000.0
            return "\(String(format: "%.1f", newNumber))P"
        } else if self >= 1_000_000_000_000 {
            let newNumber = Double(self) / 1_000_000_000_000.0
            return "\(String(format: "%.1f", newNumber))T"
        } else if self >= 1_000_000_000 {
            let newNumber = Double(self) / 1_000_000_000.0
            return "\(String(format: "%.1f", newNumber))G"
        } else if self >= 1_000_000 {
            let newNumber = Double(self) / 1_000_000.0
            return "\(String(format: "%.1f", newNumber))M"
        } else if self >= 10_000 {
            let newNumber = Double(self) / 1_000.0
            return "\(String(format: "%.1f", newNumber))K"
        } else {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedNumber = numberFormatter.string(from: NSNumber(value:self))
            return formattedNumber ?? ""
        }
    }
    
}
