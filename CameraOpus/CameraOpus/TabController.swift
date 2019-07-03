//
//  TabController.swift
//  CameraOpus
//
//  Created by Abheek Basu on 7/2/19.
//  Copyright © 2019 CameraOpus. All rights reserved.
//

import Foundation
import UIKit

/*
 * right now this class is not used
 */

class TabController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make self the UITabBarControllerDelegate
        self.delegate = self
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
//        if let vc = viewController as? FirstViewController {
//            myValue += 1
//            vc.firstViewSpecific(myValue)
//            return
//        }
//        
//        if let vc = viewController as? NearMeViewController {
//            vc.resetMe()
//            return
//        }
//
//        if let vc = viewController as? MapSearchViewController {
//            vc.resetMe()
//            return
//        }
        
    }
    
}
