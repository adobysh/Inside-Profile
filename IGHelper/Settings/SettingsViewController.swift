//
//  SettingsViewController.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/14/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit
import SafariServices

class SettingsViewController: UIViewController {
    
    public var onLogOut: (()->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    @IBAction func getPremiumButtonAction(_ sender: Any) {
        let vc = UIViewController.vip
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func restoreButtonAction(_ sender: Any) {
    }
    
    @IBAction func privatyButtonAction(_ sender: Any) {
        openUrl(url: "https://google.com/")
    }
    
    @IBAction func termsButtonAction(_ sender: Any) {
        openUrl(url: "https://google.com/")
    }
    
    @IBAction func logOutButtonAction(_ sender: Any) {
        AuthorizationManager.shared.logOut()
        onLogOut?()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func openUrl(url: String) {
        guard let newUrl = URL(string: url) else { return }
        let svc = SFSafariViewController(url: newUrl)
        present(svc, animated: true, completion: nil)
    }
    
}

extension SettingsViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
