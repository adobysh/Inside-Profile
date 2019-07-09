//
//  ViewExtension.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 7/8/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

// MARK: IB
extension UIView {
    
    @IBInspectable var borderColor: UIColor? {
        set {
            layer.borderColor = newValue?.cgColor
        }
        get {
            guard let color = layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: color)
        }
    }
    
}

// MARK: Scalable
extension UIView {
    
    func callRecursively(level: Int = 0, _ body: (_ subview: UIView, _ level: Int) -> Void) {
        body(self, level)
        subviews.forEach { $0.callRecursively(level: level + 1, body) }
    }
    
    func scale() {
        callRecursively { (subview, level) in
            if let label = subview as? UILabel {
                label.scaleFont()
            }
            if let button = subview as? UIButton {
                button.scaleFont()
            }
            for constraint in subview.constraints {
                if let constraint = constraint as? ScalableConstraint {
                    constraint.scale()
                }
            }
        }
    }
    
}
