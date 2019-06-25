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
    
    @IBOutlet weak var sceneView: SCNView!
    //var modelName: String?
    var modelName = "modelOne"
    
    override func viewDidLoad() {
        testText.text = modelName
    }
    
    
    
    func sceneSetUp(fileName: String){
        let scene = SCNScene()

        guard let assetUrl = Bundle.main.url(forResource: fileName, withExtension: "obj", subdirectory: "models.scnassets")
            else { fatalError("Failed to find model file.") }
        
        let asset = MDLAsset(url:assetUrl)
        guard let object = asset.object(at: 0) as? MDLMesh
            else { fatalError("Failed to get mesh from asset.") }
        
        let newNode  = SCNNode(mdlObject: object)
        
//        guard let assetMaterialUrl = Bundle.main.url(forResource: fileName, withExtension: "png", subdirectory: "models.scnassets")
//            else { fatalError("Failed to find model file.") }
//
//        print("the asset url is ", assetMaterialUrl)
        
        //youtube.com/watch?v=D2UWvR2nR0A
        newNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: modelName + ".png")
        
//        newNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: assetMaterialUrl)
        
        
        scene.rootNode.addChildNode(newNode)
        
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        // we need this to see the item's texture
        sceneView.autoenablesDefaultLighting = true

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //we set modelName to the correct modelName
        sceneSetUp(fileName: modelName)
    }
    
    
    
    
}
