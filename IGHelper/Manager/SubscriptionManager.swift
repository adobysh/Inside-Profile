//
//  SubscriptionsManager.swift
//  ReadOrDie
//
//  Created by Andrei Dobysh on 6/4/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation
import SwiftyStoreKit
import RxSwift
import StoreKit
import SwiftyStoreKit

enum SubscriptionType: String {
    case month = "com.andreidobysh.nativereader.month"
    case empty = ""
}

struct SubscriptionError: Error {
    var message: String
}

class SubscriptionManager {
    
    static var verifyReceiptURLType: AppleReceiptValidator.VerifyReceiptURLType {
        #if DEBUG
            return .sandbox
        #else
            return .production
        #endif
    }
    
    static let sharedSecret = "2eab742f8fba4ffca9bb0649e86ffe83"
    static let storeKitTimeout = 6000
    
    static func purchase(_ type: SubscriptionType) -> Observable<[VerifySubscriptionResult]> {
        return Observable.create { observer in
            guard SwiftyStoreKit.canMakePayments else { return Disposables.create() }
            SwiftyStoreKit.purchaseProduct(type.rawValue, quantity: 1, atomically: true) { result in
                switch result {
                case .success:
                    observer.onNext([type])
                case .error(let error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            return Disposables.create()
            }.timeout(RxTimeInterval(storeKitTimeout), scheduler: MainScheduler.instance)
            .flatMapLatest(verify)
    }
    
    static func restore() -> Observable<[VerifySubscriptionResult]> {
        return Observable.create { observer in
            SwiftyStoreKit.restorePurchases(atomically: true, completion: { results in
                if results.restoredPurchases.count > 0 {
                    observer.onNext([.month])
                } else if results.restoreFailedPurchases.count > 0 {
                    observer.onError(SubscriptionError(message: "Restore Failed"))
                } else {
                    observer.onError(SubscriptionError(message: "Nothing to restore"))
                }
                observer.onCompleted()
            })
            return Disposables.create()
            }.timeout(RxTimeInterval(storeKitTimeout), scheduler: MainScheduler.instance)
            .flatMapLatest(verify)
    }
    
    static func isProductionVersion() -> Bool {
        return verifyReceiptURLType == .production
    }
    
    static func verify(_ types: [SubscriptionType]) -> Observable<[VerifySubscriptionResult]> {
        return Observable.create { observer in
            let appleValidator = AppleReceiptValidator(service: verifyReceiptURLType, sharedSecret: sharedSecret)
            SwiftyStoreKit.verifyReceipt(using: appleValidator, completion: { result in
                switch result {
                case .success(let receipt):
                    observer.onNext(types.map {
                        let verifySubscriptionResult = SwiftyStoreKit.verifySubscription(ofType: .autoRenewable, productId: $0.rawValue, inReceipt: receipt)
                        return verifySubscriptionResult
                    })
                case .error(let error):
                    observer.onError(error)
                }
            })
            return Disposables.create()
        }
    }
    
    static func product() -> Single<SKProduct> {
        return Single.create { observer in
            SwiftyStoreKit.retrieveProductsInfo([SubscriptionType.month.rawValue]) { result in
                if let product = result.retrievedProducts.first {
                    observer(.success(product))
                } else if result.invalidProductIDs.first != nil {
                    assertionFailure("invalid product name")
                } else if let error = result.error {
                    observer(.error(error))
                }
            }
            return Disposables.create()
        }
    }
    
    static func verify(onSuccess: @escaping (Date?, [ReceiptItem]?)->(), onError: @escaping (Error)->()) {
        let appleValidator = AppleReceiptValidator(service: verifyReceiptURLType, sharedSecret: sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            switch result {
            case .success(let receipt):
                let productId = SubscriptionType.month.rawValue
                let purchaseResult = SwiftyStoreKit.verifySubscription(
                    ofType: .autoRenewable,
                    productId: productId,
                    inReceipt: receipt)
                
                switch purchaseResult {
                case .purchased(let expiryDate, let items):
                    SubscriptionKeychain.registerSubscription(expirationDate: expiryDate)
                    onSuccess(expiryDate, items)
                case .expired(_, _), .notPurchased:
                    SubscriptionKeychain.unsubscribe()
                    onSuccess(nil, nil)
                }
            case .error(let error):
                onError(error)
            }
        }
    }
    
    static func verify(onSuccess: ((Bool) -> Void)? = nil) {
        let appleValidator = AppleReceiptValidator(service: verifyReceiptURLType, sharedSecret: sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            switch result {
            case .success(let receipt):
                let productId = SubscriptionType.month.rawValue
                let purchaseResult = SwiftyStoreKit.verifySubscription(
                    ofType: .autoRenewable,
                    productId: productId,
                    inReceipt: receipt)
                
                switch purchaseResult {
                case .purchased(let expiryDate, _):
                    SubscriptionKeychain.registerSubscription(expirationDate: expiryDate)
                    onSuccess?(true)
                case .expired(_, _), .notPurchased:
                    SubscriptionKeychain.unsubscribe()
                    onSuccess?(false)
                }
            case .error(_):
                // TODO
                break
            }
        }
    }
    
}
