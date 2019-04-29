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
    
    @IBOutlet weak var imview: UIImageView!
    
    @IBOutlet weak var v: UIView!

    @IBAction func takePhoto(_ sender: UIButton) {
    }
    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var error: NSError?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textInput.delegate = self
    }
    
    func viewWillAppear(){
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSession.Preset.photo
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

