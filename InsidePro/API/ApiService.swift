//
//  ApiService.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 7/18/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import Foundation
import Alamofire
import SwiftKeychainWrapper

public enum Status: String, Codable {
    case success
    case error
}

public class BaseResponse<T: Codable>: Codable {
    
    public var status: Status
    public var data: T?
    public var error: String?
    
    private enum CodingKeys: String, CodingKey {
        case status
        case data
        case error = "error_message"
    }
    
    public required init(from decoder: Decoder) throws {
        let response = try decoder.container(keyedBy: CodingKeys.self)
        status = try response.decode(Status.self, forKey: .status)
        data = try response.decode(T?.self, forKey: .data)
        error = try response.decode(String?.self, forKey: .error)
    }
    
}

class ApiService {
    
    static let shared = ApiService()
    
    private static let baseHOST = "https://instadoo.n44.me"
    private static let api = "/api"
    private let uuidKey = "UUIDKey"
    
    typealias Response<T: Codable> = (response: T?, error: ApiError?)
    
    enum ApiErrorType {
        case noInternet
        case custom
    }
    
    struct ApiError: Error {
        var type: ApiErrorType
        var message: String?
        
        init(type: ApiErrorType, message: String? = nil) {
            self.type = type
            self.message = message
        }
        
        static let defaultError = ApiError(type: .custom, message: "Unknown error")
        static let defaultServerError = ApiError(type: .custom, message: "Something went wrong. Please, try again later")
        static let decodingError = ApiError(type: .custom, message: "Decoding error")
    }
    
    public func registerReceipt(price: NSDecimalNumber? = nil, currency: String? = nil, place: String, completion: @escaping (Response<Bool>) -> ()) {
        guard let receiptURL = Bundle.main.appStoreReceiptURL, let receiptData = try? Data(contentsOf: receiptURL) else {
            completion(Response(response: nil, error: .defaultError))
            return
        }
        let parameters: [String: Any] = [
            "receipt": receiptData.base64EncodedString(),
            "item_price": price ?? 0,
            "fb_currency": currency ?? "undefined",
            "facebook_data": AppAnalytics.getFBParameters(),
            "appsflyer_data": AppAnalytics.getAppsflyerParameters(),
            "place": place
        ]
        Alamofire.request(ApiService.baseHOST + ApiService.api + "/buy", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: getHeaders()).responseData { response in
            self.handleResponse(response, completion: completion)
        }
    }
    
//    public func sendUserInfo(completion: @escaping (Response<Bool>) -> ()) {
//        Alamofire.request(ApiService.baseHOST + ApiService.api + "/user", method: .post, parameters: userInfo, encoding: JSONEncoding.default, headers: getHeaders()).responseData { response in
//            self.handleResponse(response, completion: completion)
//        }
//    }
    
    public func getHeaders() -> HTTPHeaders {
        var headers: HTTPHeaders = [:]
        if let uuid = getDeviceUUID() {
            headers["ios-device-token"] = uuid
        }
//        if let pushToken = getPushToken() {
//            headers["ios-push-token"] = pushToken
//        }
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            headers["version"] = version
        }
        headers["language"] = Locale.current.languageCode
        headers["timezone"] = TimeZone.current.identifier
        return headers
    }
    
    private func getDeviceUUID() -> String? {
        if let uuid = KeychainWrapper.standard.string(forKey: uuidKey) {
            return uuid
        } else {
            if let uuid = UIDevice.current.identifierForVendor?.uuidString {
                KeychainWrapper.standard.set(uuid, forKey: uuidKey)
                return uuid
            }
            return nil
        }
    }
    
    private func handleResponse<T: Codable>(_ response: DataResponse<Data>, completion: @escaping (Response<T>) -> ()) {
        if let error = response.error {
            let code = (error as NSError).code
            if code == NSURLErrorNotConnectedToInternet {
                completion(Response(response: nil, error: ApiError(type: .noInternet)))
                return
            } else {
                completion(Response(response: nil, error: ApiError(type: .custom, message: error.localizedDescription)))
                return
            }
        }
        guard let jsonData = response.data else {
            completion(Response(response: nil, error: .defaultError))
            return
        }
        do {
            let response = try JSONDecoder().decode(BaseResponse<T>.self, from: jsonData)
            guard let decodedResponse = response.data else {
                completion(Response(response: nil, error: ApiError(type: .custom, message: response.error)))
                return
            }
            completion(Response(response: decodedResponse, error: nil))
        } catch let decodingError {
            print("----------------------")
            print("Decoding Error: \(decodingError)")
            print("----------------------")
            completion(Response(response: nil, error: .decodingError))
            return
        }
    }
    
}
