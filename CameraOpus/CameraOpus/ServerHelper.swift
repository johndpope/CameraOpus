//
//  ServerHelper.swift
//  CameraOpus
//
//  Created by Abheek Basu on 7/10/19.
//  Copyright © 2019 CameraOpus. All rights reserved.
//

import Foundation

class ServerHelper{
  

    static func downLoadModel(modelkey: String){
        
        print("in download model")
        
        let serverAddress = "http://3.82.80.228/"
        
        let testing = true
        if(testing){
            let parameters: [String: Any] = [
                "modelid": modelkey
            ]
            
            var r  = URLRequest(url: URL(string: serverAddress + "retrieve/")!)
            
            r.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            r.httpMethod = "POST"
            r.httpBody = parameters.percentEscaped().data(using: .utf8)
            
            let task = URLSession.shared.dataTask(with: r) { data, response, error in
                guard let data = data,
                    let response = response as? HTTPURLResponse,
                    error == nil else {
                        return
                }
                
                guard (200 ... 299) ~= response.statusCode else {
                    return
                }
                
                let responseString = String(data: data, encoding: .utf8)
                print("responseString = \(responseString)")
            }
            task.resume()
        }
        
    }
    
//    private lazy var urlSession: URLSession = {
//        let config = URLSessionConfiguration.background(withIdentifier: "modelDownloader")
//        config.isDiscretionary = true
//        config.sessionSendsLaunchEvents = true
//        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
//    }()
//
    static func downloadModel(address: String){
        let url = URL(string: address)!
        let task = Downloader.shared.activate().downloadTask(with: url)
        task.resume()
        
    }
}

extension Dictionary {
    func percentEscaped() -> String {
        return map { (key, value) in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
            }
            .joined(separator: "&")
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

