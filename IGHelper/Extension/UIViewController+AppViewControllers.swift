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
        return UIStoryboard.main.instantiateViewControllerCustom(withIdentifier: MainViewController.identifier) as! MainViewController
    }
    
    class var getStarted: GetStartedViewController {
        return UIStoryboard.main.instantiateViewControllerCustom(withIdentifier: GetStartedViewController.identifier) as! GetStartedViewController
    }
    
    class var detail: DetailViewController {
        return UIStoryboard.main.instantiateViewControllerCustom(withIdentifier: DetailViewController.identifier) as! DetailViewController
    }
    
    class var authorization: AuthorizationViewController {
        return UIStoryboard.main.instantiateViewControllerCustom(withIdentifier: AuthorizationViewController.identifier) as! AuthorizationViewController
    }
    
    class var settings: SettingsViewController {
        return UIStoryboard.main.instantiateViewControllerCustom(withIdentifier: SettingsViewController.identifier) as! SettingsViewController
    }
    
}

extension UIViewController {
    
    class var identifier: String {
        return String(describing: self)
    }
    
}
