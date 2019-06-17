//
//  sceneViewController.swift
//  CameraOpus
//
//  Created by Abheek Basu on 6/17/19.
//  Copyright © 2019 CameraOpus. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import SceneKit.ModelIO


class sceneViewController : UIViewController {
    
    @IBOutlet weak var testText: UILabel!
    
    //var modelName: String?
    var modelName = "example"
    
    override func viewDidLoad() {
        testText.text = modelName
    }
    
    
}
