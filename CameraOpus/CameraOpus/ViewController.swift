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
import CoreMotion

import CoreLocation


/*
 General Info learnt
 
 **************************
 
 PHOTO:
 
 (back camera)
 depthdatamap width is 768
 depthdatamap height is 576
 
 avcapturphotooutput width is 4032
 avcapturphotooutput height is 3024
 
 **************************
 
 **************************
 
 VIDEO:
 
 (back camera)
 depthdatamap width is  320
 depthdatamap height is 240
 
 avvideoframe width is 1504 (cgImage.width)
 avvideoframe height is 1128 (cgImage.height)
 
 (true depth)
 the depthmap width is  640
 the depthmap height is  480
 
 **************************
 
 AR:
 
 arkitcapture is about 2megapixels
 
 keep in mind cgpoint y seems to correspond to pixel width
 it seems to be the origin of cgimage is top right, not top left
 while the origin of cgpoint is top right
 
 ACCEL
 
 when the phone is still im seeing residual numbers
 
 # 1 (lying on sofa)
 from accel
 teh x accel is  -0.109619140625
 teh y accel is  -0.2089385986328125
 teh z accel is  -0.9712066650390625
 
 # 2 (lying on table face up)
 
 from accel
 teh x accel is  0.00457763671875
 teh y accel is  -0.0081787109375
 teh z accel is  -0.997161865234375
 
 on this iphone xs it seems like we could round to nearest 0.1?
 
 */

/*
 
 strategy
 - create a frame in the image about 2/3 of the photo layer, inbetween which we ask user to position object
 - ask user to tap center of object (this gives us the distance) and allows us to calculate a radius for how much translation and how many images we want
 - As user moves around we show a progress bar
 - get depth reading from tap in image
 
 ideas
 - we could start an ar scene with arkit and save information about the enviroment
 - then once a user touches the object we turn off the ar scene and go back to avcapture
 - then once the image taking process has started, we systematically switch to arkit to check how much distance has been traversed
 
 log of todo now
 - write function that makes log of acelerometer data
 - having some issue with OperationQueue.main.addOperation not getting in there
 - get depth value in human readable format
 - rewrite pixel rectification with cvpixel buffers, and check against the cgimage implementation (this is needed because the co-ordinate system of cgimage seems to be different to cg point)
 - consider rewriting visualizePoint function with cvpixel buffers instead (so we can avoid co-ordinate system troubles)
 
 */

/*
 Flags
 
 - right now devMotionFlag is on and devEffectFlag is off (both cannot be on at the same time becuase they both attempt to turn on the accelerometer)
 - additionally motionInterval must have some reasonable value
 
 **NB**
 - we use setDefaultLabelText as a user input way of resetting flags for testing purposes
 
 */

/*
 log of nice to haves
 - timstamps of image taking
 -
 
 */

/*
 CURRENT STACK
 
 - completing depth rectification function - done
 - the get depth point will have the same logic as the depth rectifiication function, but will only 'rectify' a points worth of data - done?
 - working on depth segmentiontation algo next
 
 - How do we determine the optimal distance from which to take photo?
 - We will need to guess size of image
    - to do that we will use some depth segmentation algo
 - Is there some mathemtics we can do based on the object prelim size guess?
 
 
 - right now when you touch the video previewLayer, you save 3 photos
 - the flow is capturePhoto is called with the capture3 flag. One image is automatically saved here, then visualizeImage is called, and one image is saved there, then createDepthMap is called saving another image
 - The text label isnt updating because of some silly issue
 
 
 Resources:
 - git.kabellmunk.dk/talks/into-the-deep/blob/master/IntoTheDeep/Models/Slides.swift
 
 
 - github.com/ejeinc/MetalScope
 
 */


class ViewController: UIViewController, UITextFieldDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureDataOutputSynchronizerDelegate, CLLocationManagerDelegate {
    
    var count = 1
    
    var session = AVCaptureSession()
    var photoOutput: AVCapturePhotoOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    //var layer: CALayer?
    var layer: UIView?
    
    
    var videoDataOutput = AVCaptureVideoDataOutput()
    var videoFlag = 0
    private let depthDataOutput = AVCaptureDepthDataOutput()
    private var outputSynchronizer: AVCaptureDataOutputSynchronizer?
    
    var error: NSError?
    
    var depthDataMap: CVPixelBuffer?
    var depthData: AVDepthData?
    var motionManager: CMMotionManager?
    var accelFlag = 0
    var gyroFlag = 0
    var devMotionFlag = 0
    var firstShotTaken = false
    var currentTouch: CGPoint?
    var updateDepthLabel = false
    
    var capturePhotoFlag1 = true
    var capturePhotoFlag2 = false
    var capturePhotoFlag3 = false
    
    //flag to add the focus box
    var focusFlag = true
    
    /*
     Animation variables
    */
    
    //this is the rotation animation
    var tempView: UIImageView?
    //var arrow = SKSpriteNode()
    
    //this is the panorama arrow
    var arrowView: UIImageView?
    let motionInterval = 0.3
    
    //location and magentometer
    let locationManager = CLLocationManager()

    
    //temp variables
    var accelcount = 0
    var devCount = 0
    var compassCount = 0
    
    //MARK: Properties
    @IBOutlet weak var textLabel: UILabel!
    
    @IBOutlet weak var textInput: UITextField!
    
    //@IBOutlet weak var previewView: PreviewView!
    
    @IBOutlet weak var photoPreviewImageView: UIImageView!
    
    //var outputSynchronizer: AVCaptureDataOutputSynchronizer?
    
