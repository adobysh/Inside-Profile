//
//  UIImageViewExtension.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/29/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

extension UIImageView {
    
    var imageWithFade: UIImage? {
        get {
            return self.image
        }
        set {
            UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: { [weak self] in
                self?.image = newValue
            }, completion: nil)
        }
    }
    
}
