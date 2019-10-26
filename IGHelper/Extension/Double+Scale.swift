//
//  Double+Scale.swift
//  Scanner
//
//  Created by Артем Дудинский on 5/2/19.
//  Copyright © 2019 Nesus. All rights reserved.
//

import UIKit

extension Double {
    
    var scalable: CGFloat {
        let scaleFactor = min(UIScreen.main.bounds.width / 375, 1)
        return CGFloat(self) * scaleFactor
    }
    
}
