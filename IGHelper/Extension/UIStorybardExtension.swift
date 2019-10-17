//
//  UIStorybard+AppStoryboards.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 7/24/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

extension UIStoryboard {
    
    class var main: UIStoryboard {
        return UIStoryboard(name: "Main", bundle: nil)
    }
    
}

extension UIStoryboard {
    
    func instantiateViewControllerCustom(withIdentifier identifier: String) -> UIViewController {
        let vc = self.instantiateViewController(withIdentifier: identifier)
        vc.modalPresentationStyle = .fullScreen
        if #available(iOS 13.0, *) {
            vc.overrideUserInterfaceStyle = .light
        }
        return vc
    }
    
}
