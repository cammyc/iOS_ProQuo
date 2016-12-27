//
//  ImageHelper.swift
//  Scalpr
//
//  Created by Cam Connor on 9/30/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import Foundation

class ImageHelper {
    
    init(){}
    
    static func ResizeImage(image:UIImage, size:CGSize)-> UIImage {
        
        let scale  = UIScreen.main.scale
        let newSize = CGSize(width: size.width, height: size.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        let context = UIGraphicsGetCurrentContext()
        
        context!.interpolationQuality = CGInterpolationQuality.high

        image.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    static func circleImage(image: UIImage)->UIImage {
        let square = CGSize(width: min(image.size.width, image.size.height), height: min(image.size.width, image.size.height))
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: square))
        imageView.contentMode = .scaleAspectFill
        imageView.image = image
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
    
    static func centerImage(image: UIImage)->UIImage{
        let square = CGSize(width: min(image.size.width, image.size.height), height: min(image.size.width, image.size.height))
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: square))
        imageView.contentMode = .scaleAspectFill
        imageView.image = image
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
    
    static func textToImage(drawText: NSString, inImage: UIImage) -> UIImage{
        
        // Setup the font specific variables
        let textColor = UIColor.white
        let textFont = UIFont(name: "Helvetica Bold", size: 12)!
        
        // Setup the image context using the passed image
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(inImage.size, false, scale)
        
        let context = UIGraphicsGetCurrentContext()
        
        // Setup the font attributes that will be later used to dictate how the text should be drawn
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            ] as [String : Any]
        
        let textSize = drawText.size(attributes: textFontAttributes)

        
        // Put the image into a rectangle as large as the original image
        inImage.draw(in: CGRect(origin: CGPoint.zero, size: inImage.size))
        
        let rectangle = CGRect(x: 0, y: inImage.size.height - textSize.height - 2, width: inImage.size.width, height: textSize.height + 2)
        
        context!.setFillColor(UIColor.black.cgColor)
        context!.addRect(rectangle)
        context!.drawPath(using: .fill)
        

        // Create a point within the space that is as bit as the image
        let rect = CGRect(x: inImage.size.width / 2 - textSize.width / 2, y: inImage.size.height - textSize.height - 2, width: inImage.size.width / 2 + textSize.width / 2, height: inImage.size.height - textSize.height)
        
        // Draw the text into an image
        drawText.draw(in: rect, withAttributes: textFontAttributes)
        
        // Create a new image out of the images we have created
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the context now that we have the image we need
        UIGraphicsEndImageContext()
        
        //Pass the image back up to the caller
        return newImage!
        
    }

    
}
