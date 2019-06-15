//
//  ThreeDFileViewController.swift
//  CameraOpus
//
//  Created by Abheek Basu on 6/14/19.
//  Copyright © 2019 CameraOpus. All rights reserved.
//

import Foundation
import UIKit

class ThreeDFileViewController : UIViewController {
    
    static func storyboardInstance() -> ThreeDFileViewController? {
        let storyboard = UIStoryboard(name: "ThreeDFileViewController", bundle: nil)
        return storyboard.instantiateInitialViewController() as? ThreeDFileViewController
    }
    
    
    
    
}