    private let dataOutputQueue = DispatchQueue(label: "video data queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    // stackoverflow.com/questions/37869963/how-to-use-avcapturephotooutput
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        print("in file Output")
        let imageData = outputFileURL.dataRepresentation
        print(imageData)
        
        if error != nil {
            print("Movie file finishing error")
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("in file output 2")
    }
    //TOGGLE
    
    /*
     accelerometer handler function
    */
    func outputAccelData(acceleration: CMAcceleration){
        print("from accel")
        if (accelcount < 5){
            print("teh x accel is ", acceleration.x)
            print("teh y accel is ", acceleration.y)
            print("teh z accel is ", acceleration.z)
            print(" ")
            accelcount = accelcount + 1
        }
    }


    func outputDevMotionData(data: CMDeviceMotion){
        print("from output dev motion")
        let gravity = data.gravity
        let xa = data.userAcceleration.x
        let ya = data.userAcceleration.y
        let za = data.userAcceleration.z
        
        if (devCount < 5){
            print("teh x accel is ", xa)
            print("teh y accel is ", ya)
            print("teh z accel is ", za)
            print(" ")
            devCount = devCount + 1
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        if(compassCount < 5){
            print("the compass")
            print (heading.magneticHeading)
            compassCount = compassCount + 1
        }
        
    }

    
    /// - Tag: CapturePhoto
    override func viewDidLoad() {
        super.viewDidLoad()
        textInput.delegate = self
        do{
            /*
             this preset line is needed for depth for some reason
             */
            session.sessionPreset = .photo
            //We are trying to set the input device to the session ie the back camera
            guard let backCamera =  try AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) else { print("Default video device is unavailable."); return }
            let DeviceInput = try AVCaptureDeviceInput(device: backCamera)
            if session.canAddInput(DeviceInput) {
                session.addInput(DeviceInput)
                print("was able to add deviceinput")
                // that we set input device lets set output files
                photoOutput = AVCapturePhotoOutput()
                if session.canAddOutput(videoDataOutput){
                    videoFlag = 1
                    print("***")
                    print("we can add video")
                }
                if (session.canAddOutput(photoOutput!) && (videoFlag == 1)) {
                    session.addOutput(photoOutput!)
                    print("was able to set photooutput")
                    if photoOutput!.isDepthDataDeliverySupported {
                        print("we can add depth")
                        session.addOutput(depthDataOutput)
                        photoOutput!.isDepthDataDeliveryEnabled = true
                    }
                    else{
                        print("for some reason we can't add depth")
                    }
                    session.addOutput(videoDataOutput)
                    print("was able to set videooutput")
                    
                    
                    /*
                        Set up accelerometer and gyroscope
                     */
                    
                    motionManager = CMMotionManager()
                    
                    if (motionManager!.isGyroAvailable){
                        print("we have access to the gyro")
                        gyroFlag = 1
                    }
                    if(motionManager!.isAccelerometerAvailable){
                        print("we have access to the accel")
                        accelFlag = 1
                    }
                    if(motionManager!.isDeviceMotionAvailable){
                        devMotionFlag = 1
                    }
                    
                    //TOGGLE
                    
                    accelFlag = 0
                    // we start running the accel right away but not the gyro
                    if((accelFlag == 1)){
                        
                         motionManager?.accelerometerUpdateInterval = 0.3

                        motionManager!.startAccelerometerUpdates(
                            to: OperationQueue.current!,
                            withHandler: {(accelData: CMAccelerometerData?, errorOC: Error?) in
                                self.outputAccelData(acceleration: accelData!.acceleration)
                        })
                        print("running accelerometer")
                        print("**")
                        
                    }
                    
                    if(devMotionFlag == 1){
                        print("dev flag is on")
                        
                        motionManager?.deviceMotionUpdateInterval = motionInterval
                        motionManager!.startDeviceMotionUpdates(
                            to: OperationQueue.current!,
                            withHandler: {(data, error) in
                                self.outputDevMotionData(data: data!)
                        
                        //UUUU
                        })
                    }
                    
                    /*
                     setting up location stuff
                     the internal compass
                     */
                    if (CLLocationManager.headingAvailable()) {
                        locationManager.headingFilter = 1
                        locationManager.startUpdatingHeading()
                        locationManager.delegate = self
                    }
                    
                    //photoOutput!.isDepthDataDeliveryEnabled = true
                    // we try to connect the preview layer which will eventually be the element in the IB to what the camera sees
                    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
                    videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspect
                    videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                    
                    
                    //outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [videoDataOutput, depthDataOutput])
                    
                    
                    photoPreviewImageView.layer.addSublayer(videoPreviewLayer!)
                    print("seems like we have added a subLayer")
                    
                    if(focusFlag){
                        print("in focus")
                        //layer = CALayer()
                        layer = UIView()
                        //layer?.addSubview(<#T##view: UIView##UIView#>)
                        var im = UIImage(named: "focus")//?.cgImage
                        //print("image height is ", im?.height)
                        //print("image width is ", im?.width)
                        
                        let imageView = UIImageView(image: im!)
                        imageView.frame = CGRect(x: 62.5, y: 84, width: 250, height: 333)
                        photoPreviewImageView.addSubview(imageView)
                        
                        //layer!.contents = UIImage(named: "focus")//?.cgImage
                        //sphotoPreviewImageView.layer.addSublayer(layer!)
                    }
                    /*
                     *
                     Configuring the depthdata here
                     *
                     */
                    let pressGestureDepth = UILongPressGestureRecognizer(target: self, action: #selector(getDepthTouch) )
                    pressGestureDepth.minimumPressDuration = 1.00
                    //pressGestureDepth.cancelsTouchesInView = false
                    print("about to add gesture recog")
                    photoPreviewImageView.isUserInteractionEnabled = true
                    photoPreviewImageView.addGestureRecognizer(pressGestureDepth)
                    print("added gesture recog")
                    
                    
                    //session.commitConfiguration()
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
    
    func outputGyroData(gyroMeasure: CMRotationRate){
        //gyroMeasure
        print("teh xaxis is ", gyroMeasure.x)
        print("teh yaxis is ", gyroMeasure.y)
        print("teh zaxis is ", gyroMeasure.z)
        print(" ")
        
    }

    @IBAction func capturePhoto(_ sender: UIButton) {
        
            do{
                print("in capturePhoto")
                
                if(gyroFlag == 1){
                    motionManager?.gyroUpdateInterval = 10.0
                    motionManager!.startGyroUpdates(
                        to: OperationQueue.current!,
                        withHandler: {(gyroData: CMGyroData?, errorOC: Error?) in
                            self.outputGyroData(gyroMeasure: gyroData!.rotationRate)
                    })
                    print("running gyro")
                }
                
                let videoPreviewLayerOrientation = try videoPreviewLayer?.connection?.videoOrientation
                if let photoOutputConnection = photoOutput!.connection(with: .video) {
                    photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
                }
                var photoSettings = AVCapturePhotoSettings()
                //photoSettings.isDepthDataDeliveryEnabled = true
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                //JUST ADDED
                photoSettings.isDepthDataDeliveryEnabled =
                    photoOutput!.isDepthDataDeliverySupported

                print("about to set up delegate")

                print("delegate should have been created")
                photoOutput!.capturePhoto(with: photoSettings, delegate: self)
                
                print("capturePhoto should have been called")
                
                /*
                 We will need to stop the accelerometer at some point in the future
                 Ideally we should have some function that is called when the app is closed or stops being used
                 How we decide to stop
                 */
//                if(accelFlag == 1){
//                    motionManager!.stopAccelerometerUpdates()
//                    print("stopping accelerometer")
//                }
                
                if(gyroFlag == 1){
                    //motionManager!.stopGyroUpdates()
                    print("stopping gyro")
                }
                
            }
            catch{
                print("something wrong with capture")
            }
        }
    
    func viewWillAppear(){
        //captureSession = AVCaptureSession()
        //captureSession!.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoPreviewLayer!.frame = photoPreviewImageView.bounds
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
        accelcount = 0
        devCount = 0
        compassCount = 0
    }
    /*
     To create a rectilinear image we must begin with an empty destination buffer and iterate through it
     row by row, calling the sample implementation below for each point in the output image, passing the
     lensDistortionLookupTable to find the corresponding value in the distorted image, and write it to your
     output buffer.
     
     ie we know that the lensDistortionLookupTable is correct,
     */
    
    /*
     further testing is required to find the bounds of this function. Can the output be negative, if so why?
     we should also consider approaches beyond linear interpolation
     */
    
    func lensDistortionPoint(point: CGPoint, lookupTable: Data, distortionOpticalCenter opticalCenter: CGPoint, imageSize: CGSize) -> CGPoint {
        // The lookup table holds the relative radial magnification for n linearly spaced radii.
        // The first position corresponds to radius = 0
        // The last position corresponds to the largest radius found in the image.
        
        // Determine the maximum radius.
        let delta_ocx_max = Float(max(opticalCenter.x, imageSize.width  - opticalCenter.x))
        let delta_ocy_max = Float(max(opticalCenter.y, imageSize.height - opticalCenter.y))
        let r_max = sqrt(delta_ocx_max * delta_ocx_max + delta_ocy_max * delta_ocy_max)
        
        // Determine the vector from the optical center to the given point.
        let v_point_x = Float(point.x - opticalCenter.x)
        let v_point_y = Float(point.y - opticalCenter.y)
        
        // Determine the radius of the given point.
        let r_point = sqrt(v_point_x * v_point_x + v_point_y * v_point_y)
        
        // Look up the relative radial magnification to apply in the provided lookup table
        let magnification: Float = lookupTable.withUnsafeBytes { (lookupTableValues: UnsafePointer<Float>) in
            let lookupTableCount = lookupTable.count / MemoryLayout<Float>.size
            
            if r_point < r_max {
                // Linear interpolation
                let val   = r_point * Float(lookupTableCount - 1) / r_max
                let idx   = Int(val)
                let frac  = val - Float(idx)
                
                let mag_1 = lookupTableValues[idx]
                let mag_2 = lookupTableValues[idx + 1]
                
                return (1.0 - frac) * mag_1 + frac * mag_2
            } else {
                return lookupTableValues[lookupTableCount - 1]
            }
        }
        
        // Apply radial magnification
        let new_v_point_x = v_point_x + magnification * v_point_x
        let new_v_point_y = v_point_y + magnification * v_point_y
        
        // Construct output
        return CGPoint(x: opticalCenter.x + CGFloat(new_v_point_x), y: opticalCenter.y + CGFloat(new_v_point_y))
    }
    
    private func getDepthValueAtPoint(avDepthDataT: AVDepthData, TouchPoint: CGPoint) -> Float32? {
        guard
            let distortionLookupTable = avDepthDataT.cameraCalibrationData?.lensDistortionLookupTable,
            let distortionCenter = avDepthDataT.cameraCalibrationData?.lensDistortionCenter else {
                return nil
        }
        
        print("the camera's ref dimensions are ", avDepthDataT.cameraCalibrationData?.intrinsicMatrixReferenceDimensions)
        
        var avDepthData = avDepthDataT
        
        if avDepthDataT.depthDataType != kCVPixelFormatType_DisparityFloat32 {
            avDepthData = avDepthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
        }
        
        print("distortion center was ", distortionCenter)
        
        let originalDepthDataMap = avDepthData.depthDataMap
        
        let width = CVPixelBufferGetWidth(originalDepthDataMap)
        print("depth map buffer ", width)
        let height = CVPixelBufferGetHeight(originalDepthDataMap)
        print("depth map buffer ", height)
        
        
        // We have found that the distortion center corresponds to the 12mp photo (not depth dimensions)
        // we make scale invariant.
        //let scaledCenter = CGPoint(x: (distortionCenter.x / CGFloat(image.size.height)) * CGFloat(width), y: (distortionCenter.y / CGFloat(image.size.width)) * CGFloat(height))
        var scaledCenter = distortionCenter
        
        scaledCenter.x = (distortionCenter.x / (avDepthDataT.cameraCalibrationData?.intrinsicMatrixReferenceDimensions.height)!) * CGFloat(height)
        
        scaledCenter.y = (distortionCenter.y / (avDepthDataT.cameraCalibrationData?.intrinsicMatrixReferenceDimensions.width)!) * CGFloat(width)
        
        print("distortion center becomes ", scaledCenter)
        
        CVPixelBufferLockBaseAddress(originalDepthDataMap, CVPixelBufferLockFlags(rawValue: 0))
        
        guard let address = CVPixelBufferGetBaseAddress(originalDepthDataMap) else {
            return nil
        }
        
        let distortedPoint = lensDistortionPoint(point: TouchPoint, lookupTable: distortionLookupTable, distortionOpticalCenter: scaledCenter, imageSize: CGSize(width: width, height: height) )
        //this gets us to the right row
        let distortedRow = address + Int(distortedPoint.y) * CVPixelBufferGetBytesPerRow(originalDepthDataMap)
        // is the "count: width" correct?, i'll comment out the og
        let distortedData = UnsafeBufferPointer(start: distortedRow.assumingMemoryBound(to: Float32.self), count: width)
    
        let disparity = distortedData[Int(distortedPoint.x)]
        let meters = 1/disparity
        print("distance is ", meters)
        return meters
    }
    
    /*
     For each point (x,y co-ord) (not pixel value, just co-ord ie no RGB) in the rectified image, find each correspondging x,y co-ord in the non rectified image.
     Take the depth value at the x,y co-ord and put into the right co-ord in the rectified image
     */
    
    /*
     It seems like the lens distortion center is scaled to the full 12mp image resolution. thus we need to scale it
    */
    
    private func rectifyDepthData(avDepthDataT: AVDepthData){//}, image: UIImage) {//-> CVPixelBuffer? {
        guard
            let distortionLookupTable = avDepthDataT.cameraCalibrationData?.lensDistortionLookupTable,
            let distortionCenter = avDepthDataT.cameraCalibrationData?.lensDistortionCenter else {
                return //nil
        }
        
        print("the camera's ref dimensions are ", avDepthDataT.cameraCalibrationData?.intrinsicMatrixReferenceDimensions)
        
        var avDepthData = avDepthDataT
        
        if avDepthDataT.depthDataType != kCVPixelFormatType_DisparityFloat32 {
            avDepthData = avDepthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
        }
        
        print("distortion center was ", distortionCenter)
        
        let originalDepthDataMap = avDepthData.depthDataMap
        
        
        let width = CVPixelBufferGetWidth(originalDepthDataMap)
        print("depth map buffer ", width)
        let height = CVPixelBufferGetHeight(originalDepthDataMap)
        print("depth map buffer ", height)
        
        var scaledCenter = distortionCenter
        
        scaledCenter.x = (distortionCenter.x / (avDepthDataT.cameraCalibrationData?.intrinsicMatrixReferenceDimensions.height)!) * CGFloat(height)
        
        scaledCenter.y = (distortionCenter.y / (avDepthDataT.cameraCalibrationData?.intrinsicMatrixReferenceDimensions.width)!) * CGFloat(width)
        
        print("distortion center becomes ", scaledCenter)
        
        
        // We have found that the distortion center corresponds to the 12mp photo
        // this funtion scale invariant.
        //let scaledCenter = CGPoint(x: (distortionCenter.x / CGFloat(image.size.height)) * CGFloat(width), y: (distortionCenter.y / CGFloat(image.size.width)) * CGFloat(height))
        CVPixelBufferLockBaseAddress(originalDepthDataMap, CVPixelBufferLockFlags(rawValue: 0))
        
        /*
         Creating a new pixel buffer
         */
        var maybePixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(nil, width, height, avDepthData.depthDataType, nil, &maybePixelBuffer)
        print("checking status of new pixel buffer ", status)
        
        //assert(status == kCVReturnSuccess && maybePixelBuffer != nil);
        
        guard let rectifiedPixelBuffer = maybePixelBuffer else {
            return //nil
        }
        
        CVPixelBufferLockBaseAddress(rectifiedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        guard let address = CVPixelBufferGetBaseAddress(originalDepthDataMap) else {
            return //nil
        }
        print("about to get the depthvalue")
        //This is getting the depth values and putting into the new depthmap
        for y in 0 ..< height{
            let rowData = CVPixelBufferGetBaseAddress(rectifiedPixelBuffer)! + y * CVPixelBufferGetBytesPerRow(rectifiedPixelBuffer)
            let data = UnsafeMutableBufferPointer(start: rowData.assumingMemoryBound(to: Float32.self), count: width)
            
            //
            for x in 0 ..< width{
                let rectifiedPoint = CGPoint(x: x, y: y)
                //distorted point is some cgpoint we have do not have control over
                let distortedPoint = lensDistortionPoint(point: rectifiedPoint, lookupTable: distortionLookupTable, distortionOpticalCenter: scaledCenter, imageSize: CGSize(width: width, height: height) )
                //this gets us to the right row
                let distortedRow = address + Int(distortedPoint.y) * CVPixelBufferGetBytesPerRow(originalDepthDataMap)
                // is the "count: width" correct?, i'll comment out the og
                let distortedData = UnsafeBufferPointer(start: distortedRow.assumingMemoryBound(to: Float32.self), count: width)
                //let distortedData = UnsafeBufferPointer(start: distortedRow.assumingMemoryBound(to: kCVPixelFormatType_DisparityFloat32.self), count: width)
                
                //print(distortedData)
                //getting out of bounds here so i break up into statements
                let val = distortedData[Int(distortedPoint.x)]
                data[x] = val
            }
        }
        CVPixelBufferUnlockBaseAddress(rectifiedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        CVPixelBufferUnlockBaseAddress(originalDepthDataMap, CVPixelBufferLockFlags(rawValue: 0))
        print("created rectified image")
        let cmage = CIImage(cvPixelBuffer: rectifiedPixelBuffer)
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(cmage, from: cmage.extent)!
        print("about to create UIimage from rectifyDepthData to be saved")
        let outputImage = UIImage(cgImage: cgImage, scale: 1, orientation: .right)
        
        UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil)
        //return rectifiedPixelBuffer
    }
    
    /*
     the rectification function as clarified by some sources, the only remaining ambiguity is the value for optical center
     takes ina cgimage, and saves an image with call to UIImageWriteToSavedPhotosAlbum
     */
    
    func rectifyPixelData(cgImage: CGImage, lookupTable: Data, distortionOpticalCenter opticalCenter: CGPoint, channels: Int = 4, bitsPerComp: Int = 8) {
        
        // Get image width, height
        let pixelsWide = cgImage.width
        let pixelsHigh = cgImage.height
        print("width is ", pixelsWide)
        print("height is ", pixelsHigh)
        
        let bitmapBytesPerRow = pixelsWide * channels
        let bitmapByteCount = bitmapBytesPerRow * Int(pixelsHigh)
        
        // Use the generic RGB color space.
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        print("device colour space all good")
        
        // Allocate memory for image data. This is the destination in memory
        // where any drawing to the bitmap context will be rendered.
        let bitmapData = malloc(bitmapByteCount)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        let size = CGSize(width: pixelsWide, height: pixelsHigh)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        // create bitmap
        let context = CGContext(data: bitmapData, width: pixelsWide, height: pixelsHigh, bitsPerComponent: bitsPerComp,
                                bytesPerRow: bitmapBytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        print("created first context")
        
        // draw the image onto the context
        let rect = CGRect(x: 0, y: 0, width: pixelsWide, height: pixelsHigh)
        context?.draw(cgImage, in: rect)
        print("should have written first image to buffer")
        
        let data = context!.data
        print("about to bind memory to buffer")
        let dataBuf = data!.bindMemory(to: UInt8.self, capacity: pixelsWide * pixelsHigh * 4)

        //destination buffer
        let newBitmapData = malloc(bitmapByteCount)
        //let newBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        //let newSize = CGSize(width: pixelsWide, height: pixelsHigh)
        let otherContext = CGContext(data: newBitmapData, width: pixelsWide, height: pixelsHigh, bitsPerComponent: 8,
                                     bytesPerRow: bitmapBytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        let otherRect = CGRect(x: 0, y: 0, width: pixelsWide, height: pixelsHigh)
        
        otherContext?.draw(cgImage, in: otherRect)
        
        let newData = otherContext!.data
        let newDataBuf = newData!.bindMemory(to: UInt8.self, capacity: pixelsWide * pixelsHigh * 4)
        //let pixelBuffer = buffer.bindMemory(to: RGBA32.self, capacity: pixelsWide * pixelsHigh)
        
        for row in 0 ..< Int(pixelsHigh) {
            for column in 0 ..< Int(pixelsWide) {
                var point = lensDistortionPoint(point: CGPoint(x: column, y: row), lookupTable: lookupTable, distortionOpticalCenter: opticalCenter, imageSize: CGSize(width: pixelsWide, height: pixelsHigh))
                let rectifiedPointer = 4*((Int(pixelsWide) * row + column))
                let distortedPointer = 4*((Int(pixelsWide) * Int(point.y)) + Int(point.x))
                //let offset = row * width + column
                newDataBuf[rectifiedPointer] = dataBuf[distortedPointer]
                newDataBuf[rectifiedPointer + 1] = dataBuf[distortedPointer + 1]
                newDataBuf[rectifiedPointer + 2] = dataBuf[distortedPointer + 2]
                newDataBuf[rectifiedPointer + 3] = dataBuf[distortedPointer + 3]
                //let val = data![distortedPointer]
                //newData[rectifiedPointer]
            }
        }
        
        print("about to create rectify pixel output image")
        let outputCGImage = otherContext!.makeImage()!
        //scale 1 is the same scale as CGimage, 0 orientation is up?
        print("about to create UIimage to be saved")
        let outputImage = UIImage(cgImage: outputCGImage, scale: 1, orientation: .right)
        UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil)
        
        free(data)
        free(newData)
        
        //return context!
    }
    
    func testRect(image: CGImage){
        
        print("the type of pixel in og pixel is %@", image.pixelFormatInfo)
        print("the type of colourspace in og pixel is %@", image.colorSpace)
        print("the type of bitmapinfo in og pixel is %@", image.bitmapInfo)
        print("the type of alpha in og pixel is %@", image.alphaInfo)

        //NSLog("the type of pixel in og pixel is %@",CVPixelBufferGetPixelFormatType((image.ciImage?.pixelBuffer)!))
        
    }
    
    func createDepthImageFromMap(avDepthData: AVDepthData, orientation: UIImage.Orientation, visualBool: Bool = false) {
        
        var avDepthData = avDepthData
        
        print("in depth image mpa")
        /*
         First we need to normalize the depth numbers in the pixel buffer
         Then we will convert to greyscale.
         Why greyscale you say? Because depth pixels are single channel
         */
        
        
        /*
         Added this line because of a tutorial, its unclear whether I actually need it
         */
        if avDepthData.depthDataType != kCVPixelFormatType_DisparityFloat32 {
            avDepthData = avDepthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
        }
        
        let originalDepthDataMap = avDepthData.depthDataMap
        
        
        let width = CVPixelBufferGetWidth(originalDepthDataMap)
        let height = CVPixelBufferGetHeight(originalDepthDataMap)
        print("depthmap width is ",width )
        print("depthmap height is ", height)
        CVPixelBufferLockBaseAddress(originalDepthDataMap, CVPixelBufferLockFlags(rawValue: 0))
        
        var maybePixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(nil, width, height, avDepthData.depthDataType, nil, &maybePixelBuffer)
        
        //assert(status == kCVReturnSuccess && maybePixelBuffer != nil);
        
        
        /*
         This whole reference to PB (and ensuing references) may be completely superflous
        */
        guard let PB = maybePixelBuffer else {
            return
        }
        
        CVPixelBufferLockBaseAddress(PB, CVPixelBufferLockFlags(rawValue: 0))
        guard let address = CVPixelBufferGetBaseAddress(originalDepthDataMap) else {
            print("we have an error in export depth map")
            return
        }
        
        var minPixel: Float = 1.0
        var maxPixel: Float = 0.0
        
        for y in 0 ..< height{
            
            let distortedRow = address + y * CVPixelBufferGetBytesPerRow(originalDepthDataMap)
            let distortedData = UnsafeBufferPointer(start: distortedRow.assumingMemoryBound(to: Float32.self), count: width)
            for x in 0 ..< width{
                let pixel =  distortedData[x]
                //print(y,x," ", pixel)
                minPixel = min(pixel, minPixel)
                maxPixel = max(pixel, maxPixel)
            }
        }
        
        //let floatBuffer = unsafeBitCast(address, to: UnsafeMutablePointer<Float32>.self)
        
        print("The min depth value is ",minPixel)
        print("The max depth value is ",maxPixel)
        
        //TODO check this
        //the minimum distance should never be less than zero
//        if(minPixel <= 0){
//            minPixel = 0
//        }
        
        let range = maxPixel - minPixel
        print("The range is ",range)
        
        //we retry min and max for testing
        //minPixel = Float.greatestFiniteMagnitude
        //maxPixel = -Float.greatestFiniteMagnitude
        
        for y in 0 ..< height {
            
            let distortedRow = address + y * CVPixelBufferGetBytesPerRow(originalDepthDataMap)
            let distortedData = UnsafeMutableBufferPointer(start: distortedRow.assumingMemoryBound(to: Float32.self), count: width)
            
            for x in 0 ..< width {
                var pixel =  distortedData[x]
//                if(pixel <= 0){
//                    pixel = 0
//                }
                distortedData[x] = ((pixel - minPixel) / range) //* 255
                //minPixel = min(distortedData[x], minPixel)
                //maxPixel = max(distortedData[x], maxPixel)
                //print(distortedData[x])
            }
            
        }
        
        print("finished printing")
        //let colorSpace = CGColorSpaceCreateDeviceGray()

        let cmage = CIImage(cvPixelBuffer: originalDepthDataMap)
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(cmage, from: cmage.extent)!
        print("about to create UIimage to be saved")
        let outputImage = UIImage(cgImage: cgImage, scale: 1, orientation: orientation)
        
        UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil)
        if (visualBool){
            print("in visualBool")
            //visualizePointInImage(cgImage: cgImage, crossHairRadius: 10, thickness: 3)
            
            let distortionLookupTable = (avDepthData.cameraCalibrationData?.lensDistortionLookupTable)!
            let distortionCenter = avDepthData.cameraCalibrationData?.lensDistortionCenter
            //lets see what the rectifyPixelData function does on depthmap data
            //rectifyPixelData(cgImage: cgImage, lookupTable: distortionLookupTable, distortionOpticalCenter: distortionCenter!)
            print("about to call rectifyDepthData function")
            rectifyDepthData(avDepthDataT: avDepthData)//, image: UIImage)
            //rectifyDepthData
            
        }
        
        
        //print("The new min is ", minPixel)
        //print("The new max is ", maxPixel)
        
        CVPixelBufferUnlockBaseAddress(PB, CVPixelBufferLockFlags(rawValue: 0))
    }
    
    
    func testRectDepth(avDepthData: AVDepthData, image: UIImage){
        let originalDepthDataMap = avDepthData.depthDataMap
        let width = CVPixelBufferGetWidth(originalDepthDataMap)
        let height = CVPixelBufferGetHeight(originalDepthDataMap)
        print("the width is %@", width)
        print("the width is %@", height)
    }
    
    /*
 At the moment we are looking at values in the original depth map, this will need to change when we look at values in the new one
     */
    
    func getDistance(at: CGPoint, avPhoto: AVDepthData)->Float?{
        print("in getDistance")
        let depthM = avPhoto.depthDataMap
        print("did we get here?")
        
        CVPixelBufferLockBaseAddress(depthM, CVPixelBufferLockFlags(rawValue: 0))
        
        guard let address = CVPixelBufferGetBaseAddress(depthM) else {
            print("an error in getDistance")
            return nil
        }
       
        let width = CVPixelBufferGetWidth(depthM)
        let height = CVPixelBufferGetHeight(depthM)
        print("depthdatamap width is ", width)
        print("depthdatamap height is ", height)
        
        let distortedRow =  address + (Int(at.y)  * CVPixelBufferGetBytesPerRow(depthM)) //+ Int(at.x)
        let distortedData = UnsafeBufferPointer(start: distortedRow.assumingMemoryBound(to: Float32.self), count: width)
        
        /*
         Keep in mind that this value is disparity (1/m)
        */
        let valToReturn = distortedData[Int(at.x)]
        print("we searched for depth at ", at.x, " ",at.y)
        print("depth value is ", valToReturn)
        
        CVPixelBufferUnlockBaseAddress(depthM, CVPixelBufferLockFlags(rawValue: 0))
        
        return valToReturn
        
        //return 4.2
    }
    
    /*
     * stackoverflow.com/questions/3707726/how-do-i-measure-the-distance-traveled-by-an-iphone-using-the-accelerometer
     *
     * stackoverflow.com/questions/6647314/how-can-i-find-distance-traveled-with-a-gyroscope-and-accelerometer
     */
    func getDistanceFromLastPhoto(){
        
    }
    
    /*
     stackoverflow.com/questions/44857179/get-distance-to-surface-with-arkit
     */
    func distanceToBoundingBox(){
        
    }
    
    func setDepthLabel(){
        
        //let depthPixelBuffer = depthDataOutput.depthDataMap
        //let sampleBuffer = videoDataOutput.sampleBuffer
        
        //let vidPixelsWide = CVPixelBufferGetWidth(sampleBuffer)
        //let vidPixelsWide = CVPixelBufferGetWidth(videoDataOutput)
        
        //let Pointer = 4*((Int(vidPixelsWide) * Int(currentTouch.y)) + Int(currentTouch.x))
        
    
    }
    
    /*
     Get depth at point that user touched
    */
    func getDepthAtPoint(){
        
        //let scale = CGFloat(CVPixelBufferGetWidth(depthFrame)) / CGFloat(CVPixelBufferGetWidth(videoFrame))
        //let depthPoint = CGPoint(x: CGFloat(CVPixelBufferGetWidth(depthFrame)) - 1.0 - texturePoint.x * scale, y: texturePoint.y * scale)
        
    }
    
    
    /*
    NOW
     */
    @objc func getDepthTouch(gesture: UILongPressGestureRecognizer){
        print("in depth touch")
        let point: CGPoint?
        if gesture.state == .began {
            print("**()**")
            point = gesture.location(in: photoPreviewImageView)
            print("the x coord was", point!.x)
            print("the y coord was", point!.y)
            currentTouch = point
            print("the width of th image is ", photoPreviewImageView.bounds.size.width)
            print("the height of th image is ", photoPreviewImageView.bounds.size.height)
            
            let scaledx =  currentTouch!.x / photoPreviewImageView.bounds.size.width
            let scaledy =  currentTouch!.y / photoPreviewImageView.bounds.size.height
            
            print("scaled x is ", scaledx)
            print("scaled y is ", scaledy)
            
            
            //CG
        } else if  gesture.state == .ended {
            print("&&&&&")
            /*
             Once the gesture has ended we set the capturePhotoFlag3 variable, and this allows the image capture process to take place after the use touches the photo preview view
            */
            capturePhotoFlag3 = true
            capturePhotoFlag1 = false
            
            //set up av capture process
            
            var photoSettings = AVCapturePhotoSettings()
            //photoSettings.isDepthDataDeliveryEnabled = true
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            //JUST ADDED
            photoSettings.isDepthDataDeliveryEnabled =
                photoOutput!.isDepthDataDeliverySupported
            
            print("about to set up delegate")
            
            print("delegate should have been created")
            photoOutput!.capturePhoto(with: photoSettings, delegate: self)
            
            
            updateDepthLabel = true
            print("updated depth label to true")
            
        }
        
    }
    
    /*
     maybe we run a depth discontinuity algo on the cv pixel buff
    */
    func depthSegmentation(){
        
    }
    
   
    /*
     Based on the GSD of the phone we tell user to move camera
     www.agisoft.com/forum/index.php?topic=9132.0
     
     We will also need to have preliminary guess of the size of the object
     
     We will also need some heuristics on the what is the best distance for the camera
     
     GSD units are mm/pixel
     
     * GSD = (DISTANCE x SENSORwidth) / (IMAGEwidth x FOCALLENGTH)
     * lets say we take picture .5 meters away
     * 500mm x 4.25mm/ 4000pixels x 4.25 mm
     
     * so long as camera is ~< 3 meters from object we can theoretically get <1mm resolution
     
     */
    func guidedPhotoLength(){
        
    }
    
    //focal length = 4.25mm or (26 mm for 35mm equivalent)
    //www.google.com/search?q=iphone+xs+sensor+width&oq=iphone+xs+sensor+width&aqs=chrome..69i57j33l5.8231j0j7&sourceid=chrome&ie=UTF-8

//    private func getPoints(avDepthData: AVDepthData,  image: UIImage)->Array<Any>{
//        let depthData = avDepthData. converting(toDepthDataType: kCVPixelFormatType_DepthFloat32)
//        guard let intrinsicMatrix = avDepthData.cameraCalibrationData?.intrinsicMatrix, let depthDataMap = rectifyDepthData(avDepthData: depthData, image: image) else {
//                return []
//            }
//
//        CVPixelBufferLockBaseAddress(depthDataMap, CVPixelBufferLockFlags(rawValue: 0))
//
//        let width = CVPixelBufferGetWidth(depthDataMap)
//        let height = CVPixelBufferGetHeight(depthDataMap)
//
//        var points = Array<Any>()
//        let focalX = Float(width) *  ( intrinsicMatrix[0][0] / Float(image.size.width))
//        let focalY = Float(height) * ( intrinsicMatrix[1][1] / Float(image.size.height))
//        let principalPointX = Float(width) * (intrinsicMatrix[2][0] / Float(image.size.width))
//        let principalPointY = Float(height) * (intrinsicMatrix[2][1] / Float (image.size.height))
//        for y in 0 ..< height{
//            for x in 0 ..< width{
//                guard let Z = getDistance(at: CGPoint(x: x, y: y) , depthMap: depthDataMap) else {
//                    continue
//                }
//                let X = (Float(x) - principalPointX) * Z / focalX
//                let Y = (Float(y) - principalPointY) * Z / focalY
//                points.append(RThree(x: X, y: Y, z: Z))
//            }
//        }
//        CVPixelBufferUnlockBaseAddress(depthDataMap, CVPixelBufferLockFlags(rawValue: 0))
//
//        return points
//    }
    
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        /*
         the count stuff here is just so we don't print too much.
         It should print **roughly** every second
        */
        if (count < 1000000){
            count = count + 1
        }
        if(count >= 1000000){
            count = 2
        }
        
        if((count % 100) == 0){
            print(count)
            print("we are receiving info from synchronized data")
        }
        
        guard let syncedDepthData: AVCaptureSynchronizedDepthData =
            (synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData), let syncedVideoData: AVCaptureSynchronizedSampleBufferData =
            (synchronizedDataCollection.synchronizedData(for: videoDataOutput) as? AVCaptureSynchronizedSampleBufferData) else{
                print("guard let is exiting line 832")
                return
        }
        
        if syncedDepthData.depthDataWasDropped || syncedVideoData.sampleBufferWasDropped {
            print("data was dropped")
            return
        }
        
        let depthData = syncedDepthData.depthData
        let depthPixelBuffer = depthData.depthDataMap
        let sampleBuffer = syncedVideoData.sampleBuffer
        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
                print("error getting buffer")
                return
        }
        
        if(updateDepthLabel){
            
            //TOGGLE
//            print("we are accessing this")
//
//            let scale = CGFloat(CVPixelBufferGetWidth(depthPixelBuffer)) / CGFloat(CVPixelBufferGetWidth(videoPixelBuffer))
//            //why do we have the depthpoint looking like this? what is the "1 -" doing
//            //we will save the images to see if they are indeed the same
//            //let depthPoint = CGPoint(x: CGFloat(CVPixelBufferGetWidth(depthPixelBuffer)) - 1.0 - currentTouch!.x * scale, y: currentTouch!.y * scale)
//
//
//            let cmage = CIImage(cvPixelBuffer: videoPixelBuffer)
//            let context = CIContext(options: nil)
//            let cgImage = context.createCGImage(cmage, from: cmage.extent)!
//            let outputImage = UIImage(cgImage: cgImage, scale: 1, orientation: .right)
//            //save image before manipulation
//            UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil)
//
//            visualizePointInImage(cgImage: cgImage )
//
//            //let rowData = CVPixelBufferGetBaseAddress(depthPixelBuffer)! + Int(depthPoint.y) * CVPixelBufferGetBytesPerRow(depthFrame)
//
//            print("the width of depth buffer is ", CVPixelBufferGetWidth(depthPixelBuffer))
//            print("the height of depth buffer is ", CVPixelBufferGetHeight(depthPixelBuffer))
//
//            createDepthImageFromMap(avDepthData: depthData, orientation: .up)
//
           updateDepthLabel = false
        }
        
    }
    
    /*
     NOW
     */
    
    /*
     take the cg point, and image and get pixel coords from image
    */
    func translatePointToPixel(){
        
        
    }
    func getDepthPoint(depthdata: AVDepthData , cgImage: CGImage){
        
        let depthPixelBuffer = depthdata.depthDataMap
        let pixelsWide = cgImage.width
        let pixelsHeight = cgImage.height
        
        print("we are accessing this")
        
        //let scale = CGFloat(CVPixelBufferGetWidth(depthPixelBuffer)) / (Float (pixelsWide))
        
        //why do we have the depthpoint looking like this? what is the "1 -" doing
        //we will save the images to see if they are indeed the same
        //let depthPoint = CGPoint(x: CGFloat(CVPixelBufferGetWidth(depthPixelBuffer)) - 1.0 - currentTouch!.x * scale, y: currentTouch!.y * scale)
        
        
        let outputImage = UIImage(cgImage: cgImage, scale: 1, orientation: .right)
        
        //TOGGLE
        //save image before manipulation
        //UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil)
        
        visualizePointInImage(cgImage: cgImage, crossHairRadius: 200, thickness: 10 )
        
        //get depth value
        //let val = translatePointToPixel()
        let val = 4.2
        //some thread error
        
        //****NOW
        
        DispatchQueue.main.async {
            self.textLabel.text = String(val)
            
            self.updateDepthLabel = false
            
        }
        
        print("the width of depth buffer is ", CVPixelBufferGetWidth(depthPixelBuffer))
        print("the height of depth buffer is ", CVPixelBufferGetHeight(depthPixelBuffer))
        
        //TOGGLE
        createDepthImageFromMap(avDepthData: depthdata, orientation: .right, visualBool: true)
        
        
        
    }
    
    /*
     * This may be a very rough speed
     * How do we handle when the motion stops?
     * then acceleration is zero and we should return zero
    */
    
    func calcSpeed(accel: Double , prevSpeed: Double ) -> Double{
        //case we are still seeing
        var currSpeed = prevSpeed + (accel * Double (motionInterval))
        return 4.0
        
    }
    
    func addRotationAnimation(){
        print("*&*&")
        print("in add rotation")
        //?.cgImage
        //print("image height is ", im?.height)
        //print("image width is ", im?.width)
        
        DispatchQueue.main.async {
            // view manipulation here so it happens with main thread.
            
            self.tempView = UIImageView(image: UIImage(named: "move")!)
            self.tempView!.frame = CGRect(x: 160, y: 45, width: 90, height: 30)
            //tempView.addTag
            
            self.photoPreviewImageView.addSubview(self.tempView!)
            
            self.textLabel.text = "While keeping the object in frame slowly walk around. Please maintain the same distance"
            
            var timer = Timer.scheduledTimer(timeInterval: TimeInterval(2.0), target: self, selector: "timeExpired", userInfo: nil, repeats: false)
        }
        
        //TODO
        // we will
        /*
         stackoverflow.com/questions/36524066/how-to-move-sprite-just-left-or-right-using-coremotion
         
        arrowView = UIImageView(image: UIImage(named: "arrow")!)
        arrowView!.frame = CGRect(x: 62.5, y: 84, width: 250, height: 333)
        */
        
    }
    /*
     * Important that we have @obj c because this function comes from a selector
    */
    @objc func timeExpired() {
        print("time to remove the animation")
        
        var uiEffectFlag = false
        var devEffectFlag = false
        
        if tempView != nil { // Dismiss the view from here
            tempView!.removeFromSuperview()
        }
        
        DispatchQueue.main.async {
            
            self.tempView = UIImageView(image: UIImage(named: "arrow")!)
            self.tempView!.frame = CGRect(x: 0, y: 430, width: 90, height: 45)
            self.tempView?.alpha = 0.5
            
            if(uiEffectFlag){
                let min = CGFloat(-100)
                let max = CGFloat(100)
                
                let xMotion = UIInterpolatingMotionEffect(keyPath: "layer.transform.translation.x", type: .tiltAlongHorizontalAxis)
                xMotion.minimumRelativeValue = min
                xMotion.maximumRelativeValue = max
                
                let yMotion = UIInterpolatingMotionEffect(keyPath: "layer.transform.translation.y", type: .tiltAlongVerticalAxis)
                yMotion.minimumRelativeValue = min
                yMotion.maximumRelativeValue = max
                
                let motionEffectGroup = UIMotionEffectGroup()
                motionEffectGroup.motionEffects = [xMotion,yMotion]
                
                self.tempView!.addMotionEffect(motionEffectGroup)
                
            }
            
            /*
             dev motion option
            */
            var xspeed = 0.0
            var yspeed = 0.0
            
            var devMotionCheck = 0
            
            if(self.devMotionFlag == 1)&&(devEffectFlag){
                print("trying out dev motion based ui move")
                self.motionManager?.deviceMotionUpdateInterval = self.motionInterval
                self.motionManager!.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {(data, error) in
                    guard let data = data else { return }
                    let gravity = data.gravity
                    let rotation = atan2(gravity.x, gravity.y) - .pi
                    
                    let xa = data.userAcceleration.x
                    let ya = data.userAcceleration.y
                    let za = data.userAcceleration.z
                    
                    print("before the operationqueue ")
                    //be careful with counter it will increment very quickly
                    OperationQueue.main.addOperation {
                        
                        //this should lead to only one print statement
                        while(devMotionCheck < 1){
                            print("we seem to be accessing devmotion data")
                            print("xa is ", xa)
                            print("ya is ", ya)
                            print("za is ", za)
                            devMotionCheck = 1
                        }
                        
                        xspeed = self.calcSpeed(accel: xa, prevSpeed: xspeed)
                        yspeed = self.calcSpeed(accel: ya, prevSpeed: yspeed)
                        self.tempView!.transform.translatedBy(x: CGFloat(xspeed), y: CGFloat(yspeed))// = CGAffineTransform(rotationAngle: CGFloat(rotation))
                    }
                })
            }
            
            //bezier implementation of a sine wave
            
//            let width = 300.0
//            let height = 90.0
//
//            //let amplitude = 90
//
//            let origin = CGPoint(x: width * (1) / 2, y: height * 0.50)
//
//            let path = UIBezierPath()
//            path.move(to: origin)
//
//            for angle in stride(from: 5.0, through: 360.0, by: 5.0) {
//                let x = origin.x + CGFloat(angle/360.0) * CGFloat(width)
//                let y = origin.y - CGFloat(sin(angle/180.0 * Double.pi)) * CGFloat(height) //* amplitude
//                path.addLine(to: CGPoint(x: x, y: y))
//            }
//
//            self.tempView!.draw(<#T##rect: CGRect##CGRect#>)
//
//            UIColor.black.setStroke()
//            path.stroke()
//
            
        
            
        
            //This stuff works
            
            self.photoPreviewImageView.addSubview(self.tempView!)
        }
        
        //photoPreviewImageView.removeSubview(tempView)
        // yoursubview.removeFromSuperview()
    }
    
    

    
    func visualizePointInImage(cgImage: CGImage, crossHairRadius: Int, thickness: Int){
        
        print("in visualize image with point")
        let pixelsWide = cgImage.width
        let pixelsHigh = cgImage.height
        print("width is ", pixelsWide)
        print("height is ", pixelsHigh)
        
        let bitmapBytesPerRow = pixelsWide * 4
        let bitmapByteCount = bitmapBytesPerRow * Int(pixelsHigh)
        
        // Use the generic RGB color space.
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        print("device colour space all good")
        
        // Allocate memory for image data. This is the destination in memory
        // where any drawing to the bitmap context will be rendered.
        let bitmapData = malloc(bitmapByteCount)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        let size = CGSize(width: pixelsWide, height: pixelsHigh)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        // create bitmap
        let context = CGContext(data: bitmapData, width: pixelsWide, height: pixelsHigh, bitsPerComponent: 8,
                                bytesPerRow: bitmapBytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        print("created first context")
        
        // draw the image onto the context
        let rect = CGRect(x: 0, y: 0, width: pixelsWide, height: pixelsHigh)
        context?.draw(cgImage, in: rect)
        print("should have written first image to buffer")
        
        let data = context!.data
        print("about to bind memory to buffer")
        let dataBuf = data!.bindMemory(to: UInt8.self, capacity: pixelsWide * pixelsHigh * 4)
        
        //destination buffer
        let newBitmapData = malloc(bitmapByteCount)
        //let newBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        //let newSize = CGSize(width: pixelsWide, height: pixelsHigh)
        let otherContext = CGContext(data: newBitmapData, width: pixelsWide, height: pixelsHigh, bitsPerComponent: 8, bytesPerRow: bitmapBytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        let otherRect = CGRect(x: 0, y: 0, width: pixelsWide, height: pixelsHigh)
        
        otherContext?.draw(cgImage, in: otherRect)
        
        let newData = otherContext!.data
        let newDataBuf = newData!.bindMemory(to: UInt8.self, capacity: pixelsWide * pixelsHigh * 4)
        //let pixelBuffer = buffer.bindMemory(to: RGBA32.self, capacity: pixelsWide * pixelsHigh)
        
        /*
         we are going to create a line arround the pixel we touched
        */
        
        for row in 0 ..< Int(pixelsHigh) {
            for column in 0 ..< Int(pixelsWide) {
                //var point: CGPoint?
                let rectifiedPointer = 4*((Int(pixelsWide) * row + column))
                let distortedPointer = 4*((Int(pixelsWide) * row + column))
                //rgba green?
                    newDataBuf[rectifiedPointer] = dataBuf[distortedPointer]
                    newDataBuf[rectifiedPointer + 1] = dataBuf[distortedPointer + 1]
                    newDataBuf[rectifiedPointer + 2] = dataBuf[distortedPointer + 2]
                    newDataBuf[rectifiedPointer + 3] = dataBuf[distortedPointer + 3]
            }
        }
        /*
         * the terms width and height are used for the opposite dimensions when referring to the the previewImage, and the actual photo
         * so here we are scaling the cgpoint by the absolute values the cgpoint could have taken
         * thus it is x/width and y/height
        */
        let scaledx = 1.0 - Float ((currentTouch!.x) / photoPreviewImageView.bounds.size.width)
        let scaledy = Float (currentTouch!.y / photoPreviewImageView.bounds.size.height)
        
        print("scaled x is ", scaledx)
        print("scaled y is ", scaledy)
        
        /*
         The multiplication below is a little tricky because we needed to get the double value then convert to int, otherwise it just becomes 0
        */
        //the x co-ord in terms of pixels
        let offsetX = scaledx *  (Float (pixelsHigh))
        //the y co-ord in terms of pixels
        let offsetY = scaledy *  (Float (pixelsWide))
        //we multiply offsetX by pixelsWide because each row in the pixelbuffer is equal to a column in the pixture
        // this can be verified below
        let offset = Int(4 * ((offsetX * (Float (pixelsWide))) + offsetY))
        print("offsetX is ", offsetX)
        print("offsetY is ", offsetY)
        print("offset is ", offset)
        //print(offset/4)
        
        /*
         this funciton is not safe if you don't leave 50 pixel width from the edge
         because I don't handle for cases where we are not accessing the buffer
        */
        
        
//        for j in -(thickness) ..< thickness{
//            var newoffset = offset + (j * (pixelsWide - 1) * 4)
//            /*
//             **** as found from testing
//             this gives us a horizontal line
//             */
//
//
//            for i in -(crossHairRadius) ..< crossHairRadius {
//                //offset = offset - pixelsWide
//                newDataBuf[newoffset + (pixelsWide * i * 4)] = 0
//                newDataBuf[newoffset + (pixelsWide * i * 4) + 1] = 220
//                newDataBuf[newoffset + (pixelsWide * i * 4) + 2] = 220
//                newDataBuf[newoffset + (pixelsWide * i * 4) + 3] = 1
//            }
//
//            /*
//             this gives a vertical line
//             */
//
//            for k in -(crossHairRadius) ..< crossHairRadius{
//                newDataBuf[newoffset + (k * 4)] = 0
//                newDataBuf[newoffset + (k * 4) + 1] = 220
//                newDataBuf[newoffset + (k * 4) + 2] = 220
//                newDataBuf[newoffset + (k * 4) + 3] = 1
//            }
//
//        }
        
//
        //shall use this to find the right offset
        //120,000 is getting us br
        let attempt = 400
        
        for j in 0 ..< 5{//thickness{
        var newattempt = attempt + (j * (pixelsWide - 1) * 4)
                    /*
                     **** as found from testing
                     this gives us a horizontal line
                     */
            for i in 0 ..< 20 {
                //offset = offset - pixelsWide
                newDataBuf[newattempt + (pixelsWide * i * 4)] = 220
                newDataBuf[newattempt + (pixelsWide * i * 4) + 1] = 220
                newDataBuf[newattempt + (pixelsWide * i * 4) + 2] = 220
                newDataBuf[newattempt + (pixelsWide * i * 4) + 3] = 1
            }

            for i in 0 ..< 20{
                newDataBuf[newattempt + (i * 4)] = 0
                newDataBuf[newattempt + (i * 4) + 1] = 220
                newDataBuf[newattempt + (i * 4) + 2] = 0
                newDataBuf[newattempt + (i * 4) + 3] = 1
            }
        }
        
        print("about to create visualized image")
        let outputCGImage = otherContext!.makeImage()!
        //scale 1 is the same scale as CGimage, 0 orientation is up?
        print("about to save visualized image")
        let outputImage = UIImage(cgImage: outputCGImage, scale: 1, orientation: .right)
        UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil)
        print("image should have saved and exiting visualize function")
        
        free(data)
        free(newData)
        
    }
    
    /*
     workspace code
    */
    
    /*
     motion manager alternate implementation
    */
    /*
        self.motionManager!.startDeviceMotionUpdates(
        using: .xMagneticNorthZVertical,
        to: OperationQueue.current!,
        withHandler: {(data, error) in
        if let validData = data {
        // Get the attitude relative to the magnetic north reference frame.
        let xa = validData.userAcceleration.x
        let ya = validData.userAcceleration.y
        let za = validData.userAcceleration.z
        // Use the motion data in your app.
        self.outputDevMotionData(data: validData)
        }
        })
    */
    
    

}

extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        //var photoData: Data?
        
        print("in didFinishProcessingPhoto")
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            print("we seem to be error free")
            //photoData = photo.fileDataRepresentation()
            
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else { return }
                PHPhotoLibrary.shared().performChanges({
                    // Add the captured photo's file data as the main resource for the Photos asset.
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: photo.fileDataRepresentation()!, options: nil)
                }, completionHandler: { success, error in
                    if success{
                        print("saved image to library")
                        
                        //this flag needs to be set for the first successful shot
                        if(!self.firstShotTaken){
                            self.firstShotTaken = true
                        }
                        
                        //we want these variables to have greater scope so they are out of the capturePhotoFlag1 statement
                        let avDepthData = photo.depthData
                        let temp = photo.cgImageRepresentation()
                        let cgim = temp!.takeUnretainedValue()//!.takeRetainedValue()
                        
                        //time stamp
                        if(self.capturePhotoFlag1){
                            let totalSeconds = CMTimeGetSeconds(photo.timestamp)
                            print("photo was taken at ", totalSeconds)
                            print("which in a human readable is ", totalSeconds)
                            
                            //getting information about pixel format type in cg file
                            
                            
                            let pixelsWide = cgim.width
                            let pixelsHigh = cgim.height
                            print("cg width is ", pixelsWide)
                            print("cg height is ", pixelsHigh)
                            
                            // developer.apple.com/videos/play/wwdc2017/508/
                            // image pixels significantly more than depth pixels
                            // 4032 x 3024 vs 768 x 576
                            
                            print("cg rep")
                            self.testRect(image: cgim)
                            print("finsihed testrect")
                            
                            /*
                             * Testing depth functions
                             *
                             */
                            
                            
                            let cgTestPointOne = CGPoint(x: 3,y: 5)
                            self.getDistance(at: cgTestPointOne, avPhoto: photo.depthData!)
                            print("finished messing with depth")
                            //let cgTestPointTwo = CGPoint(x: 14,y: 60)
                            //self.getDistance(at: cgTestPointOne, avPhoto: photo.depthData!)
                            
                            /*
                             we test the general image pixel rectification in here
                             */
                            
                            let distortionLookupTable = avDepthData?.cameraCalibrationData?.lensDistortionLookupTable
                            let distortionCenter = avDepthData?.cameraCalibrationData?.lensDistortionCenter
                            print("we found distortionLookupTable and distortionCenter and about to enter rectifyPixel")
                            
                            //self.rectifyPixelData(cgImage: cgim, lookupTable: distortionLookupTable!, distortionOpticalCenter: distortionCenter!)
                            
                            //let scaledCenter = CGPoint(x: (distortionCenter!.x / CGFloat(pixelsHigh)) * CGFloat(pixelsWide), y: (distortionCenter!.y / CGFloat(pixelsWide)) * CGFloat(pixelsHigh))
                            
                            // print("2nd call to rectifyPixel")
                            
                            // self.rectifyPixelData(cgImage: cgim, lookupTable: distortionLookupTable!, distortionOpticalCenter: scaledCenter)
                            
                            self.createDepthImageFromMap(avDepthData: avDepthData!, orientation: .right)
                        }
                       
                        
                        //this flag signifies we want to send the depth data to further processing
                        /*
                        NOW
                        */
                        if(self.capturePhotoFlag3){
                            
                            print("sending depth info to getDepthPoint")
                            self.getDepthPoint(depthdata: avDepthData!, cgImage: cgim)
                            self.capturePhotoFlag1 = true
                            
                            self.addRotationAnimation()
                        }
                        
                    }
                    else {
                        print("Opus couldn't save the photo to your photo library")
                    }
                })
            }
        }
    }
        
}



