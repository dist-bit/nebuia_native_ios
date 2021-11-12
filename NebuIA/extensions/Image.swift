//
//  Image.swift
//  NebuIA
//
//  Created by Miguel on 24/06/21.
//

import AVFoundation

extension UIImage {
    
    func imageWithInsets(insets: UIEdgeInsets) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: self.size.width + insets.left + insets.right,
                   height: self.size.height + insets.top + insets.bottom), false, self.scale)
        let _ = UIGraphicsGetCurrentContext()
        let origin = CGPoint(x: insets.left, y: insets.top)
        self.draw(at: origin)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithInsets
    }
    
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func crop( rect: CGRect) -> UIImage {
        var rect = rect
        rect.origin.x*=self.scale
        rect.origin.y*=self.scale
        rect.size.width*=self.scale
        rect.size.height*=self.scale
        
        let imageRef = self.cgImage!.cropping(to: rect)
        let image = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
        return image
    }
    
    static func emptyImage(with size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func cropToRect(rect: CGRect, viewSize: CGSize) -> CGRect? {
        
        var cr = rect
        
        switch self.imageOrientation {
        case .right, .rightMirrored, .left, .leftMirrored:
            // rotate the crop rect if needed
            cr.origin.x = rect.origin.y
            cr.origin.y = rect.origin.x
            cr.size.width = rect.size.height
            cr.size.height = rect.size.width
            
        default:
            break
        }
        
        let imageViewScale = max(self.size.width / viewSize.width,
                                 self.size.height / viewSize.height)
        
        // scale the crop rect
        let cropZone = CGRect(x:cr.origin.x * imageViewScale,
                              y:cr.origin.y * imageViewScale,
                              width:cr.size.width * imageViewScale,
                              height:cr.size.height * imageViewScale)
        
        return cropZone
    }
    
}

extension CVImageBuffer {
    func toUIImage() -> UIImage {
        
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags.readOnly);
        
        // Get the number of bytes per row for the pixel buffer
        let baseAddress = CVPixelBufferGetBaseAddress(self);
        
        // Get the number of bytes per row for the pixel buffer
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self);
        // Get the pixel buffer width and height
        let width = CVPixelBufferGetWidth(self);
        let height = CVPixelBufferGetHeight(self);
        
        // Create a device-dependent RGB color space
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        // Create a bitmap graphics context with the sample buffer data
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue
        let context = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        let quartzImage = context?.makeImage();
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags.readOnly);
        // Create an image object from the Quartz image
        let image = UIImage.init(cgImage: quartzImage!)
        // rorate image
        let rotated = image.rotate(radians: .pi/2)
        return (rotated!);
    }
}

extension CMSampleBuffer {
    func toUIImage() -> UIImage {
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        let  imageBuffer = CMSampleBufferGetImageBuffer(self);
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
        
        // Get the number of bytes per row for the pixel buffer
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!);
        
        // Get the number of bytes per row for the pixel buffer
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!);
        // Get the pixel buffer width and height
        let width = CVPixelBufferGetWidth(imageBuffer!);
        let height = CVPixelBufferGetHeight(imageBuffer!);
        
        // Create a device-dependent RGB color space
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        // Create a bitmap graphics context with the sample buffer data
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue
        let context = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        let quartzImage = context?.makeImage();
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
        // Create an image object from the Quartz image
        let image = UIImage.init(cgImage: quartzImage!)
        // rorate image
        let rotated = image.rotate(radians: .pi/2)
        return (rotated!);
    }
}
