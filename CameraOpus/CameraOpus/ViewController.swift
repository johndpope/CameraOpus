//
//  ViewController.swift
//  CameraOpus
//
//  Created by Abheek Basu on 4/28/19.
//  Copyright © 2019 CameraOpus. All rights reserved.
//

import UIKit
import AVFoundation
import Photos


class ViewController: UIViewController, UITextFieldDelegate, AVCaptureFileOutputRecordingDelegate {
    
    var session = AVCaptureSession()
    var photoOutput: AVCapturePhotoOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    var error: NSError?
    
    //MARK: Properties
    @IBOutlet weak var textLabel: UILabel!
    
    @IBOutlet weak var textInput: UITextField!
    
    @IBOutlet weak var previewView: PreviewView!
    
    @IBOutlet weak var photoPreviewImageView: UIImageView!
    
    
    // stackoverflow.com/questions/37869963/how-to-use-avcapturephotooutput
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        print("in file Output")
        let imageData = outputFileURL.dataRepresentation
        print(imageData)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("in file output 2")
    }

    
    /// - Tag: CapturePhoto
 

    @IBAction func capturePhoto(_ sender: UIButton) {
        
            do{
                print("in capturePhoto")
                let videoPreviewLayerOrientation = try videoPreviewLayer?.connection?.videoOrientation
                if let photoOutputConnection = photoOutput!.connection(with: .video) {
                    photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
                }
                var photoSettings = AVCapturePhotoSettings()
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                // Capture HEIF photos when supported. Enable auto-flash and high-resolution photos.
//                if  photoOutput!.availablePhotoCodecTypes.contains(.hevc) {
//                    print("photosettings set up")
//                    photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
//                }
//
                print("about to set up delegate")
                let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings, willCapturePhotoAnimation: {
                    // Flash the screen to signal that AVCam took a photo.
                    //we seem to not be getting here
                    print("in delegate creation")
                    
                        self.previewView.videoPreviewLayer.opacity = 0
                        UIView.animate(withDuration: 0.25) {
                            self.previewView.videoPreviewLayer.opacity = 1
                        }
                    
                }, completionHandler: { _ in
                    // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                    /*
                     will better need to understand this part - hopefully im not destrioying my phone
                     */
                    //photoCaptureProcessor.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                }
                )
                print("delegate should have been created")
                /*
                 This is the main function that is saving the phto
                */
                photoOutput!.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
                print("capturePhoto should have been called")
                //photoOutput(_:didFinishProcessingPhoto:error:)
            }
            catch{
                print("something wrong with capture")
            }
        }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textInput.delegate = self
        do{
            //We are trying to set the input device to the session ie the back camera
            guard let backCamera =  try AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) else { print("Default video device is unavailable."); return }
            let DeviceInput = try AVCaptureDeviceInput(device: backCamera)
            if session.canAddInput(DeviceInput) {
                session.addInput(DeviceInput)
                print("was able to add deviceinput")
                //Now that we set input device lets set output files
                photoOutput = AVCapturePhotoOutput()
                if session.canAddOutput(photoOutput!) {
                    session.addOutput(photoOutput!)
                    print("was able to set deviceoutput")
                    //Now we try to connect the preview layer which will eventually be the element in the IB to what the camera sees
                    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
                    videoPreviewLayer!.videoGravity =    AVLayerVideoGravity.resizeAspect
                    videoPreviewLayer!.connection?.videoOrientation =   AVCaptureVideoOrientation.portrait
                    photoPreviewImageView.layer.addSublayer(videoPreviewLayer!)
                    print("seems like we have added a subLayer")
                    session.startRunning()
                    print("session is running?")
                }
            }
        }
        catch{
            print("there must have been an error in vievDidLoad")
            return
        }
    }
    
    func viewWillAppear(){
        //captureSession = AVCaptureSession()
        //captureSession!.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoPreviewLayer!.frame = previewView.bounds
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

