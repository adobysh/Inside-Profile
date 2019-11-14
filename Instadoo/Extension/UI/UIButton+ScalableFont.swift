//
//  UIButton+ScalableFont.swift
//  Horoscope
//
//  Created by Andrei Dobysh on 5/9/19.
//  Copyright © 2019 Nesus UAB. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    
    func scaleFont() {
        let fontSize: Double = Double(titleLabel?.font.pointSize ?? 0.0)
        titleLabel?.font = titleLabel?.font.withSize(fontSize.scalable)
    }
    
}
