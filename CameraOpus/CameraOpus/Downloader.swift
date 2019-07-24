//
//  Downloader.swift
//  CameraOpus
//
//  Created by Abheek Basu on 7/10/19.
//  Copyright © 2019 CameraOpus. All rights reserved.
//

import Foundation
import SSZipArchive

class Downloader : NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    
    static var shared = Downloader()
    
    var url : URL?
    
    //var destinationUrl: string?
    
    typealias ProgressHandler = (Float) -> ()
    
    var onProgress : ProgressHandler? {
        didSet {
            if onProgress != nil {
                let _ = activate()
            }
        }
    }
    
    override private init() {
        super.init()
    }
    
    func activate() -> URLSession {
        let config = URLSessionConfiguration.background(withIdentifier: "cameraOpusDownloader")
        
        // Warning: If an URLSession still exists from a previous download, it doesn't create a new URLSession object but returns the existing one with the old delegate object attached!
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }
    
    private func calculateProgress(session : URLSession, completionHandler : @escaping (Float) -> ()) {
        session.getTasksWithCompletionHandler { (tasks, uploads, downloads) in
            let progress = downloads.map({ (task) -> Float in
                if task.countOfBytesExpectedToReceive > 0 {
                    return Float(task.countOfBytesReceived) / Float(task.countOfBytesExpectedToReceive)
                } else {
                    return 0.0
                }
            })
            completionHandler(progress.reduce(0.0, +))
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        if totalBytesExpectedToWrite > 0 {
            if let onProgress = onProgress {
                calculateProgress(session: session, completionHandler: onProgress)
            }
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            debugPrint("Progress \(downloadTask) \(progress)")
            
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        debugPrint("Download finished: \(location)")
        
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        //if(url.path.contains("texture")){
            //destinationUrl = documentsUrl!.appendingPathComponent
        //}
        var destinationUrl = documentsUrl!.appendingPathComponent(url!.lastPathComponent)
        
        print("the destination ur' is", destinationUrl)
        /*
         * We are prolly gonna use
         *
         * SSZipArchive.unzipFileAtPath(zipPath, toDestination: unzipPath)
         */
        
//        if(url!.path.contains("texture")){
//            print("we have a texture")
//            destinationUrl = destinationUrl.appendingPathExtension("png")//".png"
//        }
//        if(url!.path.contains("mesh")){
//            print("we have a mesh")
//            destinationUrl = destinationUrl.appendingPathExtension("obj")
//        }
        
        let dataFromURL = try? Data(contentsOf: location)
        try? dataFromURL?.write(to: destinationUrl, options: [.atomic])
        var newDestinationUrl = documentsUrl!.appendingPathComponent("model")
        newDestinationUrl = newDestinationUrl.appendingPathComponent(url!.lastPathComponent)
        print("new destination is", newDestinationUrl.path)
        
        /*
         add proper try catch here
         what happens if catch is not unzipped?
        */
        
        print("we are trying to unzip")
        try? SSZipArchive.unzipFile(atPath: destinationUrl.path, toDestination: newDestinationUrl.path)
        print("unzipped")
        
        //uncomment for more visibility into what is happening
        //let directoryContents = try? FileManager.default.contentsOfDirectory(at: newDestinationUrl, includingPropertiesForKeys: nil)
        //print("unzipped contents are", directoryContents)
        
        
        try? FileManager.default.removeItem(at: location)
        print("about to end session")
        session.invalidateAndCancel()
        
        //invalidateAndCancel()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        debugPrint("Task completed: \(task), error: \(error)")
    }
    
    func download(_ url: URL)
    {
        print("in downloader download")
        self.url = url
        
        //download identifier can be customized. I used the "ulr.absoluteString"
        let task = Downloader.shared.activate().downloadTask(with: url)
        task.resume()
    }

}
