
//
//  sceneViewController.swift
//  CameraOpus
//
//  Created by Abheek Basu on 6/17/19.
//  Copyright © 2019 CameraOpus. All rights reserved.
//

/*
 TO DO:
 
 - dynamic model load function
 - - try to send filename in ThreeDFileViewer Controller to sceneViewController
 
 - www.justindoan.com/tutorials/2016/9/9/creating-and-exporting-a-csv-file-in-swift
 
 */


import Foundation
import UIKit
import SceneKit
import SceneKit.ModelIO
import MessageUI



class sceneViewController : UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var testText: UILabel!
    
    @IBOutlet weak var sceneView: SCNView!
    
    var assetLocation : URL?
    
    //var modelName: String?
    var modelName = "modelOne"
    
    @IBAction func exportFile(_ sender: UIButton) {
        print("in export file")
        createEmail()
    }
    
    /*
     * Lets try presenting this from the navigation view controller not the sceneview
     */
    
    func createEmail(){
        if MFMailComposeViewController.canSendMail() {
            print("we can send email")
            let emailController = MFMailComposeViewController()
            
            emailController.mailComposeDelegate = self
            emailController.setToRecipients([]) //I usually leave this blank unless it's a "message the developer" type thing
            emailController.setSubject("Exported by CameraOpus")
            emailController.setMessageBody("Please find your wonderful model attached", isHTML: false)
            
            do{ emailController.addAttachmentData(try Data(contentsOf: assetLocation!), mimeType: "text/plain", fileName: String(modelName + ".obj"))
            }
            catch{
                print("there was issue with attaching the file")
            }

            self.present(emailController, animated: true, completion: nil)
            
        }
    }
    
    /*
     * This worked but not the very similar function below straight from apple's site, which we are keeping for posterity
     *
     * it seems to be both the '_' before controller and NSError vs Error that makes this function work
    */
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        print("called")
        controller.dismiss(animated: true, completion: nil)
    }
    
//    func mailComposeController(controller: MFMailComposeViewController,
//                               didFinishWithResult result: MFMailComposeResult, error: NSError?) {
//        controller.dismiss(animated: true, completion: nil)
//    }
//
    
    override func viewDidLoad() {
        testText.text = modelName
        print("the model is ",modelName)
    }
    
    
    func sceneSetUp(fileName: String){
        let scene = SCNScene()

        guard let assetUrl = Bundle.main.url(forResource: fileName, withExtension: "obj", subdirectory: "models.scnassets")
            else { fatalError("Failed to find model file.") }
        
        assetLocation = assetUrl
        
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
