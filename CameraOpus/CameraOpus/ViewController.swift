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
import GLKit


/*
 General Info learnt
 
 **************************
 
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
 
 **************************
 
 AR:
 
 arkitcapture is about 2megapixels
 
 keep in mind cgpoint y seems to correspond to pixel width
 it seems to be the origin of cgimage is top right, not top left
 while the origin of cgpoint is top right
 
 **************************
 
 **************************
 
 ACCEL:
 
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
 
 **************************
 
 **************************
 
 STORYBOARD
 
 photoPreviewImageView: h: 500 x w: 375
 
 */

/*

FLOW
 
    - when a user touches the video layer
        - the flow is capturePhoto is called, an avphotocapture session is created and captures the image and sends it to the photoOutput function with the capture3 flag on. One image is automatically saved here, then visualizeImage is called, and one image is saved there, then createDepthMap is called saving another image
        - we also start add the arrow to the view in the photoOutput method (in the capture3 flag if statement)
        - this is triggered by the addRotationAnimation method which calls the timer method
 
 
    - After the CL location manager is set up any movement changing angle triggers locationManager automatically
        - locationManager initially has the flag getInitialDirection on
            - with this flag we find the initial directino then turn the compass flag on
        - with the compassOn flag we start all the functionality of moving the arrow and taking pictures automatically in the moveArrow function and takeGuidedImage functions respectively
            - the takeGuidedImage checks if an image is taken at the right locations, and increments the global imagesTaken counter to keep track (efficiently)
            - when the imagesTaken is full we alert user and refresh the view and reset flags
 
*/
 
/*
 
 strategy
 - create a frame in the image about 2/3 of the photo layer, inbetween which we ask user to position object
 - ask user to tap center of object (this gives us the distance) and allows us to calculate a radius for how much translation and how many images we want
 - As user moves around we show a progress bar
 - We provide feedback on how many more images are needed, and speed user should be moving vs is currently

 - we should consider obfuscating code using this scheme en.wikipedia.org/wiki/Amit_Sahai
 
 */

