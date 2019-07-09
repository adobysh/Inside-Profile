//
//  UILabel+ScalableFont.swift
//  Horoscope
//
//  Created by Andrei Dobysh on 5/13/19.
//  Copyright © 2019 Nesus UAB. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    
    func scaleFont() {
        let fontSize: Double = Double(font.pointSize)
        font = font.withSize(fontSize.scalable)
    }
    
}
