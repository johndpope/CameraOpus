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

class ThreeDFileViewController : UIViewController, UITabBarDelegate, UITableViewDelegate, UITableViewDataSource {

    var initial = true
    
    //number of cells
    var modelNames:  [String] = ["modelOne"]
    
    let defaults = UserDefaults.standard
    
    /*
     These two variables exist so that we can add the functionality to change model names etc inline with each cell in the tableview, rather than having to tap in first. We will add this functionality down the line
     
        (otherwise we could do all the data passing in the cellForRowAt indexPath function )
    */
    var selectedModel : String?
    var modelpressed = false
    
    
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("cellforrowat")
        let cell = tableView.dequeueReusableCell(withIdentifier: "ModelTableViewCell", for: indexPath) as! ModelTableViewCell
        selectedModel = modelNames[indexPath.row]
        modelpressed = true
        cell.cellLabel.text = selectedModel
        
        return cell
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
    
    override func viewDidLoad() {
        print("viewdidload 3D")
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
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
        var isUpdated = false
        for userModel in userModels {
            //if the current cells do not contain a model create that cell
            if !(modelNames.contains(userModel)){
                modelNames.append(userModel)
                isUpdated = true
            }
            
        }
        //there is a new model so we insert the cells
        if (isUpdated) {
            tableView.beginUpdates()
            tableView.insertRows(at: [IndexPath(row: modelNames.count-1, section: 0)], with: .automatic)
            tableView.endUpdates()
        }
        
        //check if there are newModelNames

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("3d view will appear")
        if (keyExists(key: "userModelNames")){
            print("found defaults")
            var modelArray = defaults.array(forKey: "userModelNames") as! [String]
            refreshCells(userModels: modelArray)
        }
        
    }
    
}
