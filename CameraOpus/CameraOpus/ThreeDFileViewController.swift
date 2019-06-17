//
//  ThreeDFileViewController.swift
//  CameraOpus
//
//  Created by Abheek Basu on 6/14/19.
//  Copyright © 2019 CameraOpus. All rights reserved.
//


/* To Do

 developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/UsingSegues.html

 - Add example tableViewCell when running the app
 - On tap of example cell open scnview with correct file
 
 */

import UIKit

class ThreeDFileViewController : UIViewController, UITabBarDelegate, UITableViewDelegate, UITableViewDataSource {

    
    var initial = true
    
    @IBOutlet weak var tableView: UITableView!
    
    
    static func storyboardInstance() -> ThreeDFileViewController? {
        let storyboard = UIStoryboard(name: "ThreeDFileViewController", bundle: nil)
        return storyboard.instantiateInitialViewController() as? ThreeDFileViewController
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3 // your number of cells here
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ModelTableViewCell", for: indexPath)
        //cell.textLabel?.text = ["Manny", "Moe", "Jack"][indexPath.row]
        //let cell = UITableViewCell()
        
        return cell
    }
    
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        // cell selected code here
//    }
    
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        print("in tabBar")
        
        if(item.tag == 0) {
            print("we are pressing tab 0")
            
            //let storyboard = UIStoryboard(name: "ThreeDFileViewController", bundle: nil)
            //let nextVc = storyboard.instantiateViewController(withIdentifier: "ThreeDFileViewController") as! ThreeDFileViewController
            //let navigationVc = UINavigationController(rootViewController: nextVc)
            //present(navigationVc, animated: false, completion: nil)
            
        }
        else if(item.tag == 1) {
            print("we are pressing tab 1")
            //your code for tab item 2
        }
        else if(item.tag == 2)
        {
            print("we are pressing tab 2")
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        
        do{
            //tableView.dequeueReusableCell(withIdentifier: "ModelTableViewCell", for: 0)
//            tableView.beginUpdates()
//            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
//            tableView.endUpdates()
            //tableView.register()
        }
        catch{
            print("error in 3d viewer controller")
        }
        
    }
    
    
    
    
    
}
