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
    
    @IBOutlet var getPremiumButton: UIButton?
    @IBOutlet var restoreButton: UIButton?
    @IBOutlet var logoutButton: UIButton?
    
    public var onLogOut: (()->())?
    public var isHiddenPremium: Bool?
    public var isHiddenLogin: Bool?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.scale()
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        if SubscriptionKeychain.isSubscribed() {
            getPremiumButton?.removeFromSuperview()
            restoreButton?.removeFromSuperview()
        }
        
        if isHiddenPremium == true {
            getPremiumButton?.removeFromSuperview()
            restoreButton?.removeFromSuperview()
        }
        
        if isHiddenLogin == true {
            logoutButton?.removeFromSuperview()
        }
    }
    
    @IBAction func getPremiumButtonAction(_ sender: Any) {
        let vc = VipViewController.instantiate()
        vc.source = .settings
        vc.onClose = {
            vc.dismiss(animated: true)
        }
        vc.onPaymentSuccess = { [weak self] in
            if SubscriptionKeychain.isSubscribed() {
                self?.getPremiumButton?.removeFromSuperview()
                self?.restoreButton?.removeFromSuperview()
            }
            vc.dismiss(animated: true)
        }
        vc.onRestoreSuccess = { [weak self] in
           if SubscriptionKeychain.isSubscribed() {
               self?.getPremiumButton?.removeFromSuperview()
               self?.restoreButton?.removeFromSuperview()
           }
        }
        present(vc, animated: true)
    }
    
    @IBAction func restoreButtonAction(_ sender: UIButton) {
        sender.isEnabled = false
        AppAnalytics.logClick(button: .restore, source: .settings)
        SubscriptionManager.restore(onSuccess: { [weak self] verifySubscriptionResultArray in
            verifySubscriptionResultArray.forEach { verifySubscriptionResult in
                switch verifySubscriptionResult {
                case .purchased(_, let receiptItemArray):
                    receiptItemArray.forEach {
                        let haveThisSybscription: Bool = SubscriptionType.allCases.map { $0.rawValue }.contains($0.productId)
                        if haveThisSybscription {
                            if let subscriptionExpirationDate = $0.subscriptionExpirationDate {
                                SubscriptionKeychain.registerSubscription(expirationDate: subscriptionExpirationDate)
                            }
                        }
                    }
                case .expired(_, _):
                    // do nothing
                    break
                case .notPurchased:
                    // do nothing
                    break
                }
            }
            self?.showAlert(title: "Success", message: "All your purchases have been restored")
            sender.isEnabled = true
        }, onError: { [weak self] error in
            print("!!! ERROR: restore error \(error)")
            self?.showErrorAlert()
            sender.isEnabled = true
        }, onNothing: { [weak self] in
            self?.showAlert(title: "Nothing to restore")
            sender.isEnabled = true
        })
    }
    
    @IBAction func privatyButtonAction(_ sender: Any) {
        openUrl(url: "https://andromeda-group.jimdosite.com/privacy-policy/")
    }
    
    @IBAction func termsButtonAction(_ sender: Any) {
        openUrl(url: "https://andromeda-group.jimdosite.com/terms-of-use/")
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
        present(svc, animated: true)
    }
    
}

extension SettingsViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
