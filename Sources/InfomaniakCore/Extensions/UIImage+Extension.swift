//
//  UIImage+Extension.swift
//  InfomaniakCore
//
//  Created by Philippe Weidmann on 03.07.20.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import UIKit

public class ImageUtil {
    internal typealias ImageOrientation = UIImage.Orientation

    public static func CGImageWithCorrectOrientation(_ image: UIImage) -> CGImage {

        if (image.imageOrientation == ImageOrientation.up) {
            return image.cgImage!
        }

        var transform = CGAffineTransform.identity

        switch (image.imageOrientation) {
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: image.size.height)
            transform = transform.rotated(by: .pi / -2.0)
            break
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.rotated(by: .pi / 2.0)
            break
        case .down, .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: image.size.height)
            transform = transform.rotated(by: .pi)
            break
        default:
            break
        }

        switch (image.imageOrientation) {
        case .rightMirrored, .leftMirrored:
            transform = transform.translatedBy(x: image.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break
        case .downMirrored, .upMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break
        default:
            break
        }

        let contextWidth: Int
        let contextHeight: Int

        switch (image.imageOrientation) {
        case .left, .leftMirrored,
             .right, .rightMirrored:
            contextWidth = (image.cgImage?.height)!
            contextHeight = (image.cgImage?.width)!
            break
        default:
            contextWidth = (image.cgImage?.width)!
            contextHeight = (image.cgImage?.height)!
            break
        }

        let context: CGContext = CGContext(data: nil, width: contextWidth, height: contextHeight,
            bitsPerComponent: image.cgImage!.bitsPerComponent,
            bytesPerRow: 0,
            space: image.cgImage!.colorSpace!,
            bitmapInfo: image.cgImage!.bitmapInfo.rawValue)!

        context.concatenate(transform)
        context.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: CGFloat(contextWidth), height: CGFloat(contextHeight)))

        let cgImage = context.makeImage()
        return cgImage!
    }

    public static func drawImageInBounds(_ image: UIImage, bounds: CGRect) -> UIImage? {
        return drawImageWithClosure(size: bounds.size, scale: UIScreen.main.scale) { (size: CGSize, context: CGContext) -> UIImage? in
            image.draw(in: bounds)

            let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()

            return image
        }
    }

    public static func croppedImageWithRect(_ image: UIImage, rect: CGRect) -> UIImage? {
        return drawImageWithClosure(size: rect.size, scale: image.scale) { (size: CGSize, context: CGContext) -> UIImage? in
            let drawRect = CGRect(x: -rect.origin.x, y: -rect.origin.y, width: image.size.width, height: image.size.height)
            context.clip(to: CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height))
            image.draw(in: drawRect)

            let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()

            return image
        }
    }

    public static func drawImageWithClosure(size: CGSize!, scale: CGFloat, closure: @escaping (_ size: CGSize, _ context: CGContext) -> UIImage?) -> UIImage? {

        guard size.width > 0.0 && size.height > 0.0 else {
            print("WARNING: Invalid size requested: \(size.width) x \(size.height) - must not be 0.0 in any dimension")
            return nil
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            print("WARNING: Graphics context is nil!")
            return nil
        }

        return closure(size, context)
    }
}

public extension UIImage {
    func resizeImage(size: CGSize) -> UIImage {
        let imgRef = ImageUtil.CGImageWithCorrectOrientation(self)
        let originalWidth = CGFloat(imgRef.width)
        let originalHeight = CGFloat(imgRef.height)
        let widthRatio = size.width / originalWidth
        let heightRatio = size.height / originalHeight

        let scaleRatio = max(heightRatio, widthRatio)

        let resizedImageBounds = CGRect(x: 0, y: 0, width: round(originalWidth * scaleRatio), height: round(originalHeight * scaleRatio))
        let resizedImage = ImageUtil.drawImageInBounds(self, bounds: resizedImageBounds)
        guard resizedImage != nil else {
            return UIImage()
        }


        return ImageUtil.drawImageInBounds(resizedImage!, bounds: CGRect(x: 0, y: 0, width: size.width, height: size.height)) ?? UIImage()
    }

    func maskImageWithRoundedRect(cornerRadius: CGFloat, borderWidth: CGFloat = 0, borderColor: UIColor? = UIColor.white) -> UIImage {

        let imgRef = ImageUtil.CGImageWithCorrectOrientation(self)
        let size = CGSize(width: CGFloat(imgRef.width) / self.scale, height: CGFloat(imgRef.height) / self.scale)

        return ImageUtil.drawImageWithClosure(size: size, scale: self.scale) { (size: CGSize, context: CGContext) -> UIImage? in

            let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

            UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
            self.draw(in: rect)

            if (borderWidth > 0 && borderColor != nil) {
                context.setStrokeColor(borderColor!.cgColor)
                context.setLineWidth(borderWidth)

                let borderRect = CGRect(x: 0, y: 0,
                    width: size.width, height: size.height)

                let borderPath = UIBezierPath(roundedRect: borderRect, cornerRadius: cornerRadius)
                borderPath.lineWidth = borderWidth * 2
                borderPath.stroke()
            }

            let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()

            return image
        } ?? UIImage()
    }

    class func imageFromColor(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()

        context!.setFillColor(color.cgColor)
        context!.fill(rect)

        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        UIGraphicsBeginImageContext(size)
        image?.draw(in: rect)
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image!
    }
}
