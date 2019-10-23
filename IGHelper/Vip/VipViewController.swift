//
//  VipViewController.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/21/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit
import RxSwift
import SwiftyStoreKit
    
class VipViewController: UIViewController {
    
    @IBOutlet var restoreButton: UIButton?
    @IBOutlet var closeButton: UIButton?
    @IBOutlet var subscribeButton: UIButton?
    
    let bag = DisposeBag()
    var onPaymentOrRestoreSuccess: (()->())?
    
    @IBAction func closeAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func restoreAction(_ sender: UIButton) {
        sender.isUserInteractionEnabled = false
        SubscriptionManager.restore()
            .subscribe(onNext: { [weak self] results in
                if let firstResult = results.first {
                    switch firstResult {
                    case .purchased(let expiryDate, _):
                        self?.showAlert(title: "Success", message: "Your purchase has been restored", firstCompletion: {
                            self?.dismiss(animated: true)
                            self?.onPaymentOrRestoreSuccess?()
                        })
                        SubscriptionKeychain.registerSubscription(expirationDate: expiryDate)
                    case .expired(_, _):
                        self?.showAlert(title: "Subscription expired")
                        sender.isUserInteractionEnabled = true
                    case .notPurchased:
                        self?.showAlert(title: "Not Purchased")
                        sender.isUserInteractionEnabled = true
                    }
                } else {
                    self?.showAlert(title: "Failure to connect to iTunes Store")
                    sender.isUserInteractionEnabled = true
                }
                }, onError: { error in
                    // Cancel
                    sender.isUserInteractionEnabled = true
            }).disposed(by: bag)
    }
    
    @IBAction func subscribeAction(_ sender: Any) {
        setupButton(inProgress: true)
        
        let verifyCount = 5
        
        SubscriptionManager.purchase(.month)
            .subscribe(onNext: { [weak self] (results: [VerifySubscriptionResult]) in
                results.forEach {
                    switch $0 {
                    case .purchased(_, let items):
                        items.forEach {
                            print("!!! $0.productId \($0.productId)")
                            if $0.productId == SubscriptionType.month.rawValue {
                                self?.verifyPurchase(levels: verifyCount, onErrorOrNotPurchased: { [weak self] in
                                    self?.showAlert(title: "Failure to connect to iTunes Store")
                                    self?.setupButton(inProgress: false)
                                })
                            }
                        }
                    case .expired(_, _):
                        self?.verifyPurchase(levels: verifyCount, onErrorOrNotPurchased: { [weak self] in
                            self?.showAlert(title: "Subscription expired")
                            self?.setupButton(inProgress: false)
                        })
                    case .notPurchased:
                        self?.verifyPurchase(levels: verifyCount, onErrorOrNotPurchased: { [weak self] in
                            self?.showAlert(title: "Not purchased")
                            self?.setupButton(inProgress: false)
                        })
                    }
                }
                }, onError: { [weak self] error in
                    // Cancel
                    print("!!! ERROR: \(error)")
                    self?.verifyPurchase()
                    self?.setupButton(inProgress: false)
                    self?.showAlert(title: "Failure to connect to iTunes Store")
            }).disposed(by: bag)
    }
    
    func verifyPurchase(levels: Int = 1, onErrorOrNotPurchased: (()->())? = nil) {
        if levels <= 0 {
            onErrorOrNotPurchased?()
            return
        }
        SubscriptionManager.verify(onSuccess: { [weak self] (date, items) in
            if let date = date, let items = items {
                self?.registerPurchase(date, items)
            } else {
                self?.verifyPurchase(levels: levels - 1, onErrorOrNotPurchased: onErrorOrNotPurchased)
            }
            }, onError: { [weak self] _ in
                self?.verifyPurchase(levels: levels - 1, onErrorOrNotPurchased: onErrorOrNotPurchased)
        })
    }
    
    func registerPurchase(_ expiryDate: Date, _ items: [ReceiptItem]) {
        if items.count > 0, let item = items.first, let subscriptionExpirationDate = item.subscriptionExpirationDate {
            SubscriptionKeychain.registerSubscription(expirationDate: subscriptionExpirationDate)
            dismiss(animated: true, completion: nil)
            onPaymentOrRestoreSuccess?()
        } else {
            showAlert(title: "Failure to connect to iTunes Store")
            setupButton(inProgress: false)
        }
    }
    
    func setupButton(inProgress: Bool) {
        subscribeButton?.isEnabled = !inProgress
        
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.subscribeButton?.alpha = inProgress ? 0.5 : 1
        })
        
        if inProgress {
            subscribeButton?.setTitle("PLEASE WAIT...", for: .normal)
        } else {
            subscribeButton?.setTitle("SUBSCRIBE", for: .normal)
        }
    }
    
}