/*
 CURRENT STACK
 
 To Do
 
 - speed up photo Output function (during guidedImage) to see if there is difference
 - - there doesn't seem to be much of a difference, ie the image taking process seems to be causing the pause
 - - try capturing with another photo Settings obj eg get rid of depth delivery and see what happens
 - - asked question on stack overflow
 
 - add new viewcontroller and new screens
 - add bottom menu to screen so that we can change between views
 (tabviewcontroller)
 - stackoverflow.com/questions/26850411/how-add-tabs-programmatically-in-uitabbarcontroller-with-swift
 
 - stop crash when all photos are taken - done
 - reduce videolayer lag when taking a photo -
 - speed up loading - done
    - got to figure out where to instantiate setUpMotionManager()
 - create 2nd view showing the 3d model
 
 - take images automatically as user moves - done
 - when enough images alert the user get ready to:
        - refresh the view
        - send images to server
 - create refresh view method - done
 - create send images to server method - done
 - multiple arrows and rotation animations are appearing as images are taken why? - done (should be fixed)
 
 
 - get back 3d model files
 - show 3d model
 
 - We can show these files with the scenekit framework (rubygarage.org/blog/create-augmented-reality-app-for-ios-11)
 "ARKit SceneKit View supports several file formats, namely .dae (digital asset exchange), .abc (alembic), and .scn (SceneKit archive)."
 To add it to your application, create an Objects folder in Xcode and place the file in it. The file is still in .dae format, so use the Editor Convert tool to transform it into a .scn file. Keep in mind that the initial .dae file mustn’t be replaced.
  a 3D object model must be a subclass of SCNNode, so we need to create a new class (we’ve called it Drone, though you may call it whatever you like) and load the initial file containing the object (in our case, Drone.scn).
 
 
     func loadModel() {
         guard let virtualObjectScene = SCNScene(named: "Drone.scn") else { return }
         let wrapperNode = SCNNode()
         for child in virtualObjectScene.rootNode.childNodes {
         wrapperNode.addChildNode(child)
         }
         addChildNode(wrapperNode)
     }
 
 
 
 - add arrow back ground
    - self.xxx = UIImageView(image: UIImage(named: "arrowbackground")!)
    - self.xxx!.frame = CGRect(x: 0, y: 415, width: 375, height: 75)
 - bug when person presses twice, we get two arrows that should not happen
 
 - we will need to look into the timing of cllocation updates too
 - arrow should move up and down too based on movement too
 - rewrite pixel rectification with cvpixel
 buffers, and check against the cgimage implementation (this is needed because the co-ordinate system of cgimage seems to be different to cg point)
 - consider rewriting visualizePoint function with cvpixel buffers instead (so we can avoid co-ordinate system troubles)
 - get depth value in human readable format
 
 
Nice to Haves
 
 - speed up loading (you can apperently do some of this by moving form viewDidLoad to viewWillAppear)
 stackoverflow.com/questions/21949080/camera-feed-slow-to-load-with-avcapturesession-on-ios-how-can-i-speed-it-up
 -- Things learnt
 The big time sync is setting up the motion manager
 Moving
    setUpMotionManager()
    to under viewWillAppear led to almost all of the performance gain
 Moving some things under the dispatch async took a little time off
 
 
 - a method that checks if the user's camera is stable (get rid of the alert when stable and take photo)
 - consider also writing function that calculates if the change in depth is smooth over time (ie what is being viewed t_1 vs t_2) The reasoning behind this is that we might expect that if a user keeps the camera aimed at the right place and moves around, it would be smooth, but if the user simply points the camera at something else, we will see discontinuities
    - this function would take in all depth values in a scene (probably those inside the frame)
    - it is to be determined whether the simple average would work ie whether f : r^~300000 --> 1 makes sense
    - maybe we compare average and variance? or maybe a few other moments of the data set vis a vis generalized method of moments?
 - timstamps of image taking
 - accelerometer approximations of current speed
 - optimisation of app load time
 
 ** really unneccesary but would be cool **
 - we should consider obfuscating code using this scheme en.wikipedia.org/wiki/Amit_Sahai
 
 Keep in mind
 - the get depth point will have the same logic as the depth rectifiication function, but will only 'rectify' a points worth of data - done?
 - right now when you touch the video previewLayer, you save 3 photos
 
 
    Flags
 
 - right not put devMotionFlag = 0
 
 - right now devMotionFlag is on and devEffectFlag is off (both cannot be on at the same time becuase they both attempt to turn on the accelerometer)
 - additionally motionInterval must have some reasonable value
 
 **NB**
 - we use setDefaultLabelText as a user input way of resetting flags for testing purposes
 
 
 Done
 - completing depth rectification function - done
 - working on depth segmentiontation algo next
 - write function that makes log of acelerometer data - done
 - having some issue with OperationQueue.main.addOperation not getting in there - done
 
 - update imagemap to be int bool - done
 - round degrees in hashmap lookups - done
 - allow imagemap lookup to return if the value is within x degrees of true value - done
 
 - creating intial direction reading by taking average of last 10 readings - done
 - creating arrow movement method based on fraction of direction moved - done
 - test that this works corredtly on real world data - done
 
 ** this is solved by gsd ** --> gsd lets us determine max / min distance needed for specific resolution
 - How do we determine the optimal distance from which to take photo?
 - We will need to guess size of image
    - to do that we will use some depth segmentation algo
    - no we don't
 - Is there some mathemtics we can do based on the object prelim size guess?
 
 
 Backburner ideas
 - we could start an ar scene with arkit and save information about the enviroment
 - then once a user touches the object we turn off the ar scene and go back to avcapture
 - then once the image taking process has started, we systematically switch to arkit to check how much distance has been traversed
 
 
 Resources:
 - git.kabellmunk.dk/talks/into-the-deep/blob/master/IntoTheDeep/Models/Slides.swift
 
 
 - github.com/ejeinc/MetalScope
 
 */


class ViewController: UIViewController, UITextFieldDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureDataOutputSynchronizerDelegate, CLLocationManagerDelegate {
    
//    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
//
//    }
    
    
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
    var hasAnimationRun = false
    var arrowView: UIImageView?
    let motionInterval = 0.3
    
    //location and magentometer
    let locationManager = CLLocationManager()
    var compassOn = false
    var getInitialDirection = false
    var initialDirection : Double?
    var currentDirection: Double?
    var hasInitialDirectionSet = false
    
    var window : [Double] = []
    var windowFull = false
    
