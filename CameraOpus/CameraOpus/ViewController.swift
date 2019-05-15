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


/*
 General Info learnt
 
 depthdatamap width is 768
 depthdatamap height is 576
 
 avcapturphotooutput width is 4032
 avcapturphotooutput height is 3024
 
 arkitcapture is about 2megapixels
 
 avvideoframe width is 1504 (cgImage.width)
 avvideoframe height is 1128 (cgImage.height)
 
 keep in mind cgpoint y seems to correspond to pixel width
 
 */

/*
 log of todo now
 - believe we have to create a synchronized data and video display, because UI will show depth segmented images
 - ie in the ideal case: will need continuous access to video buffer which we will modify before showing the user
 - modification will be based on depthdata
 */

/*
 log of nice to haves
 - timstamps of image taking
 -
 
 */

/*
 CURRENT STACK
 
 - trying to debug why the new image is not being saved
 - the print stateents indicate "image should have saved" but we see nothing
 - then we also see an error in (synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData)! of dataOutputSynchronizer
 
 */


class ViewController: UIViewController, UITextFieldDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureDataOutputSynchronizerDelegate {
    
    var count = 1
    
    var session = AVCaptureSession()
    var photoOutput: AVCapturePhotoOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    
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
    func outputAccelData(acceleration: CMAcceleration){
//        print("from accel")
//
//        print("teh accel is ", acceleration.x)
//        print("teh accel is ", acceleration.y)
//        print("teh accel is ", acceleration.z)
//        print(" ")
        
    }

    func outputDevMotionData(data: CMDeviceMotion){
//        print("from devmotion")
//        print("teh accel is ", data.userAcceleration.x)
//        print("teh accel is ", data.userAcceleration.y)
//        print("teh accel is ", data.userAcceleration.z)
//        print(" ")
        
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
                //Now that we set input device lets set output files
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
                    
                    // we start running the accel right away but not the gyro
                    if((accelFlag == 1)&&(devMotionFlag == 1)){
                        motionManager?.accelerometerUpdateInterval = 10.0
                        motionManager!.startAccelerometerUpdates(
                            to: OperationQueue.current!,
                            withHandler: {(accelData: CMAccelerometerData?, errorOC: Error?) in
                                self.outputAccelData(acceleration: accelData!.acceleration)
                        })
                        motionManager?.deviceMotionUpdateInterval = 10.0
                        motionManager!.startDeviceMotionUpdates(
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
                        print("running accelerometer and device motion")
                        print("**")
                        
                        
                        
                    }
                    
                    //photoOutput!.isDepthDataDeliveryEnabled = true
                    //Now we try to connect the preview layer which will eventually be the element in the IB to what the camera sees
                    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
                    videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspect
                    videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                    
                    
                    outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [videoDataOutput, depthDataOutput])
                    
                    
                    //NOW
                    outputSynchronizer?.setDelegate(self, queue: dataOutputQueue)
                    
                    //photoPreviewImageView.contentMode = .scaleAspectFit
                    
                    photoPreviewImageView.layer.addSublayer(videoPreviewLayer!)
                    print("seems like we have added a subLayer")
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
        gyroMeasure
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
    }
    /*
     To create a rectilinear image we must begin with an empty destination buffer and iterate through it
     row by row, calling the sample implementation below for each point in the output image, passing the
     lensDistortionLookupTable to find the corresponding value in the distorted image, and write it to your
     output buffer.
     
     ie we know that the lensDistortionLookupTable is correct,
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
    
    /*
     For each point (x,y co-ord) (not pixel value, just co-ord ie no RGB) in the rectified image, find each correspondging x,y co-ord in the non rectified image.
     Take the depth value at the x,y co-ord and put into the right co-ord in the rectified image
     */
    
