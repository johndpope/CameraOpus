//
//  RThree.swift
//  CameraOpus
//
//  Created by Abheek Basu on 5/6/19.
//  Copyright © 2019 CameraOpus. All rights reserved.
//

import Foundation

class RThree: NSObject {
    
    let xco: Float
    let yco: Float
    let zco: Float
    
    init(x: Float, y: Float, z: Float) {
        xco = x
        yco = y
        zco = z
    }
    
    private func getX() -> Float{
        return xco
    }
    
    private func getY() -> Float{
        return yco
    }
    
    private func getZ() -> Float{
        return zco
    }
}
