//
//  ViewController.swift
//  CameraOpus
//
//  Created by Abheek Basu on 4/28/19.
//  Copyright © 2019 CameraOpus. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties
    @IBOutlet weak var textLabel: UILabel!
    
    @IBOutlet weak var textInput: UITextField!
    
    //@IBOutlet weak var previewView: PreviewView!
    
    @IBOutlet weak var photoPreviewImageView: UIImageView!
    
    @IBAction func takePhoto(_ sender: UIButton) {
    }
    
    
    
    
    @IBOutlet weak var v: UIView!
    //private let session = AVCaptureSession()


    var error: NSError?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textInput.delegate = self
        var session = AVCaptureSession()
        var stillImageOutput: AVCapturePhotoOutput?
        var videoPreviewLayer: AVCaptureVideoPreviewLayer?
        
        do{
            guard let backCamera =  try AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) else { print("Default video device is unavailable."); return }
            let DeviceInput = try AVCaptureDeviceInput(device: backCamera)
            if session.canAddInput(DeviceInput) {
                session.addInput(DeviceInput)
                //self.videoDeviceInput = DeviceInput
            //photoOutput = AVCapturePhotoOutput()
            //if session.canAddOutput(photoOutput) {
              //  session.addOutput(photoOutput)
            
            //}
            }
        }
        catch{
            return
        }
    
    }
    
    
    
    func viewWillAppear(){
        //captureSession = AVCaptureSession()
        //captureSession!.sessionPreset = AVCaptureSession.Preset.photo
    }
        
        // Do any additional setup after loading the view.
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textLabel.text = textField.text
    }
    
    //MARK: Actions
    @IBAction func setDefaultLabelText(_ sender: UIButton) {
        textLabel.text = "Default text"
    }

}

