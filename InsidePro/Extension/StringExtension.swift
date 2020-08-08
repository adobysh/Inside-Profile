//
//  StringExtension.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/14/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation

extension String {
    
    var asDictionary: [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func lowercaseFirstLetter() -> String {
        return prefix(1).lowercased() + self.dropFirst()
    }

    mutating func lowercaseFirstLetter() {
        self = self.lowercaseFirstLetter()
    }
    
    func encodeUrl() -> String? {
        return self.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
    }
    
    func decodeUrl() -> String? {
        return self.removingPercentEncoding
    }
    
}
