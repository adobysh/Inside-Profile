//
//  GetStartedViewController.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 7/24/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

class GetStartedViewController: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        AuthorizationManager.shared.login(loginOrEmail: "andrey_dobysh", password: "Testpass1", onSuccess: { [weak self] (authorizationData) in
            print("!!! autorization success \(authorizationData)")
            self?.dismiss(animated: true, completion: nil)
        }) { [weak self] (error) in
            print("!!! error \(error)")
            self?.showErrorAlert(error)
        }
        
//        AuthorizationManager.shared.login(self, onSuccess: {
//            ApiManager.shared.getUserInfo(onComplete: { [weak self] (userMainInfo) in
//                print("!!! userMainInfo \(userMainInfo)")
//                self?.dismiss(animated: true, completion: nil)
//            }) { [weak self] (error) in
//                self?.showErrorAlert(error)
//            }
//        })
    }
    
}
