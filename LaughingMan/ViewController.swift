//
//  ViewController.swift
//  LaughingMan
//
//  Created by Jonathan Ruiz on 10/8/18.
//  Copyright © 2018 Jonathan Ruiz. All rights reserved.
//

import UIKit
import ARKit
import ReplayKit


enum ContentType: Int {
    case none
    case mask
}


class ViewController: UIViewController {
    // MARK:- Properties
    let sharedRecorder = RPScreenRecorder.shared()
    private var isRecording = false
    var anchorNode: SCNNode?
    var contentTypeSelected: ContentType = .none
    var man: LaughingMan?
    var session: ARSession {
        return sceneView.session
    }
    
    
    // MARK:- Outlets
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var maskButton: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharedRecorder.delegate = self
        sceneView.delegate = self
       
        createFaceGeometry()
        
        session.delegate = self
        
        DispatchQueue.main.async {
            self.sceneView.layer.cornerRadius = 20
        }
        
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
        resetTracking()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = false
        sceneView.session.pause()
    }
    
    
    // MARK:- Button Actions
    @IBAction func didTappRefreshButton(_ sender: Any) {
        print("didTapRefresh")
        
        contentTypeSelected = .none
        resetTracking()
    }
    
    
    @IBAction func didTapMaskButton(_ sender: Any) {
        print("didTapMask")
        
        contentTypeSelected = .mask
        resetTracking()
    }
    
    
    @IBAction func didTapRecordButton(_ sender: Any) {
        print("didTapRecord")
        
        
        guard sharedRecorder.isAvailable else {
            print("Recording is not available.")
            return
        }
        
        
        if !isRecording {
            startRecording()
        } else {
            stopRecording()
        }
        
    }
    
    
    
} // end of ViewController




// MARK:- Custom Methods
private extension ViewController {
    
    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        configuration.providesAudioData = false
        
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    
    func createFaceGeometry() {
        let device = sceneView.device!
        let laughGeometry = ARSCNFaceGeometry(device: device)!
        man = LaughingMan(geometry: laughGeometry)
    }
    
    
    func setupFaceNodeContent() {
        guard let node = anchorNode else { return }
        
        node.childNodes.forEach { $0.removeFromParentNode() }
        
        switch contentTypeSelected {
        case.none: break
        case .mask: if let man = man { node.addChildNode(man) }
        }
        
    }
    
    
    
} // end of extension



// MARK:- ARSCNViewDelegate Methods Extension
extension ViewController: ARSCNViewDelegate, ARSessionDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            anchorNode = node
    }
    
    
    //load the mask properly
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            setupFaceNodeContent()
    }
   
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        switch contentTypeSelected {
        case .mask: man?.update(withFaceAnchor: faceAnchor)
        case .none: break
        }
        
    }
    
   
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("** didFailWithError")
    }
    
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("** sessionWasInterrupted")
    }
    
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("** sessionInterruptionEnded")
    }
    
    
    
}// end of ARSCNViewDelegate extension




// MARK:- ReplayKit Delegate Methods
extension ViewController: RPPreviewViewControllerDelegate, RPScreenRecorderDelegate {
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        print("previewControllerDidFinish")
        dismiss(animated: true)
    }
    
   
    func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWith previewViewController: RPPreviewViewController?, error: Error?) {
        
        guard error == nil else {
            print("There was an error recording: \(String(describing: error?.localizedDescription))")
            self.isRecording = false
            return
        }
    }
    
    
    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        recordButton.isEnabled = sharedRecorder.isAvailable
        
        if !recordButton.isEnabled {
            self.isRecording = false
        }
        
        if sharedRecorder.isAvailable {
            DispatchQueue.main.async {
                self.recordButton.setTitle("[REC]", for: .normal)
            }
        } else {
            DispatchQueue.main.async {
                self.recordButton.setTitle("[Can't Rec]", for: .normal)
            }
        }
        
    }
    
   
    private func startRecording() {
        
        
        self.sharedRecorder.isMicrophoneEnabled = true
        sharedRecorder.startRecording(handler: { error in
            guard error == nil else {
                print("Error starting the recording: \(String(describing: error?.localizedDescription))")
                return
            }
            
            print("Started Recording Successfully")
            self.isRecording = true
            
            DispatchQueue.main.async {
                self.recordButton.setTitle("[STOP]", for: .normal)
            }
            
        })
    }
    
    
    func stopRecording() {
        self.sharedRecorder.isMicrophoneEnabled = false
        
        sharedRecorder.stopRecording(handler: {
            previewViewController, error in
            guard error == nil else {
                print("Error stopping the recording: \(String(describing: error?.localizedDescription))")
                return
            }
            
            
            let alert = UIAlertController(title: "Recording Complete", message: "Do you want to preview/edit your recording or delete it?", preferredStyle: .alert)
            
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: {
                (action: UIAlertAction) in
                self.sharedRecorder.discardRecording(handler: { () -> Void in
                    print("Recording deleted")
                })
            
            })
            
            
            let editAction = UIAlertAction(title: "Edit", style: .default, handler: { (action: UIAlertAction) -> Void in
                if let unwrappedPreview = previewViewController {
                    unwrappedPreview.previewControllerDelegate = self
                    self.present(unwrappedPreview, animated: true, completion: {})
                }
            })
            
            alert.addAction(editAction)
            alert.addAction(deleteAction)
            self.present(alert, animated: true, completion: nil)
        }) //end of stopRecording closure
        
        
        self.isRecording = false
        
        DispatchQueue.main.async {
            self.recordButton.setTitle("[REC]", for: .normal)
        }
        
    }
    
    
    
} // end of ReplayKit delegate methods


