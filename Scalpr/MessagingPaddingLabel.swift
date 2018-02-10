//
//  PaddingLabel.swift
//  Scalpr
//
//  Created by Cam Connor on 12/14/16.
//  Copyright © 2016 ProQuo. All rights reserved.
//

import Foundation

@IBDesignable class MessagingPaddingLabel: UILabel {
    
    @IBInspectable var topInset: CGFloat = 5.0
    @IBInspectable var bottomInset: CGFloat = 5.0
    @IBInspectable var leftInset: CGFloat = 10.0
    @IBInspectable var rightInset: CGFloat = 10.0
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override var intrinsicContentSize : CGSize {
        var intrinsicSuperViewContentSize = super.intrinsicContentSize
        
        let textWidth = frame.size.width - (self.leftInset + self.rightInset)
        let newSize = self.text!.boundingRect(with: CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: self.font], context: nil)
        intrinsicSuperViewContentSize.height = ceil(newSize.size.height) + self.topInset + self.bottomInset
        
        return intrinsicSuperViewContentSize
    }
    
}
