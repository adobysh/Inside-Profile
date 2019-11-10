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
    
    public var onLogOut: (()->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.scale()
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        if SubscriptionKeychain.isSubscribed() {
            getPremiumButton?.removeFromSuperview()
            restoreButton?.removeFromSuperview()
        }
    }
    
    @IBAction func getPremiumButtonAction(_ sender: Any) {
        let vc = UIViewController.vip
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
        }) { error in
            // do nothing
            print("!!! ERROR: restore error \(error)")
            sender.isEnabled = true
        }
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
        present(svc, animated: true)
    }
    
}

extension SettingsViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
