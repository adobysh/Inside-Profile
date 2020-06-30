//
//  UIStackView+Scalable.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 6/25/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import UIKit

extension UIStackView {
    
    func scaleSpacing() {
        spacing = Double(spacing).scalable
    }
    
}
