//
//  PixelExtractor.swift
//  CameraOpus
//
//  Created by Abheek Basu on 5/5/19.
//  Copyright © 2019 CameraOpus. All rights reserved.

import Foundation
import UIKit
import AVFoundation
import Photos

class PixelExtractor: NSObject {
    
    let image: CGImage
    let context: CGContext?
    
    var width: Int {
        get {
            return image.width
        }
    }
    
    var height: Int {
        get {
            return image.height
        }
    }
    
    init(img: CGImage) {
        image = img
        context = PixelExtractor.createBitmapContext(cgImage: img)
    }
    
    class func createBitmapContext(cgImage: CGImage) -> CGContext {
        
        // Get image width, height
        let pixelsWide = cgImage.width
        let pixelsHigh = cgImage.height
        
        let bitmapBytesPerRow = pixelsWide * 4
        let bitmapByteCount = bitmapBytesPerRow * Int(pixelsHigh)
        
        // Use the generic RGB color space.
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Allocate memory for image data. This is the destination in memory
        // where any drawing to the bitmap context will be rendered.
        let bitmapData = malloc(bitmapByteCount)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        let size = CGSize(width: pixelsWide, height: pixelsHigh)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        // create bitmap
        let context = CGContext(data: bitmapData, width: pixelsWide, height: pixelsHigh, bitsPerComponent: 8,
                                bytesPerRow: bitmapBytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        // draw the image onto the context
        let rect = CGRect(x: 0, y: 0, width: pixelsWide, height: pixelsHigh)
        context?.draw(cgImage, in: rect)
        
        return context!
    }
    
    private func colorAt(x: Int, y: Int)->UIColor {
        
        assert(0<=x && x<width)
        assert(0<=y && y<height)
        
        let data = context!.data!
        
        let offset = 4 * (y * width + x)
        
        let alpha = CGFloat(data.load(fromByteOffset: offset, as: UInt8.self)) / 255.0
        let red = CGFloat(data.load(fromByteOffset: offset+1, as: UInt8.self)) / 255.0
        let green = CGFloat(data.load(fromByteOffset: offset+2, as: UInt8.self)) / 255.0
        let blue = CGFloat(data.load(fromByteOffset: offset+3, as: UInt8.self)) / 255.0
        
        let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        
        return color
    }
}
