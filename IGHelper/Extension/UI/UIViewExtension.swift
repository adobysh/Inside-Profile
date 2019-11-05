//
//  ViewExtension.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 7/8/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

// MARK: IB
extension UIView {
    
    @IBInspectable var borderColor: UIColor? {
        set {
            layer.borderColor = newValue?.cgColor
        }
        get {
            guard let color = layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: color)
        }
    }
    
}

// MARK: Scalable
extension UIView {
    
    func callRecursively(level: Int = 0, _ body: (_ subview: UIView, _ level: Int) -> Void) {
        body(self, level)
        subviews.forEach { $0.callRecursively(level: level + 1, body) }
    }
    
    func scale() {
        callRecursively { (subview, level) in
            if let label = subview as? UILabel {
                label.scaleFont()
            }
            if let button = subview as? UIButton {
                button.scaleFont()
            }
//            if let stackView = subview as? UIStackView {
//                stackView.scaleSpacing()
//            }
//            if let textView = subview as? UITextView {
//                textView.scaleFont()
//            }
            for constraint in subview.constraints {
                if let constraint = constraint as? ScalableConstraint {
                    constraint.scale()
                }
            }
        }
    }
    
    class var identifier: String {
        return String(describing: self)
    }
    
}

// MARK: TapGestureRecognizer
extension UIView {
    
    fileprivate struct AssociatedObjectKeys {
        static var tapGestureRecognizer = "MediaViewerAssociatedObjectKey_mediaViewer"
    }
    
    fileprivate typealias Action = (() -> Void)?
    
    fileprivate var tapGestureRecognizerAction: Action? {
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedObjectKeys.tapGestureRecognizer, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            }
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectKeys.tapGestureRecognizer) as? Action
        }
    }
    
    public func addTapGestureRecognizer(action: (() -> Void)?) {
        tapGestureRecognizerAction = action
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc fileprivate func handleTapGesture(sender: UITapGestureRecognizer) {
        if let action = tapGestureRecognizerAction {
            action?()
        } else {
            print("no action")
        }
    }
}
