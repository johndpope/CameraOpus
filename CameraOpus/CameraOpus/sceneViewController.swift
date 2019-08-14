
//
//  sceneViewController.swift
//  CameraOpus
//
//  Created by Abheek Basu on 6/17/19.
//  Copyright © 2019 CameraOpus. All rights reserved.
//

/*
 TO DO:
 
 - www.justindoan.com/tutorials/2016/9/9/creating-and-exporting-a-csv-file-in-swift
 - show parts button only if segmentation is possible
 
 */

/*
 *  Segments Flow:
 *  button touch (seeParts) -> reads '.seg' file (readSegments) and passes to readFiletoCloud
 *  readFiletoCloud reads the obj file, gets only the vertices (indexOfFirstVertex) --> returns data structures consisting of point clouds and their colours
 *
 */


import Foundation
import UIKit
import SceneKit
import SceneKit.ModelIO
import MessageUI



class sceneViewController : UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var testText: UILabel!
    
    @IBOutlet weak var sceneView: SCNView!
    
    var scene: SCNScene?
    
    var assetLocation : URL?
    
    var materialLocation : URL?
    
    var materialImage : UIImage?
    
    //var modelName: String?
    var modelName = "modelOne"
    
    var partsPossible = false
    
    @IBAction func seeParts(_ sender: UIButton) {
        print("see parts")
        // testing
        partsPossible = true
        //
        
        if(partsPossible){
            sceneView.backgroundColor = UIColor.black
            //getNumberOfSegments()
            let segments = readSegments(segmentsLocation: assetLocation!.deletingPathExtension()
                .appendingPathExtension("seg"))
            var pointsAndColours = readFiletoCloud(segments: segments)
            let verts = pointsAndColours.verts
            let cols = pointsAndColours.cols
            for i in 0..<verts.count{
                var cloud = pointCloudNode(pointCloud: verts[i], colors: cols[i])
                cloud.position = SCNVector3(x: 0, y: 0, z: 0)
                cloud.geometry?.firstMaterial?.lightingModel = SCNMaterial.LightingModel.constant
                scene!.rootNode.addChildNode(cloud)
            }
            
        }
    }
    
    @IBAction func exportFile(_ sender: UIButton) {
        print("in export file")
        createEmail()
    }
    
    func readSegments(segmentsLocation: URL)->[Int]{
        print("in read segments")
        let contents = try? String (contentsOf: segmentsLocation)
        print("splitting lines")
        let segs = contents!.components(separatedBy: "\n")
        let intArray = segs.map { Int($0)!}
        print("the size of the array is", intArray.count)
        return intArray
    }
    
    /*
     returns the number of segments as well as each segment
     the result array's 0th element contains the number of segments
     
     eg: f: [3,2 3,4,3,6] --> [4,2,3,4,6]
     
     NB no longer true we removed the 0th element as the count
    */
    
    func getNumberOfSegments(input: [Int]) -> [Int]{
        
        var result : [Int] = []
        let uniques = input.unique()
        //let a = ["four","one", "two", "one", "three","four", "four"]
        //print("these are the uniques")
        //result.append(uniques.count)
        
        for item in uniques{
            result.append(item)
            print(item)
        }
        //print(a.unique) // ["four", "one", "two", "three"]
        return result
    }
    
    /*
     * This makes sure that the files read have asci characters and throw errors
     */
    
    func convertString(string: String) -> String {
        var data = string.data(using: String.Encoding.ascii, allowLossyConversion: true)
        return NSString(data: data!, encoding: String.Encoding.ascii.rawValue) as! String
    }
    
    /*
     * The structure of the point cloud
    */
    struct PointCloudVertex {
        var x: Float, y: Float, z: Float
        var r: Float, g: Float, b: Float
    }
    
    func buildNode(points: [PointCloudVertex]) -> SCNNode {
        print("in buildNode")
        let vertexData = NSData(
            bytes: points,
            length: MemoryLayout<PointCloudVertex>.size * points.count
        )
        let positionSource = SCNGeometrySource(
            data: vertexData as Data,
            semantic: SCNGeometrySource.Semantic.vertex,
            vectorCount: points.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<PointCloudVertex>.size
        )
        let colorSource = SCNGeometrySource(
            data: vertexData as Data,
            semantic: SCNGeometrySource.Semantic.color,
            vectorCount: points.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: MemoryLayout<Float>.size * 3,
            dataStride: MemoryLayout<PointCloudVertex>.size
        )
        let element = SCNGeometryElement(
            data: nil,
            primitiveType: .point,
            primitiveCount: points.count,
            bytesPerIndex: MemoryLayout<Int>.size
        )
        
        // for bigger dots
        element.pointSize = 2
        element.minimumPointScreenSpaceRadius = 2
        element.maximumPointScreenSpaceRadius = 2
        
        let pointsGeometry = SCNGeometry(sources: [positionSource, colorSource], elements: [element])
        
        return SCNNode(geometry: pointsGeometry)
    }
    
    /*
     * Converts the scnvector 3 point cloud into something we can add to the scene
     */
    
    func pointCloudNode(pointCloud: [SCNVector3], colors:[UInt8]  ) -> SCNNode {
        print("in pointCloudNode")
        print("There are" , pointCloud.count, "points")
        //print(pointCloud)
        let points = pointCloud
        var vertices = Array(repeating: PointCloudVertex(x: 0,y: 0,z: 0,r: 0,g: 0,b: 0), count: points.count)
        
        for i in 0..<points.count {
            let p = points[i]
            vertices[i].x = Float(p.x)
            vertices[i].y = Float(p.y)
            vertices[i].z = Float(p.z)
            vertices[i].r = Float(colors[i * 4]) / 255.0
            vertices[i].g = Float(colors[i * 4 + 1]) / 255.0
            vertices[i].b = Float(colors[i * 4 + 2]) / 255.0
        }
        
        let node = buildNode(points: vertices)
        return node
    }
    
    
    /*
     Takes in obj file input (in a string array) and outputs the index of the fist line containing a vertex. I.E it discounts the header of the file
    */
    func indexOfFirstVertex(objContents: [String])-> Int{
        var counter = 0
        while counter < objContents.count{
            let currentLine = objContents[counter]
            if currentLine.range(of: #"^v "#, options: .regularExpression) != nil{
                return counter
            }
            counter = counter + 1
        }
        // we should only get here if the array does not contain what we are looking for
        return -1
    }
    
    
    /*
     * Filter the vertex lines for a specifc segment
     * f: ->
     */
    
    
    func filterVertices(data: [String], segmentClass: Int, segments: [Int] )->[String]{
        var result : [String] = []
        for i in 0..<segments.count {
            if segments[i] == segmentClass{
                result.append(data[i])
            }
        }
        print("we found",result.count , "instances of this class", segmentClass)
        return(result)
    }
    
    /*
     * What happens if int is largest than largest int?
     *
     *
     * Real obj file conatins v  x_1 x_2 x_3
     * Ie there are two spaces between the v and the 1st element
    */
    
    func readFiletoCloud(segments: [Int]) -> (verts: [[SCNVector3]], cols: [[UInt8]]) {
        print("in read File to Cloud" )
        let testFileUrl = assetLocation!
        print("the file we are going to parse is", testFileUrl.path)
        /*
         * do we need to wrap a bunch of this in a proper try catch?
        */
        let testContents = try? String (contentsOf: testFileUrl)
        print("splitting lines")
        var points : [String] = convertString(string: testContents!).components(separatedBy: "\n")
        //testContents.removeAll()
        
        let vertexStart = indexOfFirstVertex(objContents: points)
        let vertexLines = Array(points[vertexStart..<(vertexStart+segments.count)])
        
        // make sure this doesnt result in any weird reference errors
        points.removeAll()
        print("conversion is complete")
        //points.removeFirst()
        print("there are", vertexLines.count, "points in this function")
        
        var cloudResult = [[SCNVector3]]()
        var colorResult = [[UInt8]]()
        
        let segmentClasses = getNumberOfSegments(input: segments)
        print("segmentClasses", segmentClasses)
        for i in 0..<segmentClasses.count{
            
            /*
             * Need to add a filter function that filters vertexLines for the segment and passes that in to createVertexData
             */
            
            let segmentValues = createVertexData(vertexLines: filterVertices(data:vertexLines,segmentClass: segmentClasses[i], segments: segments), segment: segmentClasses[i], colorChoice: i)
            //print("In", i, "we found",segmentValues.coords )
            cloudResult.append(segmentValues.coords)
            colorResult.append(segmentValues.cols)
        }
        return (verts: cloudResult,cols: colorResult)
    }
    
    /*
     *
     *  Takes in the input from a file and creates the scnvector3 representation of a point cloud
     *  This representation will then later be converted into the vertexdata struct format needed to actually build the cloud on a screen
     *
     *  NB
     *  This needs to be adapated if the number of segmens is increased beyond 4
     *  NB
     *
     */
    func createVertexData(vertexLines: [String], segment: Int, colorChoice: Int)->(coords: [SCNVector3], cols:[UInt8]){
        
        print ("in create vertex data")
        
        /*
         * the if statement below is the check for the null case
         * It shouldnt ever get there because the segments are
        */
        
        var vertices = Array<SCNVector3>(repeating: SCNVector3(x:0,y:0,z:0), count: vertexLines.count)
        
        if vertexLines.count == 0{
            return (vertices, [UInt8]())
        }
        
        for i in 0..<(vertexLines.count) {
            let line = vertexLines[i]
            let x = Double(line.components(separatedBy: " ")[1])!
            let y = Double(line.components(separatedBy: " ")[2])!
            let z = Double(line.components(separatedBy: " ")[3])!
            
            vertices[i].x = Float(x)
            vertices[i].y = Float(y)
            vertices[i].z = Float(z)
        }
        /*
         * This part needs to be determined more programittically, we need to automatically adjust to the number of segments the number of colours
         *
        */
        var colors : [UInt8] = Array(repeating: 0, count: vertexLines.count * 4)
        print("colors array created")
        if(colorChoice == 0){
            for index in 0 ..< (vertexLines.count) {
                colors[index * 4] = 250
            }
        }
        if(colorChoice == 1){
            for index in 0 ..< (vertexLines.count) {
                colors[(index * 4) + 1] = 250
            }
        }
        if(colorChoice == 2){
            for index in 0 ..< (vertexLines.count) {
                colors[(index * 4) + 2] = 250
            }
        }
        if(colorChoice == 3){
            for index in 0 ..< (vertexLines.count) {
                colors[(index * 4) + 1] = 250
                colors[(index * 4) + 0] = 250
            }
        }
        print("colors created")
        return (vertices, colors)
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
                print("there was issue with attaching the model")
            }
            
            do{ emailController.addAttachmentData(try Data(contentsOf: materialLocation!), mimeType: "image/png", fileName: String(modelName + ".png"))
            }
            catch{
                print("there was issue with attaching the png")
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
        scene = SCNScene()
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
                        
                        materialLocation = materialFiles[0]
                        //break
                        
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
            
            
            let assetMaterialUrl = Bundle.main.path(forResource: fileName, ofType: "png", inDirectory: "models.scnassets")
            if(assetMaterialUrl != nil){
                materialImage = UIImage(contentsOfFile: assetMaterialUrl!)
                materialLocation = URL(string:assetMaterialUrl!)
            }
            
                //else { fatalError("Failed to find model texture.") }
            
            
        }

        
        
        //youtube.com/watch?v=D2UWvR2nR0A
    
        //print("the asset url is ", assetMaterialUrl)
        if(materialImage != nil){
            newNode.geometry?.firstMaterial?.diffuse.contents = materialImage!
        }
        
        
        /*
         * flag for testing print statements
        */
//        let testing = false
//        if testing{
//            print("the width of the material is ", tempim?.size.width)
//            print("the height of the material is ", tempim?.size.height)
//            print("the model name is", String(fileName + ".png") )
//        }
        
        scene!.rootNode.addChildNode(newNode)
        
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

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: [Iterator.Element: Bool] = [:]
        return self.filter { seen.updateValue(true, forKey: $0) == nil }
    }
}

