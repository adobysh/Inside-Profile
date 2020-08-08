//
//  UINavigationControllerExtension.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 12/5/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

extension UINavigationController {

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .default
    }
    
}
