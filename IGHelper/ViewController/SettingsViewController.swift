//
//  SettingsViewController.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/14/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    public var onLogOut: (()->())?
    
    @IBAction func logOutButtonAction(_ sender: Any) {
        AuthorizationManager.shared.logOut()
        onLogOut?()
        dismiss(animated: true, completion: nil)
    }
    
}
