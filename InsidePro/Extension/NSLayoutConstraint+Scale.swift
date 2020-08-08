//
//  NSLayoutConstraint+Scalable.swift
//  Scanner
//
//  Created by Andrei Dobysh on 6/18/19.
//  Copyright © 2019 Nesus. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {

    func scale() {
        constant = Double(constant).scalable
    }

}
