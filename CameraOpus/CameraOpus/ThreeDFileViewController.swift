//
//  ThreeDFileViewController.swift
//  CameraOpus
//
//  Created by Abheek Basu on 6/14/19.
//  Copyright © 2019 CameraOpus. All rights reserved.
//


/* To Do

 developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/UsingSegues.html

 - Add example tableViewCell when running the app - done
 - Add ability to go back to places with tab without losing state - done
 
 - When segue to new cell add
 - On tap of example cell open scnview with correct file
 
 */

import UIKit


class ThreeDFileViewController : UIViewController, UITableViewDelegate, UITableViewDataSource  {

    var initial = true
    
    //number of cells
    var modelNames:  [String] = ["modelFour","modelFive", "woodenchair", "chairtm", "h3",  "h_mesh", "floral_clean", "sofatest"]
    
    let defaults = UserDefaults.standard
    
    /*
     These two variables exist so that we can add the functionality to change model names etc inline with each cell in the tableview, rather than having to tap in first. We will add this functionality down the line
     
        (otherwise we could do all the data passing in the cellForRowAt indexPath function )
    */
    var selectedModel : String?
    var modelpressed = false
    
    var fileURLs: [URL] = []
    
    var isUpdated = false

    
    @IBOutlet weak var tableView: UITableView!
    
    
    static func storyboardInstance() -> ThreeDFileViewController? {
        let storyboard = UIStoryboard(name: "ThreeDFileViewController", bundle: nil)
        return storyboard.instantiateInitialViewController() as? ThreeDFileViewController
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("numberofrows")
        print("the number of models", modelNames.count)
        return modelNames.count // your number of cells here
    }
    /*
     * Asks the data source for a cell to insert in a particular location of the table view.
     *
     * You can treat this function as something that is called when the tableview is loaded. It is essentially called in loop for each cell we need to show when we navigate to this tab
     *
     * So in this case we are simply loading the appropriate text for each cell
    */
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("cellforrowat")
        let cell = tableView.dequeueReusableCell(withIdentifier: "ModelTableViewCell", for: indexPath) as! ModelTableViewCell
        //selectedModel =
        //modelpressed = true
        cell.cellLabel.text = modelNames[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You selected cell number: \(indexPath.row)!")
        modelpressed = true
        selectedModel = modelNames[indexPath.row]
        //self.performSegueWithIdentifier("yourIdentifier", sender: self)
    }
    
    /*
     * This function is called when a button on the tableviewcell is pressed
     * We set the fileName in the sceneViewController so that it can load the right model
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("we iz preparing for segue")
        
        if(modelpressed){
            print("in mod pressed")
            let destinationVC = segue.destination as! sceneViewController
            destinationVC.modelName = selectedModel!
            shouldPerformSegue(withIdentifier: "showModel", sender: self)
        }
    }
    
    func loadFiles(){
        
        print("in loadFiles three file")
        
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        var newDestinationUrl = documentsUrl.appendingPathComponent("model")
        
        do {
            // Get the directory contents urls (including subfolders urls)
//            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)
//            print("directory contents are", directoryContents)
            
            
//            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)

            
            let subDirs = newDestinationUrl.subDirectories
            print("the path is",newDestinationUrl.path)
            for x in subDirs{
                if (x.isDirectory){
                    print("subdirectory is ", x.path)
                    let directoryContents = try FileManager.default.contentsOfDirectory(at: x, includingPropertiesForKeys: nil)
                    print("directory contents are", directoryContents)
                    
                    if !(modelNames.contains(x.lastPathComponent)){
                        modelNames.append(x.lastPathComponent)
                        isUpdated = true
                        print("just added", x.lastPathComponent)
                    }
                    
                    /*
                     * the stuff below is for debugging
                     */
                    

//                    // if you want to filter the directory contents you can do like this:
//                    let objFiles = directoryContents.filter{ $0.pathExtension == "obj" }
//                    print("obj urls:",objFiles)
//                    let objFileNames = objFiles.map{ $0.deletingPathExtension().lastPathComponent }
//                    print("obj list:", objFileNames)
//
//                    let materialFiles = directoryContents.filter{
//                        $0.path.contains("png")
//                    }
//                    print("material files are", materialFiles)
//
//
                    //we add all the files that are not in the datasource to the datasource
                    
                }
                
            }
            
//            try? FileManager.default.removeItem(at: URL(string: "/private/var/mobile/Containers/Data/Application/E0FF7CA2-9D98-45F4-ACB6-FB1ED54D9454/Documents/model/F7CFE07B-1B1D-4023-95E8-27935201FE09.obj")!)
//
            
            //let newPath = directoryContents[0].path + ".obj"
            
            /*
             * we are renaming the file
             * we can get rid of this later
             */
            
//            if(objFileNames.count == 0){
//                //url.setResourceValue(newName, forKey: NSURLNameKey)
//                print("tryna rename")
//
//                //URL(fileURLWithPath: "/Users/xxx/Desktop/Media/")
//
//                try FileManager.default.moveItem(at:                  URL(fileURLWithPath: directoryContents[0].path), to: URL(fileURLWithPath: newPath))
//                let newContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)
//                print("new contents are", newContents)
//            }
            
        } catch {
            print(error)
        }
    }
    
    override func viewDidLoad() {
        print("viewdidload 3D")
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        /*
         * we might want to change loadFiles to return a bool
         * if we did then we want to refresh to the table view to contain the cells
         */
        loadFiles()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("view appear 3d")
        
        //self.tabBarController?.delegate = self
    }
    
    func keyExists(key: String) -> Bool {
        return defaults.array(forKey: key) != nil
    }
    
    /*
     * check to see if any new models have been created since the last time this screen was shown. If so we need to create a new cell
     */
    
    func refreshCells(userModels: [String]){
        print("in refreshCells")
        //boolean tracks if there is atleast one new model to add
        
        for userModel in userModels {
            //if the current cells do not contain a model create that cell
            if !(modelNames.contains(userModel)){
                modelNames.append(userModel)
                print("we should update models")
                isUpdated = true
            }
            
        }
        //there is a new model so we insert the cells
        if (isUpdated) {
            tableView.beginUpdates()
            tableView.insertRows(at: [IndexPath(row: modelNames.count-1, section: 0)], with: .automatic)
            tableView.endUpdates()
            isUpdated = false
        }
        
        //check if there are newModelNames

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("3d view will appear")
        loadFiles()
        refreshCells(userModels: modelNames)
        //not sure if this is needed after we changed the fileManager to include a models folder
//        if (keyExists(key: "userModelNames")){
//            print("found defaults")
//            var modelArray = defaults.array(forKey: "userModelNames") as! [String]
//            refreshCells(userModels: modelArray)
//        }
        
    }
    
}

extension URL {
    var isDirectory: Bool {
        if self.path.contains(".obj"){
            return false
        }
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    var subDirectories: [URL] {
        guard isDirectory else { return [] }
        return (try? FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter{ $0.isDirectory }) ?? []
    }
}
