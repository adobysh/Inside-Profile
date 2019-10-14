//
//  StringExtension.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/14/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

extension String {
    
    func lowercaseFirstLetter() -> String {
        return prefix(1).lowercased() + self.dropFirst()
    }

    mutating func lowercaseFirstLetter() {
        self = self.lowercaseFirstLetter()
    }
    
}
