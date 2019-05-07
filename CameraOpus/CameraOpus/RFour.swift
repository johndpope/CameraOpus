//
//  RThree.swift
//  CameraOpus
//
//  Created by Abheek Basu on 5/6/19.
//  Copyright © 2019 CameraOpus. All rights reserved.
//

import Foundation

class RFour: NSObject {
    
    let alpha: CGFloat
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    
    init(a: CGFloat, r: CGFloat, g: CGFloat, b: CGFloat) {
        alpha = a
        red = r
        green = g
        blue = b
    }
    
    private func geta() -> CGFloat{
        return alpha
    }
    
    private func getr() -> CGFloat{
        return red
    }
    
    private func getg() -> CGFloat{
        return green
    }
    
    private func getb() -> CGFloat{
        return blue
    }
}