    //image tracker
    // this will keep track of the number of the images we want
    // each Double corresponds to the angle at which we want an image
    // the bool will track if an image was taken at at the angle
    //eg [30: false, 60: false]
    var imageMap = [Int : Bool]()
    // this variable sets the frequency with which to take images
    // for now it will be in the addRotationAnimation function but this should be dynamically set based on image conditions
    // we can create that method later
    var imageInterval: Int?
    var imagesTaken = 0
    
    
    
    // a flag set in guided to stop photoOutput from doing too much
    var guidedFlag = false


    //temp variables
    var accelcount = 0
    var devCount = 0
    var compassCount = 0
    var initDirCount = 0
    var moveArrowCount = 0
    
    //MARK: Properties
    @IBOutlet weak var textLabel: UILabel!
    
    @IBOutlet weak var textInput: UITextField!
    
    //@IBOutlet weak var previewView: PreviewView!
    
    @IBOutlet weak var photoPreviewImageView: UIImageView!
    
    //var outputSynchronizer: AVCaptureDataOutputSynchronizer?
    
    private let dataOutputQueue = DispatchQueue(label: "video data queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    // stackoverflow.com/questions/37869963/how-to-use-avcapturephotooutput
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        print("in file Output2")
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
        
        let gravity = data.gravity
        let xa = data.userAcceleration.x
        let ya = data.userAcceleration.y
        let za = data.userAcceleration.z
        
        if (devCount < 5){
            print("from output dev motion")
            print("teh x accel is ", xa)
            print("teh y accel is ", ya)
            print("teh z accel is ", za)
            print(" ")
            devCount = devCount + 1
        }
        
    }
    
    /*
     * returns difference between start and end angle and
     */
    func getShortestDistance(start: Double ,end: Double) -> Double {
        
        var dif : Double?
        if (end > start) {
            /*
             eg
             
             start = 10
             end = 350
             
             start = 340
             end = 350
             */
            if (360-end+start) < (end-start) {
                // (360-end+start!) case corresponds to 360 being in between start and end
                dif = -1 * ((360-end+start) )
            } else {
                dif = ((end-start) )
            }
        }
        else {
            /*
             eg
             start = 350
             end = 10
             
             start = 350
             end = 340
             */
            if (360-start+end) < (start-end) {
                dif = ((360-start+end) )
            } else {
                dif = -1 * ((start-end) )
            }
        }
        return dif!
    }
    
    /*
        recursive implementation but should only run count times
    */
    func weightedUpdate(start: Double, dif: Double, count: Int) -> Double{
        
        print("WU we had start of ", start)
        print("WU we had dif of ", dif)
        
        var newValue = start + dif
        if(newValue > 360){
            newValue = newValue.truncatingRemainder(dividingBy: 360)
        }
        if(newValue < 0){
            newValue = newValue + 360
        }
        if(count > 0){
            //we divide so that the dif is smaller for each recursive call, this means when the count is large the dif will less strongly affect the final number
            let newDif = (getShortestDistance(start: start, end: newValue) / Double (count) )
            return weightedUpdate(start: newValue, dif: newDif, count: count - 1)
        }
        print("WU we calculated the value @", newValue)
        return newValue
    }
    
    /*
     checks if value is in interval and if so has not yet triggered a photo
    */
    
    func checkInterval(radius: Int, candidate: Double) -> (found: Bool ,imNumber: Int){
        let candid = Int(floor(candidate))
        var counter = candid - radius
        while (counter < candid + radius){
            //needs to be if let, not if (because we are searching not nil, not true)
            if let val = imageMap[counter] {
                
                //the value is false ie we haven't taken a picture here yet
                if(!val){
                    print("found interval @ ", counter)
                    return (found: true, imNumber: counter)
                }
            }
            counter = counter + 1
        }
        return (found: false, imNumber: -1)
    }
    
