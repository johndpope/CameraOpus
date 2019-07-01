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
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        //vcCount += 1
//        //navigationItem.title = "back"
//
//        if segue.identifier == "pizza"{
//            navigationItem.title = "Pizza to One"
//        }
//        if segue.identifier == "pasta"{
//            navigationItem.title = "Pasta to One"
//        }
//    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("cellforrowat")
        let cell = tableView.dequeueReusableCell(withIdentifier: "ModelTableViewCell", for: indexPath) as! ModelTableViewCell
        selectedModel = modelNames[indexPath.row]
        modelpressed = true
        cell.cellLabel.text = selectedModel
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("we iz preparing for segue")
        /*
         this is currently giving us problems
        */
//        if(modelpressed){
//            let destinationVC = sceneViewController()
//            destinationVC.modelName = selectedModel!
//            destinationVC.performSegue(withIdentifier: "showModel", sender: self)
//        }
    }
    
    override func viewDidLoad() {
        print("viewdidload 3D")
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
}
