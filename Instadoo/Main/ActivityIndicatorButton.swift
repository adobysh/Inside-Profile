//
//  ActivityIndicatorButton.swift
//  IGHelper
//
//  Created by Andrei Dobysh on 11/4/19.
//  Copyright © 2019 Andrei Dobysh. All rights reserved.
//

import UIKit

@IBDesignable
class ActivityIndicatorButton: UIView {
    
    @IBInspectable
    var value: String? = "Value" {
        didSet {
            valueLabel?.text = value
        }
    }
    
    @IBInspectable
    var valueDescription: String = "Title" {
        didSet {
            descriptionLabel?.text = valueDescription
        }
    }
    
    @IBInspectable
    var image: UIImage? {
        didSet {
            imageView?.image = image
        }
    }
    
    @IBOutlet var contentView: UIView?
    @IBOutlet var button: UIButton?
    @IBOutlet var valueLabel: UILabel?
    @IBOutlet var descriptionLabel: UILabel?
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView?
    @IBOutlet var imageView: UIImageView?
    
    var inProgress: Bool {
        set {
            if newValue {
                activityIndicatorView?.startAnimating()
            } else {
                activityIndicatorView?.stopAnimating()
            }
            valueLabel?.alpha = newValue ? 0 : 1
        }
        get {
            return activityIndicatorView?.isAnimating ?? false
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }
    
    init() {
        super.init(frame: .zero)
        initSubviews()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    func initSubviews() {
        contentView = loadViewFromNib()
        if let contentView = contentView {
            addSubview(contentView)
            contentView.frame = bounds
            contentView.autoresizingMask = [ .flexibleHeight, .flexibleWidth ]
        }
        valueLabel?.text = value
        descriptionLabel?.text = valueDescription
    }
    
    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as? UIView
        return view
    }
    
}
