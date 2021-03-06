//
//  VipViewController.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/21/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit
import StoreKit
import SwiftyStoreKit
import Lottie
    
class VipViewController: UIViewController {
    
    @IBOutlet var restoreButton: UIButton?
    @IBOutlet var closeButton: UIButton?
    @IBOutlet var subscribeButton: UIButton?
    @IBOutlet var textView: UITextView?
    @IBOutlet var scrollView: UIScrollView?
    @IBOutlet var onButtonLabel: UILabel?
    @IBOutlet var lottieCrownView: AnimationView?
    @IBOutlet var lottieButton: AnimationView?
    private var blurEffectView: UIVisualEffectView?
    private var spinner: UIActivityIndicatorView?
    
    @IBOutlet var closeButtonTopConstraint: NSLayoutConstraint?
    
    private let currentSubscription: SubscriptionType = .week
    private var product: SKProduct?
    
    public var source: EventSource = .unknown
    
    public var onPaymentSuccess: (()->())?
    public var onRestoreSuccess: (()->())?
    public var onClose: (()->())?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.scale()
        
        AppAnalytics.logOpen(screen: .vip, source: source)
        setupLoadingBlur()
        if #available(iOS 13.0, *) {
            let constantForIOS13 = (closeButtonTopConstraint?.constant ?? 0) / 2.0
            closeButtonTopConstraint?.constant = constantForIOS13
        }
        
        subscribeButton?.setTitle("PLEASE WAIT...", for: .disabled)
        
        SubscriptionManager.product(onComplete: { [weak self] product in
            self?.product = product
            guard let price = product.localizedPrice else { return }

            self?.onButtonLabel?.text = "Start your 3-days trial, then \(price)/week"

            self?.setupDescriptionTextView(price: price)
            self?.dismissLoadingBlur()
            self?.lottieCrownView?.play()
        }) { [weak self] error in
            self?.showErrorAlert {
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    private func setupLoadingBlur() {
        let blurEffect = UIBlurEffect(style: .extraLight)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        spinner = UIActivityIndicatorView(style: .gray)
        
        guard let blurEffectView = blurEffectView, let spinner = spinner else { return }
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        
        view.addSubview(spinner)
        spinner.center = view.center
        spinner.startAnimating()
    }
    
    private func dismissLoadingBlur() {
        blurEffectView?.removeFromSuperview()
        spinner?.stopAnimating()
        spinner?.removeFromSuperview()
    }
    
    @IBAction func closeAction(_ sender: Any) {
        onClose?()
    }
    
    @IBAction func restoreAction(_ sender: UIButton) {
        sender.isEnabled = false
        AppAnalytics.logClick(button: .restore, source: source)
        SubscriptionManager.restore(onSuccess: { [weak self] verifySubscriptionResultArray in
            verifySubscriptionResultArray.forEach { verifySubscriptionResult in
                switch verifySubscriptionResult {
                case .purchased(_, let receiptItemArray):
                    receiptItemArray.forEach {
                        let haveThisSubscription: Bool = SubscriptionType.allCases.map { $0.rawValue }.contains($0.productId)
                        if haveThisSubscription {
                            if let subscriptionExpirationDate = $0.subscriptionExpirationDate, !$0.isExpired {
                                SubscriptionKeychain.registerSubscription(expirationDate: subscriptionExpirationDate)
                                if SubscriptionKeychain.isSubscribed() {
                                    self?.onRestoreSuccess?()
                                }
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
        }, onError: { [weak self] error in
            print("!!! ERROR: restore error \(error)")
            self?.showErrorAlert()
            sender.isEnabled = true
        }, onNothing: { [weak self] in
            self?.showAlert(title: "Nothing to restore")
            sender.isEnabled = true
        })
    }
    
    @IBAction func subscribeAction(_ sender: UIButton) {
        sender.isEnabled = false
        AppAnalytics.logClick(button: .vip)
        SubscriptionManager.purchase(currentSubscription, onSuccess: { [weak self] verifySubscriptionResult in
            switch verifySubscriptionResult {
            case .purchased(_, let receiptItemArray):
                receiptItemArray.forEach {
                    if $0.productId == self?.currentSubscription.rawValue && !$0.isExpired {
                        if let subscriptionExpirationDate = $0.subscriptionExpirationDate {
                            SubscriptionKeychain.registerSubscription(expirationDate: subscriptionExpirationDate)
                            self?.onPaymentSuccess?()
                            guard let product = self?.product, let source = self?.source else { return }
                            AppAnalytics.logPurchase(price: product.price,
                                                     currency: product.priceLocale.currencyCode,
                                                     identifier: product.productIdentifier,
                                                     place: source.rawValue)
                            let properties: [String: String] = [
                                "source": source.rawValue,
//                                "type": self?.isOffer == true ? "offer" : "vip",
                                "identifier": product.productIdentifier
                            ]
//                            if let pushId = self?.pushId {
//                                properties["push_id"] = pushId
//                            }
                            AppAnalytics.log(.purchase_analytics, properties: properties)
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
    
    private func setupDescriptionTextView(price: String) {
        
        let font = UIFont.systemFont(ofSize: 11.0.scalable, weight: .semibold)
        let linkFont = UIFont.systemFont(ofSize: 11.0.scalable, weight: .bold)
        let linkColor = UIColor(hex: "#8244E2FF") ?? .black
        let color = linkColor.withAlphaComponent(0.7)
        
        let template = "Information about the auto-renewable nature of the subscription: Subscription periods are 1 week, price - <price>. Every week your subscription renews. Payment will be charged to iTunes Account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period. Account will be charged for renewal within 24-hours prior to the end of the current period. After the trial period, weekly subscription will start for <price>. Trials will be 3 days, after which the subscription will auto-renew. Any unused portion of a free trial period, if offered, will be forfeited when the user purchases a subscription to that publication, where applicable. You can cancel your subscription via this url: https://support.apple.com/en-us/HT202039. \nPrivacy Policy: https://andromeda-group.jimdosite.com/privacy-policy/. \nTerms of Use: https://andromeda-group.jimdosite.com/terms-of-use/."
        
        let text = template.replacingOccurrences(of: "<price>", with: price)
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return }
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        let attributedString = NSMutableAttributedString()
        attributedString.append(NSAttributedString(string: text,
                                                   attributes: [.font: font, NSAttributedString.Key.foregroundColor: color]))
        
        let content = attributedString
        for match in matches {
            guard let range = Range(match.range, in: text) else { continue }
            let url = String(text[range])
            content.setAsLink(textToFind: url, linkURL: url, font: font)
        }
//        content.setAsLink(textToFind: "Privacy Policy", linkURL: "https://andromeda-group.jimdosite.com/privacy-policy/", font: font)
//        content.setAsLink(textToFind: "Terms of Use", linkURL: "https://andromeda-group.jimdosite.com/terms-of-use/", font: font)
        textView?.attributedText = content
        textView?.linkTextAttributes = [.font: linkFont, .foregroundColor: linkColor]
        textView?.textAlignment = .justified
    }
    
}

extension NSMutableAttributedString {

    public func setAsLink(textToFind: String, linkURL: String, font: UIFont) {
        let foundRange = self.mutableString.range(of: textToFind)
        if foundRange.location != NSNotFound {
            self.addAttribute(.link, value: linkURL, range: foundRange)
            self.addAttribute(.font, value: font, range: foundRange)
        }
    }

}
