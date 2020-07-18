//
//  UIViewControllerExtension.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 7/23/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showErrorAlert(_ error: Error? = nil, _ action: (()->())? = nil) {
        #if DEBUG
        let message = error?.localizedDescription
        #else
        let message = "Check your Internet connection and try again"
        #endif
        
//        let message = error != nil ? "\(error)" : "Check your Internet connection and try again"
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            action?()
        }))
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
    
    func showAlert(title: String? = nil, message: String? = nil, actions: [UIAlertAction]? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions?.forEach { alertController.addAction($0) }
        present(alertController, animated: true)
    }
    
    func showSimpleAlert(_ title: String, _ message: String? = nil, _ firstActionTitle: String = "OK", _ firstCompletion: (() -> ())? = nil) {
        showAlert(title: title, message: message, firstActionTitle: firstActionTitle, secondActionTitle: nil, firstCompletion: firstCompletion, secondCompletion: nil)
    }
    
}

// MARK: - Storyboarded
extension UIViewController {
    static func instantiate() -> Self {
        let bundle = Bundle(for: Self.self)
        let storyboard = UIStoryboard(name: String(describing: Self.self), bundle: bundle)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: Self.self)) as! Self
        (vc as? UIViewController)?.modalPresentationStyle = .fullScreen
        return vc
    }
}
