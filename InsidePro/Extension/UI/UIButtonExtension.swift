//
//  UIButtonExtension.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 10/22/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

extension UIButton {
    
    private func imageWithColor(color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()

        context?.setFillColor(color.cgColor)
        context?.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    func setBackgroundColor(_ color: UIColor?, for state: UIControl.State) {
        guard let color = color else {
            setBackgroundImage(imageWithColor(color: .clear), for: state)
            return
        }
        setBackgroundImage(imageWithColor(color: color), for: state)
    }
    
}
