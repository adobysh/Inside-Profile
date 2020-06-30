//
//  LabelWithAdaptiveTextHeight.swift
//  Instadoo
//
//  Created by Andrei Dobysh on 6/22/20.
//  Copyright © 2020 Andrei Dobysh. All rights reserved.
//

import Foundation
import UIKit

class LabelWithAdaptiveTextHeight: UILabel {

    override func layoutSubviews() {
        super.layoutSubviews()
        font = fontToFitHeight()
    }

    // Returns an UIFont that fits the new label's height.
    private func fontToFitHeight() -> UIFont {

        var minFontSize: CGFloat = 10 // DISPLAY_FONT_MINIMUM // CGFloat 18
        var maxFontSize: CGFloat = 42 // DISPLAY_FONT_BIG     // CGFloat 67
        var fontSizeAverage: CGFloat = 0
        var textAndLabelHeightDiff: CGFloat = 0

        while (minFontSize <= maxFontSize) {

            fontSizeAverage = minFontSize + (maxFontSize - minFontSize) / 2

            // Abort if text happens to be nil
            guard (text?.count ?? 0) > 0 else {
              break
            }

            if let labelText: NSString = text as NSString? {
                let labelHeight = frame.size.height

                let testStringHeight = labelText.size(
                    withAttributes: [NSAttributedString.Key.font: font.withSize(fontSizeAverage)]
                ).height

                textAndLabelHeightDiff = labelHeight - testStringHeight

                if (fontSizeAverage == minFontSize || fontSizeAverage == maxFontSize) {
                    if (textAndLabelHeightDiff < 0) {
                        return font.withSize(fontSizeAverage - 1)
                    }
                    return font.withSize(fontSizeAverage)
                }

                if (textAndLabelHeightDiff < 0) {
                    maxFontSize = fontSizeAverage - 1

                } else if (textAndLabelHeightDiff > 0) {
                    minFontSize = fontSizeAverage + 1

                } else {
                    return font.withSize(fontSizeAverage)
                }
            }
        }
        return font.withSize(fontSizeAverage)
    }
    
}