    private func rectifyDepthData(avDepthData: AVDepthData, image: UIImage) -> CVPixelBuffer? {
        guard
            let distortionLookupTable = avDepthData.cameraCalibrationData?.lensDistortionLookupTable,
            let distortionCenter = avDepthData.cameraCalibrationData?.lensDistortionCenter else {
                return nil
        }
        
        let originalDepthDataMap = avDepthData.depthDataMap
        let width = CVPixelBufferGetWidth(originalDepthDataMap)
        let height = CVPixelBufferGetHeight(originalDepthDataMap)
        // Assumption is that the original depth map is not the same size as the rectified depth map, makes
        // this funtion scale invariant.
        let scaledCenter = CGPoint(x: (distortionCenter.x / CGFloat(image.size.height)) * CGFloat(width), y: (distortionCenter.y / CGFloat(image.size.width)) * CGFloat(height))
        CVPixelBufferLockBaseAddress(originalDepthDataMap, CVPixelBufferLockFlags(rawValue: 0))
        
        /*
         TODO
         Why are we creating a new pixel buffer instead of a new depthmap here?
         TODO
         */
        var maybePixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(nil, width, height, avDepthData.depthDataType, nil, &maybePixelBuffer)
        
        assert(status == kCVReturnSuccess && maybePixelBuffer != nil);
        
        guard let rectifiedPixelBuffer = maybePixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(rectifiedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        guard let address = CVPixelBufferGetBaseAddress(originalDepthDataMap) else {
            return nil
        }
        //This is getting the depth values and putting into the new depthmap
        for y in 0 ..< height{
            let rowData = CVPixelBufferGetBaseAddress(rectifiedPixelBuffer)! + y * CVPixelBufferGetBytesPerRow(rectifiedPixelBuffer)
            let data = UnsafeMutableBufferPointer(start: rowData.assumingMemoryBound(to: Float32.self), count: width)
            
            //
            for x in 0 ..< width{
                let rectifiedPoint = CGPoint(x: x, y: y)
                let distortedPoint = lensDistortionPoint(point: rectifiedPoint, lookupTable: distortionLookupTable, distortionOpticalCenter: scaledCenter, imageSize: CGSize(width: width, height: height) )
                
                let distortedRow = address + Int(distortedPoint.y) * CVPixelBufferGetBytesPerRow(originalDepthDataMap)
                let distortedData = UnsafeBufferPointer(start: distortedRow.assumingMemoryBound(to: Float32.self), count: width)
                data[x] = distortedData[Int(distortedPoint.x)]
            }
        }
        CVPixelBufferUnlockBaseAddress(rectifiedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        CVPixelBufferUnlockBaseAddress(originalDepthDataMap, CVPixelBufferLockFlags(rawValue: 0))
        return rectifiedPixelBuffer
    }
    
    /*
     TODO once we know how to create pixel buffers
     */
    
    func rectifyPixelData(cgImage: CGImage, lookupTable: Data, distortionOpticalCenter opticalCenter: CGPoint) {
        
        // Get image width, height
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
    
    func createDepthImageFromMap(avDepthData: AVDepthData) {
        
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
        let outputImage = UIImage(cgImage: cgImage, scale: 1, orientation: .right)
        UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil)
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
    
    
    //WORKING ON
    @objc func getDepthTouch(gesture: UILongPressGestureRecognizer){
        print("in depth touch")
        let point: CGPoint?
        if gesture.state == .began {
            print("**()**")
            point = gesture.location(in: photoPreviewImageView)
            print("the x coord was", point!.x)
            print("the y coord was", point!.y)
            currentTouch = point
        } else if  gesture.state == .ended {
            print("&&&&&")
            updateDepthLabel = true
            print("updated depth label to true")
            
        }
        
    }
    
    /*
     maybe we run a depth discontinuity algo on the cv pixel buff
    */
    func depthSegmentatino(){
        
    }
    
   
    /*
     Based on the GSD of the phone we tell user to move camera
     www.agisoft.com/forum/index.php?topic=9132.0
     */
    func guidedPhotoLength(){
         //GSD = (DISTANCE x SENSORwidth) / (IMAGEwidth x FOCALLENGTH)
    }
    

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
        /*
         NOW
         */
        if(updateDepthLabel){
            print("we are accessing this")
            
            let scale = CGFloat(CVPixelBufferGetWidth(depthPixelBuffer)) / CGFloat(CVPixelBufferGetWidth(videoPixelBuffer))
            //why do we have the depthpoint looking like this? what is the "1 -" doing
            //we will save the images to see if they are indeed the same
            //let depthPoint = CGPoint(x: CGFloat(CVPixelBufferGetWidth(depthPixelBuffer)) - 1.0 - currentTouch!.x * scale, y: currentTouch!.y * scale)


            let cmage = CIImage(cvPixelBuffer: videoPixelBuffer)
            let context = CIContext(options: nil)
            let cgImage = context.createCGImage(cmage, from: cmage.extent)!
            let outputImage = UIImage(cgImage: cgImage, scale: 1, orientation: .right)
            //save image before manipulation
            UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil)

            visualizePointInImage(cgImage: cgImage)
            
            //let rowData = CVPixelBufferGetBaseAddress(depthPixelBuffer)! + Int(depthPoint.y) * CVPixelBufferGetBytesPerRow(depthFrame)
            
            updateDepthLabel = false
        }
        
    }
    
    func visualizePointInImage(cgImage: CGImage){
        
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
        let otherContext = CGContext(data: newBitmapData, width: pixelsWide, height: pixelsHigh, bitsPerComponent: 8,
                                     bytesPerRow: bitmapBytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
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
        
        let offsetTemp = Int(currentTouch!.y) * pixelsWide
        var offset = 4 * (offsetTemp + Int(currentTouch!.x))
        
        /*
         this funciton is not safe if you don't leave 5 pixel width from the edge
         because I don't handle for cases where we are not accessing the buffer
        */
        
        /*
         pixels 3 above and below
        */
        //offset = offset + (pixelsWide * 3 * 4)
        
        for i in -20 ..< 20 {
            //offset = offset - pixelsWide
            newDataBuf[offset + (pixelsWide * i * 4)] = 0
            newDataBuf[offset + (pixelsWide * i * 4) + 1] = 200
            newDataBuf[offset + (pixelsWide * i * 4) + 2] = 200
            newDataBuf[offset + (pixelsWide * i * 4) + 3] = 1
        }
        
        offset = 4 * (offsetTemp + Int(currentTouch!.x) - 12 )
        
        for i in -20 ..< 20{
            newDataBuf[offset + (i * 4)] = 0
            newDataBuf[offset + (i * 4) + 1] = 200
            newDataBuf[offset + (i * 4) + 2] = 200
            newDataBuf[offset + (i * 4) + 3] = 1
        }
        
        
        print("about to create visualized image")
        let outputCGImage = otherContext!.makeImage()!
        //scale 1 is the same scale as CGimage, 0 orientation is up?
        print("about to save visualized image")
        let outputImage = UIImage(cgImage: outputCGImage, scale: 1, orientation: .right)
        UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil)
        print("image should have saved")
        
        free(data)
        free(newData)
        
    }
    
    

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
                        
                        //time stamp
                        let totalSeconds = CMTimeGetSeconds(photo.timestamp)
                        print("photo was taken at ", totalSeconds)
                        print("which in a human readable is ", totalSeconds)
                        
                        //getting information about pixel format type in cg file
                        let temp = photo.cgImageRepresentation()
                        let cgim = temp!.takeUnretainedValue()//!.takeRetainedValue()
                        
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
                        
                        let avDepthData = photo.depthData
                       
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
                        
                        self.createDepthImageFromMap(avDepthData: avDepthData!)
                        
                    }
                    else {
                        print("Opus couldn't save the photo to your photo library")
                    }
                })
            }
        }
    }
        
}
