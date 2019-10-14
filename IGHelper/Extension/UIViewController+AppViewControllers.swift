//
//  UIViewControllers.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 7/24/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

extension UIViewController {
    
    // MARK: - Main
    
    class var main: MainViewController {
        return UIStoryboard.main.instantiateViewController(withIdentifier: MainViewController.identifier) as! MainViewController
    }
    
    class var getStarted: GetStartedViewController {
        return UIStoryboard.main.instantiateViewController(withIdentifier: GetStartedViewController.identifier) as! GetStartedViewController
    }
    
    class var recomendation: RecomendationViewController {
        return UIStoryboard.main.instantiateViewController(withIdentifier: RecomendationViewController.identifier) as! RecomendationViewController
    }
    
    class var authorization: AuthorizationViewController {
        return UIStoryboard.main.instantiateViewController(withIdentifier: AuthorizationViewController.identifier) as! AuthorizationViewController
    }
    
}

extension UIViewController {
    
    class var identifier: String {
        return String(describing: self)
    }
    
}
