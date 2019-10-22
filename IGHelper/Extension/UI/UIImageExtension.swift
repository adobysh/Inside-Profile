//
//  UIImageExtension.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/22/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

extension UIImage {
    
    public static func load(_ urlString: String?, onComplete: @escaping (_ image: UIImage?, _ url: String?)->()) {
        DispatchQueue.global().async {
            guard let imageUrl = URL(string: urlString ?? ""), let imageData = try? Data(contentsOf: imageUrl) else { return }
            let image = UIImage(data: imageData)
            DispatchQueue.main.async {
                onComplete(image, urlString)
            }
        }
    }
    
}