    /*
     this function assumes we are moving clockwise
     checks the dif between the initial direction and the current angle
    */
    func takeGuidedImage(angle: Double){
        var dif = getShortestDistance(start: initialDirection!, end: angle)
        // gets the clockwise number for anticlockwise values (since getShortestDistance is direction invariant)
        if (dif < 0){
            dif = 360 + dif
        }
        //we allow 2 degrees of radius (we may have to increase this)
        print("calling checkInterval with ", dif)
        let (found, imNumber) = checkInterval (radius: 2, candidate: dif)
        if(found){
            imageMap[imNumber] = true
            
            //flags set for photoOutput function
            capturePhotoFlag3 = false
            capturePhotoFlag1 = false
            //getting photo object ready
            var photoSettings = AVCapturePhotoSettings()
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            //photoSettings.isDepthDataDeliveryEnabled = photoOutput!.isDepthDataDeliverySupported
            
            // pop up saying hold still
            holdStill(time: 2.0)
            
            /*
             Taking photo and also setting flag which should send the image to the server
            */
            print("taking photo from within guided image")
            guidedFlag = true
            photoOutput!.capturePhoto(with: photoSettings, delegate: self)
            
            // take photo
            imagesTaken = imagesTaken + 1
            if (imagesTaken == (360/imageInterval!)){
                resetView()
            }
        }
        
    }
    
    func sendImages(){
        
    }
    
    /*
     We set up the view again without the arrow
     we reset the flags
    */
    func resetView(){
        print("In resetView")
        
        if tempView != nil {
            DispatchQueue.main.async {
                // Dismiss the view from here
                self.tempView!.removeFromSuperview()
            }
        }
        
       
//        if setUpView != nil {
//            setUpView!.removeFromSuperview()
//        }
        
        /*
         setting flags to original values
        */
        
        /*
         * we reset these all in the main event thread for atomicity
        */
        
        DispatchQueue.main.async {
            self.capturePhotoFlag1 = true
            self.capturePhotoFlag2 = false
            self.capturePhotoFlag3 = false
            
            self.hasAnimationRun = false
            self.guidedFlag = false
            self.imagesTaken = 0
            
            self.compassOn = false
            self.getInitialDirection = false
            //initialDirection : Double?
            //currentDirection: Double?
            self.hasInitialDirectionSet = false
            
            self.windowFull = false
            self.window.removeAll()
            
            self.imageMap.removeAll()
        }
        
    }
    
    func holdStill(time: Double){
        
        let alert = UIAlertController(title: "Alert", message: "capturing photo keep still please :)", preferredStyle: .alert)
        
        DispatchQueue.main.async {
            self.present(alert, animated: false, completion: nil)
        }
        
        // change to desired number of seconds (in this case 5 seconds)
        let when = DispatchTime.now() + time
        DispatchQueue.main.asyncAfter(deadline: when){
            // your code with delay
            
            //I have this print statement to figure out if this code is blocking or not ie is the image capture happening simulataneously or sequentially
            //we want simulataneously
            print("about to dismiss alert")
            alert.dismiss(animated: false, completion: nil)
        }
        
    }
    
    
    /*
     We will need to get the value of the heading continuosly and send to the arrow
     */
    func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        //for visualization purposes
        if(compassCount < 5){
            print("the compass")
            print (heading.magneticHeading)
            compassCount = compassCount + 1
        }
        //we pass the magnetic values back to the animation
        //IIII
        
