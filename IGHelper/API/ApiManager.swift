//
//  ApiManager.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 7/23/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import Foundation
import Alamofire

enum ApiError: Error {
    case unknown
    case bad_password
    case invalid_user
}

class ApiManager {
    
    static let shared = ApiManager()
    
    private let baseUrl = "https://api.instagram.com/v1/"
    
    private init() {}
    
    func getUserInfo(onComplete: @escaping ((profileInfo: ProfileInfoData, postDataArray: [PostData])) -> (), onError: @escaping (Error) -> ()) {
        getProfileInfo(onComplete: { [weak self] profileInfoData in
            self?.getPosts(onComplete: { postDataArray in
                onComplete((profileInfoData, postDataArray))
            }, onError: { error in
                onError(error)
            })
        }) { error in
            onError(error)
        }
    }
    
    private func getProfileInfo(onComplete: @escaping (ProfileInfoData) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://i-info.n44.me/user/info/me"
        guard let cookies = AuthorizationManager.shared.cookies else { return }
        guard let session = AuthorizationManager.shared.session else { return }
        
        let parameters: [String: String] = [
            "cookies" : cookies,
            "session" : session
        ]
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).response { response in
            guard let data = response.data else { return }
            do {
                let decoder = JSONDecoder()
                let container = try decoder.decode(ProfileInfoData.self, from: data)
                print("!!! ProfileInfoData \(container)")
                guard let _ = container.username else {
                    onError(ApiError.unknown)
                    return
                }
                onComplete(container)
            } catch {
                onError(error)
            }
        }
    }
    
    private func getPosts(onComplete: @escaping ([PostData]) -> (), onError: @escaping (Error) -> ()) {
        let url = "https://i-info.n44.me/user/posts/me"
        guard let cookies = AuthorizationManager.shared.cookies else { return }
        guard let session = AuthorizationManager.shared.session else { return }
        
        let parameters: [String: String] = [
            "cookies" : cookies,
            "session" : session
        ]
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).response { response in
            guard let data = response.data else { return }
            do {
                let decoder = JSONDecoder()
                let container = try decoder.decode(PostsContainerData.self, from: data)
                print("!!! ProfileInfoData \(container)")
                guard let posts = container.feed else {
                    onError(ApiError.unknown)
                    return
                }
                let notNilposts = posts.compactMap { $0 }
                onComplete(notNilposts)
            } catch {
                onError(error)
            }
        }
    }
    
}
