//
//  GetStartedViewController.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 7/24/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

class GetStartedViewController: UIViewController {
    
    @IBOutlet var loginTextField: UITextField?
    @IBOutlet var passwordTextField: UITextField?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        let vc = UIViewController.authorization
        vc.onSuccess = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
        present(vc, animated: true, completion: nil)
    }
    
}