        if(getInitialDirection){
            //we take a lazy average of the last 5 readings to increase accuracy
            if(initDirCount == 0){
                initialDirection = heading.magneticHeading
                initDirCount = initDirCount + 1
            }
            /*
             for debugging purposes we have the '== 5' case
            */
            if(initDirCount == 5){
                print("the initial direction has been set its ", initialDirection)
                hasInitialDirectionSet = true
                currentDirection = initialDirection!
            }
            if((initDirCount < 5)&&(initDirCount > 0)){
                print("calculating initial direction")
                print("reading is ", heading.magneticHeading)
                
                //this check is neccessary if the user is close  360 or 0 since slight moves can lead to pathological windows eg
                // 358 358 358 1 1
                print("about to call weightedUpdate with args ", initDirCount)
                var dif = getShortestDistance(start: initialDirection!, end: heading.magneticHeading)
                //we have this line in the beginning so that it does not revert to the new reading automatically
                dif = dif / 2
                initialDirection = weightedUpdate(start: initialDirection!, dif: dif, count: initDirCount)

                initDirCount = initDirCount + 1
            }
            else{
                getInitialDirection = false
            }
        }
        /*
         * once the intial direction has been set we can start moving the arrow relative to that direction
         */
        if(compassOn){
            // we will want to take the rolling average of the last x values to make the movement smooth
            if(windowFull){
                var newDir = window.first
                var counter = 0
                for val in window {
                    let dify = getShortestDistance(start: newDir!, end: val)
                    newDir = weightedUpdate(start: newDir!, dif: dify, count: counter)
                    //newDir = newDir + (0.2 * val)
                    counter = counter + 1
                }
                //print(" current direction is")
                //this function determines whether we should take an image
                takeGuidedImage(angle: newDir!)
                
                moveArrow(angle: newDir!)
                //update the array to get the new value
                window.removeFirst()
                window.append(heading.magneticHeading)
            }
                /* 2 cases:
                    i) window is either not full
                    ii) has just become full and the bool is not yet set
                 */
            else{
                // we specify the size of the window here -
                if (window.count < 5){
                    window.append(heading.magneticHeading)
                }
                else{
                    windowFull = true
                }
            }
        }
        
    }
    
    /*
     consider also writing function that calculates if the change in depth is smooth over time (ie what is being viewed t_1 vs t_2) The reasoning behind this is that we might expect that if a user keeps the camera aimed at the right place and moves around, it would be smooth, but if the user simply points the camera at something else, we will see discontinuities
    */
    
    func moveArrow(angle: CLLocationDirection){
        // if the initial direction has not been set we cannot calculate change and so we should not progress
        if(!hasInitialDirectionSet){
            return
        }
        //inital direction has been set we can proceed
        //let initAngle = GLKMathDegreesToRadians(Float(initialDirection!))
        //let newAngle = GLKMathDegreesToRadians(Float(angle))
        
        /*
         2 cases
            ending direction is greater than current direction
            vice versa
            2 further cases
                case 1 person moves clockwise
                case 2 person moves anticlockwise
        */
        
        /*
         * we divide frac by 360 at the end to handle 0
        */
        
        var frac : Double?
        if (angle > currentDirection!) {
            /*
             eg
             
             start = 10
             end = 350
             
             start = 340
             end = 350
             */
            if (360-angle+currentDirection!) < (angle-currentDirection!) {
                // (360-angle+currentDirection!) case corresponds to 360 being in between start and end
                frac = -1 * ((360-angle+currentDirection!) / 360.0)
            } else {
                frac = ((angle-currentDirection!) / 360.0)
            }
        }
        else {
            /*
             eg
             start = 350
             end = 10
             
             start = 350
             end = 340
            */
            if (360-currentDirection!+angle) < (currentDirection!-angle) {
                frac = ((360-currentDirection!+angle) / 360.0)
            } else {
                frac = -1 * ((currentDirection!-angle) / 360.0)
            }
        }
        
        /*
         These statements are simply there for visualisation and debugging purposesd, remove at a later moment in time
        */
        if(moveArrowCount % 25 == 0){
            print("the cur angle is ",currentDirection!)
            print("the new angle is ", angle)
            print("we should move by ", frac)
        }
        if(moveArrowCount == 200){
            moveArrowCount = 0
        }
        if((angle > 350)&&(angle < 5)){
            print("sensitivity analysis")
            print("the cur angle is ",currentDirection!)
            print("the new angle is ", angle)
            print("we should move by ", frac)
        }
        /*
         this is the temp variable which is part of debugging
        */
        moveArrowCount = moveArrowCount + 1
        
        /*
         speed estimate is r theta (check this)
        */
        //var speed
        
        /*
         this should transform the view
         we need to determine what I should be multiplying the frac with
         285 = 375 - 90 (width of arrow), ie scaling by the width of the screen
        */
        currentDirection! = angle
        tempView!.transform = tempView!.transform.translatedBy(x: CGFloat(frac! * 285.0 ), y: CGFloat(0))
        //tempView!.frame = CGRectMake(xPosition, yPosition, height, width)
    }
    
    override func viewWillAppear(_ animated: Bool) {
    //func viewWillAppear() {
        print("in view will appear")
        do{
            //setUpMotionManager()
            setUpCompass()

        }
        catch{
            print("there must have been an error in viewWillAppear")
            return
        }
    }
    
    func setUpMotionManager(){
        
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
        
        devMotionFlag = 0
        
        if(devMotionFlag == 1){
            print("dev flag is on")
            motionManager?.deviceMotionUpdateInterval = motionInterval
            motionManager!.startDeviceMotionUpdates(
                to: OperationQueue.current!,
                withHandler: {(data, error) in
                    self.outputDevMotionData(data: data!)
            })
        }
        
    }
    
    func setUpCompass(){
        /*
         setting up location stuff
         the internal compass
         */
        if (CLLocationManager.headingAvailable()) {
            locationManager.headingFilter = 1
            locationManager.startUpdatingHeading()
            locationManager.delegate = self
        }
        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        textInput.delegate = self
        print("in view did load")
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
                }
                
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
                videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspect
                videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                photoPreviewImageView.layer.addSublayer(videoPreviewLayer!)
                print("seems like we have added a subLayer")
                
                let pressGestureDepth = UILongPressGestureRecognizer(target: self, action: #selector(getDepthTouch) )
                pressGestureDepth.minimumPressDuration = 1.00
                //pressGestureDepth.cancelsTouchesInView = false
                print("about to add gesture recog")
                photoPreviewImageView.isUserInteractionEnabled = true
                photoPreviewImageView.addGestureRecognizer(pressGestureDepth)
                
                //session.commitConfiguration()
                
                DispatchQueue.global(qos: .userInitiated).async { //[weak self] in
                    self.session.startRunning()
                
                }
            
            let on = false
            
            if (on){
                    
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
                        DispatchQueue.main.async {
                            self.photoPreviewImageView.addSubview(imageView)
                        }
                        
                    }
                    
                    
//                    DispatchQueue.global(qos: .userInitiated).async { //[weak self] in
//                        self.session.startRunning()
//
//                    }
                
                    //session.startRunning()
                    print("session is running?")
                }
            }
        }
        catch{
            print("there must have been an error in viewDidLoad")
            return
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("in view did appear")
        super.viewDidAppear(animated)
        //this line is of immense importance without it the video feed will not show
        videoPreviewLayer!.frame = photoPreviewImageView.bounds
        
        if(focusFlag){
            print("in focus")
            layer = UIView()
            var im = UIImage(named: "focus")//?.cgImage
            let imageView = UIImageView(image: im!)
            imageView.frame = CGRect(x: 62.5, y: 84, width: 250, height: 333)
            print("about to add focus frame")
            DispatchQueue.main.async {
                self.photoPreviewImageView.addSubview(imageView)
            }
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
                
                if(gyroFlag == 1){
                    //motionManager!.stopGyroUpdates()
                    print("stopping gyro")
                }
                
            }
            catch{
                print("something wrong with capture")
            }
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
        moveArrowCount = 0
        
        var testAlert = false
        //testing alers
        if(testAlert){
            let alert = UIAlertController(title: "Alert", message: "Message", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            
            // change to desired number of seconds (in this case 5 seconds)
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when){
                // your code with delay
                alert.dismiss(animated: true, completion: nil)
            }
        }
        
        var resetTest = true
        
        if(resetTest){
            resetView()
        }
        
        

        
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
        
        /*
         this makes sure the animation cannot be run more than once per successful scan
        */
        if(hasAnimationRun){
            return
        }
        hasAnimationRun = true
        
        print("*&*&")
        print("in add rotation")
        
        //?.cgImage
        //print("image height is ", im?.height)
        //print("image width is ", im?.width)
        
        //set the number of images we want to take
        imageInterval = 30
        var i = 0
        while(i <= 360){
            imageMap[i] = false
            i = i + imageInterval!
        }
        
        DispatchQueue.main.async {
            // view manipulation here so it happens with main thread.
            
            self.tempView = UIImageView(image: UIImage(named: "move")!)
            self.tempView!.frame = CGRect(x: 160, y: 45, width: 90, height: 30)
            //tempView.addTag
            
            self.photoPreviewImageView.addSubview(self.tempView!)
            
            self.textLabel.text = "While keeping the object in frame slowly walk around. Please maintain the same distance"
            
            var timer = Timer.scheduledTimer(timeInterval: TimeInterval(0.5), target: self, selector: "timeExpired", userInfo: nil, repeats: false)
        }
        
    }
    /*
     * Important that we have @obj c because this function comes from a selector
    */
    @objc func timeExpired() {
        print("time to remove the animation")
        
        var uiEffectFlag = false
        var devEffectFlag = false
        

        
        DispatchQueue.main.async {
            
            if self.tempView != nil { // Dismiss the view from here
                self.tempView!.removeFromSuperview()
            }
            
            let setUpView = UIImageView(image: UIImage(named: "arowbackground"))
            setUpView.frame = CGRect(x: 0, y: 415, width: 375, height: 75)
            setUpView.alpha = 0.5
            self.photoPreviewImageView.addSubview(setUpView)
            
            self.tempView = UIImageView(image: UIImage(named: "arrow")!)
            self.tempView!.frame = CGRect(x: 0, y: 430, width: 90, height: 45)
            self.tempView?.alpha = 0.5
            
            if(uiEffectFlag){
                let min = CGFloat(-100)
                let max = CGFloat()
                
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
            
            self.compassOn = true
            self.getInitialDirection = true
            
            // call function that polls direction data for arrow animation
            /*
             * we will need to eventually move more functionality away into helper functions like this one below.
             * time expired is getting too bloated and is mutating beyond its initial intentions
            */
            self.pollDirection()
            
            /*
             dev motion option
            */
            var xspeed = 0.0
            var yspeed = 0.0
            
            var devMotionCheck = 0
            
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
    
    func pollDirection(){
        
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
    
    func createBody(parameters: [String: String],
                    boundary: String,
                    data: Data,
                    mimeType: String,
                    filename: String) -> Data {
        let body = NSMutableData()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        body.appendString("--".appending(boundary.appending("--")))
        
        return body as Data
    }
    
    
    /*
     Mo look here
    */
    func sendImageToServer(photo: AVCapturePhoto){
        var r  = URLRequest(url: URL(string: "http://18.206.164.104/photo")!)
        r.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        r.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
        //let image = photo.cgImageRepresentation() as! CGImage
        let image = photo.cgImageRepresentation()
        let im = image!.takeUnretainedValue()
        let uimg = UIImage(cgImage: im)
        let data = uimg.jpegData(compressionQuality: 1)
        
        r.httpBody = createBody(parameters: [:],
                                boundary: boundary,
                                data: data ?? Data.init(),
                                mimeType: "image/jpg",
                                filename: "hello.jpg")
        
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
    
    func goTo3DViewer(){
        if let dViewController = ThreeDFileViewController.storyboardInstance(){
            
            // initialize all your class properties
            // homeViewController.property1 = …
            // homeViewController.property2 = …
            
            // either push or present the nextViewController,
            // depending on your navigation structure
            
            //option 1 present
            present(dViewController, animated: true, completion: nil)
            
            //option 2 push
            //navigationController?.pushViewController(nextViewController,
            //animated: true)
            
        }
    }
    
    /*
     workspace code
    */
    

}

extension ViewController: AVCapturePhotoCaptureDelegate {
    
    //The function that is called after the image is taken to handle the photo
    //REAL DEAL
    
    
    /*
     * added a speed test if statement to see how long photoOutput takes
     * this will need to be changed out
     * Im thinkging of taking one of the captureflag statements and the guidedimage statement out of the php.save image part
    */
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        //var photoData: Data?
        
        print("in didFinishProcessingPhoto")
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            print("we seem to be error free")
            //photoData = photo.fileDataRepresentation()
            
            var speedTest = false
            if(speedTest){
                PHPhotoLibrary.requestAuthorization { status in
                    guard status == .authorized else { return }
                    PHPhotoLibrary.shared().performChanges({
                        // Add the captured photo's file data as the main resource for the Photos asset.
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .photo, data: photo.fileDataRepresentation()!, options: nil)
                    }, completionHandler: { success, error in
                        if success{
                            print("saved image to library")
                            
                            if(self.guidedFlag){
                                print("should have just saved guided image ")
                                
                                self.sendImageToServer( photo :photo)
                                
                                self.guidedFlag = false
                                return
                            }
                            
                            //we want these variables to have greater scope so they are out of the capturePhotoFlag1 statement but we don't want to initialize if we are just using guided images EDIT ended up putting them in each if statemnt for the time being
                            
                            //let avDepthData : AVDepthData?
                            //let cgim : CGImage
                            
                            
                            
                            //time stamp
                            if(self.capturePhotoFlag1){
                                
                                let avDepthData = photo.depthData
                                let temp = photo.cgImageRepresentation()
                                let cgim = temp!.takeUnretainedValue()//!.takeRetainedValue()
                                
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
                                
                                let avDepthData = photo.depthData
                                let temp = photo.cgImageRepresentation()
                                let cgim = temp!.takeUnretainedValue()//!.takeRetainedValue()
                                
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
            
            var rotationTest = true
            if(rotationTest){
                
                self.addRotationAnimation()
            }
            

        }
    }
        
}

extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}
