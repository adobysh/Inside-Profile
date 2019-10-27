//
//  VipViewController.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/21/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit
import SwiftyStoreKit
    
class VipViewController: UIViewController {
    
    @IBOutlet var restoreButton: UIButton?
    @IBOutlet var closeButton: UIButton?
    @IBOutlet var subscribeButton: UIButton?
    @IBOutlet var closeButtonTopConstraint: NSLayoutConstraint?
    
    private let currentSubscription: SubscriptionType = .month
    
    public var onPaymentSuccess: (()->())?
    public var onClose: (()->())?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.scale()
        if #available(iOS 13.0, *) {
            let constantForIOS13 = (closeButtonTopConstraint?.constant ?? 0) / 2.0
            closeButtonTopConstraint?.constant = constantForIOS13
        }
        
        subscribeButton?.setTitle("PLEASE WAIT...", for: .disabled)
    }
    
    @IBAction func closeAction(_ sender: Any) {
        onClose?()
    }
    
    @IBAction func restoreAction(_ sender: UIButton) {
        sender.isEnabled = false
        SubscriptionManager.restore(onSuccess: { [weak self] verifySubscriptionResultArray in
            verifySubscriptionResultArray.forEach { verifySubscriptionResult in
                switch verifySubscriptionResult {
                case .purchased(_, let receiptItemArray):
                    receiptItemArray.forEach {
                        let haveThisSubscription: Bool = SubscriptionType.allCases.map { $0.rawValue }.contains($0.productId)
                        if haveThisSubscription {
                            if let subscriptionExpirationDate = $0.subscriptionExpirationDate, !$0.isExpired {
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
            sender.isEnabled = true
            self?.showAlert(title: "Success", message: "All your purchases have been restored")
        }) { error in
            // do nothing
            print("!!! ERROR: restore error \(error)")
            sender.isEnabled = true
        }
    }
    
    @IBAction func subscribeAction(_ sender: UIButton) {
        sender.isEnabled = false
        SubscriptionManager.purchase(currentSubscription, onSuccess: { [weak self] verifySubscriptionResult in
            switch verifySubscriptionResult {
            case .purchased(_, let receiptItemArray):
                receiptItemArray.forEach {
                    if $0.productId == self?.currentSubscription.rawValue && !$0.isExpired {
                        if let subscriptionExpirationDate = $0.subscriptionExpirationDate {
                            SubscriptionKeychain.registerSubscription(expirationDate: subscriptionExpirationDate)
                            self?.onPaymentSuccess?()
                        }
                    }
                }
            case .expired(_, let receiptItemArray):
                receiptItemArray.forEach {
                    if $0.productId == self?.currentSubscription.rawValue {
                        self?.showAlert(title: "Expired")
                    }
                }
            case .notPurchased:
                self?.showAlert(title: "Not purchased")
            }
            sender.isEnabled = true
        }) { error in
            // just cancel. do nothing
            print("!!! ERROR: subscribe error \(error)")
            sender.isEnabled = true
        }
    }
    
}

// MARK: - Old Shit
extension VipViewController {
    
//    func verifyPurchase(levels: Int = 5, onErrorOrNotPurchased: (()->())? = nil) {
//        if levels <= 0 {
//            onErrorOrNotPurchased?()
//            return
//        }
//        SubscriptionManager.verify(onSuccess: { [weak self] (date, items) in
//            if let date = date, let items = items {
//                self?.registerPurchase(date, items)
//            } else {
//                self?.verifyPurchase(levels: levels - 1, onErrorOrNotPurchased: onErrorOrNotPurchased)
//            }
//        }, onError: { [weak self] _ in
//            self?.verifyPurchase(levels: levels - 1, onErrorOrNotPurchased: onErrorOrNotPurchased)
//        })
//    }
    
//    func registerPurchase(_ expiryDate: Date, _ items: [ReceiptItem]) {
//        if items.count > 0, let item = items.first, let subscriptionExpirationDate = item.subscriptionExpirationDate {
//            SubscriptionKeychain.registerSubscription(expirationDate: subscriptionExpirationDate)
//            dismiss(animated: true, completion: nil)
//            onPaymentOrRestoreSuccess?()
//        } else {
//            showAlert(title: "Failure to connect to iTunes Store")
//            setupButton(inProgress: false)
//        }
//    }
    
}
