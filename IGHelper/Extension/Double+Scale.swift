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
        let scaleFactor = UIScreen.main.bounds.width / 375
        return CGFloat(self) * scaleFactor
    }
    
}
