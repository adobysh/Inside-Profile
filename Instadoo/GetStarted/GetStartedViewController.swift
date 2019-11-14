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
    
    public var onAuthorizationSuccess: (()->())?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.scale()
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        let vc = UIViewController.authorization
        vc.onSuccess = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
            self?.onAuthorizationSuccess?()
        }
        present(vc, animated: true, completion: nil)
    }
    
}
