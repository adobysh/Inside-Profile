//
//  UIViewControllerExtension.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 7/23/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

// Error handing
extension UIViewController {
    
    func showErrorAlert() {
        let alert = UIAlertController(title: "Error", message: "Check your Internet connection and try again", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: "\(error)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showAlert(title: String, message: String? = nil, firstActionTitle: String = "OK", secondActionTitle: String? = nil, firstCompletion: (() -> ())? = nil, secondCompletion: (() -> ())? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let firstAction = UIAlertAction(title: firstActionTitle, style: .default) { (action) in
            firstCompletion?()
        }
        alertController.addAction(firstAction)
        if let secondActionTitle = secondActionTitle {
            let secondAction = UIAlertAction(title: secondActionTitle, style: .cancel) { (action) in
                secondCompletion?()
            }
            alertController.addAction(secondAction)
        }
        present(alertController, animated: true)
    }
    
    func showSimpleAlert(_ title: String, _ message: String? = nil, _ firstActionTitle: String = "OK", _ firstCompletion: (() -> ())? = nil) {
        showAlert(title: title, message: message, firstActionTitle: firstActionTitle, secondActionTitle: nil, firstCompletion: firstCompletion, secondCompletion: nil)
    }
    
}
