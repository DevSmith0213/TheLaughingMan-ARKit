//
//  RearCameraViewController.swift
//  LaughingMan
//
//  Created by Jonathan Ruiz on 12/18/18.
//  Copyright © 2018 Jonathan Ruiz. All rights reserved.
//

import UIKit
import ARKit
import AVFoundation
import Vision
import SceneKit


class RearCameraViewController: UIViewController {
    // MARK:- Properties

    var session = AVCaptureSession()
    var requests = [VNRequest]()
    var mainNode: SCNNode?
    var scene2 =  ARSCNView()
    
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var rearCameraButton: UIButton!
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startLiveVideo()
        startFaceTracking()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupLaughingMan()
        
    }
    
    override func viewDidLayoutSubviews() {
        DispatchQueue.main.async {
            self.sceneView.layer.cornerRadius = 10
            self.sceneView.layer.sublayers?[0].frame = self.sceneView.bounds
            self.blurView.layer.cornerRadius = 10
            self.scene2.layer.sublayers?[0].frame = self.scene2.bounds
        }
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        scene2.session.pause()
    }
    
    
    
    
    @IBAction func frontCameraButtonPressed(_ sender: Any) {
        

    }
    
    
    
    
    
    
}// end of RearCameraViewController






extension RearCameraViewController: ARSCNViewDelegate {
    // MARK:- Custom Methods
    func startLiveVideo() {
        session.sessionPreset = AVCaptureSession.Preset.high
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        let deviceImput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self as AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        
        session.addInput(deviceImput)
        session.addOutput(deviceOutput)
        
        let imageLayer = AVCaptureVideoPreviewLayer(session: session)
        imageLayer.frame = self.view.bounds //sceneView.bounds
        imageLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        sceneView.layer.addSublayer(imageLayer)
        
        session.startRunning()
    }
    
    
    func setupLaughingMan() {
        sceneView.delegate = self
        scene2.delegate = self
        scene2.isHidden = true
        
        DispatchQueue.main.async {
            guard let scene = SCNScene(named: "Models.scnassets/laughingMan.scn"),
                let node = scene.rootNode.childNode(withName: "container", recursively: true),
                let letterSpace = node.childNode(withName: "letterSpace", recursively: true)
                else { return }
            
            node.position = SCNVector3(0, 0, -1) //-0.5
            node.scale = SCNVector3(0.0050, 0.0050, 0.0050)
            
            
            let rotation = SCNAction.rotateBy(x: 0, y: 0, z: 1, duration: 1.23) //1
            letterSpace.runAction(SCNAction.repeatForever(rotation))
            self.mainNode = node
        }
        
    }
    
    
    func startFaceTracking() {
        let faceRequest = VNDetectFaceRectanglesRequest(completionHandler: self.detectFaceHandler)
        self.requests = [faceRequest]
    }
    
    
    func highlightFace(box: VNFaceObservation) {
        scene2.isHidden = false
        guard let mainNode = mainNode else { return }
        
        DispatchQueue.main.async {
            let width = self.sceneView.frame.size.width * box.boundingBox.width
            let height = self.sceneView.frame.size.height * box.boundingBox.height
            let xCord = self.sceneView.frame.size.width * box.boundingBox.origin.x
            let yCord = self.sceneView.frame.size.height * (1 - box.boundingBox.origin.y) - height
            
            
            
            self.scene2.frame = CGRect(x: xCord - 35, y: yCord - 35, width: width + 60, height: height + 60)
            
            self.scene2.backgroundColor = UIColor.clear
            self.scene2.scene.rootNode.addChildNode(mainNode)
            self.sceneView.addSubview(self.scene2)
            
            
            
        }// end of DispatchQueue
        
        
        
        
    }// end of highlightFace
    
    
    func detectFaceHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else { return }
        
        let result = observations.map({$0 as? VNFaceObservation})
        
        DispatchQueue.main.async {
            self.sceneView.layer.sublayers?.removeSubrange(1...)
            for region in result {
                guard let rg = region else {
                    continue
                }
                
                self.highlightFace(box: rg)
                
            }
        }
    }
    
    
    
    
    
    
    
    
} //end of ViewController








extension RearCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var requestOptions: [VNImageOption: Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
        
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
        
    }
    
}  // end of extension



