//
//  FolderHelper.swift
//  CameraOpus
//
//  Created by Abheek Basu on 7/11/19.
//  Copyright © 2019 CameraOpus. All rights reserved.
//

import Foundation


class FolderHelper {
    
    func moveModel(){
        
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory: AnyObject = paths[0] as AnyObject
        let dataPath = documentsDirectory.appendingPathComponent("MyFolder")!
        
        do {
            try FileManager.default.createDirectory(atPath: dataPath.absoluteString, withIntermediateDirectories: false, attributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription);
        }
        
        
    }

    
}
