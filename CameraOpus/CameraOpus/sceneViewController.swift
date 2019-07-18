
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
    
    var materialImage : UIImage?
    
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
        print("in scene set up")
        let scene = SCNScene()
        print("the folder we are looking for is ",fileName )
        
        var assetUrl = Bundle.main.url(forResource: fileName, withExtension: "obj", subdirectory: "models.scnassets")
        
        var fileSystemFlag = false
        
        if assetUrl == nil
        {
            fileSystemFlag = true
            
            do {
                let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                
                var newDestinationUrl = documentsUrl.appendingPathComponent("model")
                
                let subDirs = newDestinationUrl.subDirectories
                
                /*
                 * Iterate through folders until we find the right one
                 *
                 *
                 */
                
                for x in subDirs{
                    if ((x.isDirectory) && (x.path.contains(fileName))){
                        let directoryContents = try FileManager.default.contentsOfDirectory(at: x, includingPropertiesForKeys: nil)
                        
                        let modelFiles = directoryContents.filter{ $0.path.contains(fileName) }
                        
                        let objFiles = modelFiles.filter{
                            $0.path.contains("obj")
                        }
                        
                        print("model files are", modelFiles)
                        print("obj files are", objFiles)
                        
                        assetUrl = objFiles[0]
                        print("we set the asset URL to the obj file in docs")
                        
                        let materialFiles = modelFiles.filter{
                            $0.path.contains("png")
                        }
                        print("material files are", materialFiles)
                        
                        materialImage = UIImage(contentsOfFile: materialFiles[0].path)
                        
                    }
                }
                
                //let directoryContents = try FileManager.default.contentsOfDirectory(at: newDestinationUrl, includingPropertiesForKeys: nil)
                
                
                
                /*
                 * for some reason the path extension attempt did not work
                 *
                 * .pathextension == ".obj"
                 */
                
                
            }
            catch{
                print(error)
                fatalError("could not find file")
            }
                    //print("couldn't find, ", fileName)
                    //fatalError("Failed to find model file.")
            }
        
        assetLocation = assetUrl
        
        let asset = MDLAsset(url:assetUrl!)
        
        guard let object = asset.object(at: 0) as? MDLMesh
            else { fatalError("Failed to get mesh from asset.") }
        
        let newNode  = SCNNode(mdlObject: object)
        
        /*
         * The following condition is only ever true if
         * We are loading a models from models.scnassets
         * ie not from the documents folder
         */
        
        if(!fileSystemFlag){
            print("the material we are loading is ", modelName)
            
            guard let assetMaterialUrl = Bundle.main.path(forResource: fileName, ofType: "png", inDirectory: "models.scnassets")
                else { fatalError("Failed to find model texture.") }
            
             materialImage = UIImage(contentsOfFile: assetMaterialUrl)
        }

        
        //youtube.com/watch?v=D2UWvR2nR0A
    
        //print("the asset url is ", assetMaterialUrl)
    
        newNode.geometry?.firstMaterial?.diffuse.contents = materialImage!
        
        /*
         * flag for testing print statements
        */
//        let testing = false
//        if testing{
//            print("the width of the material is ", tempim?.size.width)
//            print("the height of the material is ", tempim?.size.height)
//            print("the model name is", String(fileName + ".png") )
//        }
        
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
    
    /*
     * Workspace
     *
     *  We could try this later:
     *
     *    let material = SCNMaterial()
     *    material.diffuse.contents = UIImage(named: "texture.png")
     *
     *    //Create the the node and apply texture
     *    objectNode?.geometry?.materials = [material]
     *
    */
    
}

