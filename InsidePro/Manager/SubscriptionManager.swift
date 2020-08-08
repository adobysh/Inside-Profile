//
//  SubscriptionsManager.swift
//  ReadOrDie
//
//  Created by Andrei Dobysh on 6/4/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation
import StoreKit
import SwiftyStoreKit

enum SubscriptionType: String, CaseIterable {
    case week = "com.andreidobysh.instadoo.1week"
}

struct SubscriptionError: Error {
    var message: String
    static let unknown = SubscriptionError(message: "unknown error")
}

class SubscriptionManager {
    
    static var verifyReceiptURLType: AppleReceiptValidator.VerifyReceiptURLType {
        #if DEBUG
            return .sandbox
        #else
            return .production
        #endif
    }
    
    static let sharedSecret = "cbb2dc7876a54fc9ae42656544a1bf8f"
//    static let storeKitTimeout = 6000
    
    static func isProductionVersion() -> Bool {
        return verifyReceiptURLType == .production
    }
    
    static func verify(onSuccess: ((Bool) -> Void)? = nil) {
        let appleValidator = AppleReceiptValidator(service: verifyReceiptURLType, sharedSecret: sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            switch result {
            case .success(let receipt):
                let productId = SubscriptionType.week.rawValue
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
    
    static func product(onComplete: @escaping (SKProduct)->(), onError: @escaping (Error)->()) {
        SwiftyStoreKit.retrieveProductsInfo([SubscriptionType.week.rawValue]) { result in
            if let product = result.retrievedProducts.first {
                onComplete(product)
            } else if result.invalidProductIDs.first != nil {
                onError(SubscriptionError(message: "invalid product name"))
            } else if let error = result.error {
                onError(error)
            } else {
                onError(SubscriptionError.unknown)
            }
        }
    }
    
    static func verify(_ types: [SubscriptionType], onSuccess: @escaping ([VerifySubscriptionResult])->(), onError: @escaping (Error)->()) {
        let appleValidator = AppleReceiptValidator(service: verifyReceiptURLType, sharedSecret: sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator, completion: { result in
            switch result {
            case .success(let receipt):
                var results: [VerifySubscriptionResult] = []
                types.forEach {
                    let verifySubscriptionResult = SwiftyStoreKit.verifySubscription(ofType: .autoRenewable, productId: $0.rawValue, inReceipt: receipt)
                    results.append(verifySubscriptionResult)
                }
                onSuccess(results)
            case .error(let error):
                onError(error)
            }
        })
    }
    
    static func restore(onSuccess: @escaping ([VerifySubscriptionResult])->(), onError: @escaping (Error)->(), onNothing: @escaping ()->()) {
        SwiftyStoreKit.restorePurchases(atomically: true, completion: { results in
            if results.restoredPurchases.count > 0 {
                SubscriptionManager.verify(SubscriptionType.allCases, onSuccess: onSuccess, onError: onError)
            } else if results.restoreFailedPurchases.count > 0 {
                onError(SubscriptionError(message: "Restore Failed"))
            } else {
                onNothing()
            }
        })
    }
    
    static func purchase(_ type: SubscriptionType, onSuccess: @escaping (VerifySubscriptionResult)->(), onError: @escaping (Error)->()) {
        guard SwiftyStoreKit.canMakePayments else { onError(SubscriptionError.unknown); return }
        SwiftyStoreKit.purchaseProduct(type.rawValue, quantity: 1, atomically: true) { result in
            switch result {
            case .success:
                SubscriptionManager.verify([type], onSuccess: { result in
                    guard let first = result.first else { onError(SubscriptionError.unknown); return }
                    onSuccess(first)
                }, onError: onError)
            case .error(let error):
                onError(error)
            }
        }
    }
    
}

extension ReceiptItem {
    
    var isExpired: Bool {
        let now = Date()
        if subscriptionExpirationDate ?? now < now {
            return true
        } else {
            return false
        }
    }
    
}

// MARK: - Rx Funcs
extension SubscriptionManager {
    
//    static func product() -> Single<SKProduct> {
//        return Single.create { observer in
//            SwiftyStoreKit.retrieveProductsInfo([SubscriptionType.month.rawValue]) { result in
//                if let product = result.retrievedProducts.first {
//                    observer(.success(product))
//                } else if result.invalidProductIDs.first != nil {
//                    assertionFailure("invalid product name")
//                } else if let error = result.error {
//                    observer(.error(error))
//                }
//            }
//            return Disposables.create()
//        }
//    }
    
//    static func verify(_ types: [SubscriptionType]) -> Observable<[VerifySubscriptionResult]> {
//        return Observable.create { observer in
//            let appleValidator = AppleReceiptValidator(service: verifyReceiptURLType, sharedSecret: sharedSecret)
//            SwiftyStoreKit.verifyReceipt(using: appleValidator, completion: { result in
//                switch result {
//                case .success(let receipt):
//                    observer.onNext(types.map {
//                        let verifySubscriptionResult = SwiftyStoreKit.verifySubscription(ofType: .autoRenewable, productId: $0.rawValue, inReceipt: receipt)
//                        return verifySubscriptionResult
//                    })
//                case .error(let error):
//                    observer.onError(error)
//                }
//            })
//            return Disposables.create()
//        }
//    }
//
//    static func restore() -> Observable<[VerifySubscriptionResult]> {
//        return Observable.create { observer in
//            SwiftyStoreKit.restorePurchases(atomically: true, completion: { results in
//                if results.restoredPurchases.count > 0 {
//                    observer.onNext([.month])
//                } else if results.restoreFailedPurchases.count > 0 {
//                    observer.onError(SubscriptionError(message: "Restore Failed"))
//                } else {
//                    observer.onError(SubscriptionError(message: "Nothing to restore"))
//                }
//                observer.onCompleted()
//            })
//            return Disposables.create()
//            }.timeout(RxTimeInterval(storeKitTimeout), scheduler: MainScheduler.instance)
//            .flatMapLatest(verify)
//    }
//
//    static func purchase(_ type: SubscriptionType) -> Observable<[VerifySubscriptionResult]> {
//        return Observable.create { observer in
//            guard SwiftyStoreKit.canMakePayments else { return Disposables.create() }
//            SwiftyStoreKit.purchaseProduct(type.rawValue, quantity: 1, atomically: true) { result in
//                switch result {
//                case .success:
//                    observer.onNext([type])
//                case .error(let error):
//                    observer.onError(error)
//                }
//                observer.onCompleted()
//            }
//            return Disposables.create()
//            }.timeout(RxTimeInterval(storeKitTimeout), scheduler: MainScheduler.instance)
//            .flatMapLatest(verify)
//    }
    
}
