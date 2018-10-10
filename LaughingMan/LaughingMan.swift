//
//  LaughingMan.swift
//  LaughingMan
//
//  Created by Jonathan Ruiz on 10/8/18.
//  Copyright © 2018 Jonathan Ruiz. All rights reserved.
//

import ARKit
import SceneKit


class LaughingMan: SCNNode {
    
    // MARK:- Properties
    let mainNode: SCNNode
    
    init(geometry: ARSCNFaceGeometry) {
        geometry.firstMaterial!.colorBufferWriteMask = [ ]
        mainNode = SCNNode(geometry: geometry)
        mainNode.renderingOrder = -1
        
        super.init()
        self.geometry = geometry
        
        guard let url = Bundle.main.url(forResource: "laughingMan", withExtension: "scn", subdirectory: "Models.scnassets") else { fatalError("Missing Resource") }
        
        
        let node = SCNReferenceNode(url: url)!
        node.load()
        
        // configuring the node
        guard let container = node.childNode(withName: "container", recursively: true),
              let letterSpace = node.childNode(withName: "letterSpace", recursively: true),
              let textCoverBorder = node.childNode(withName: "textCoverBorder", recursively: true),
              let leftEye = node.childNode(withName: "leftEye", recursively: true),
              let rightEye = node.childNode(withName: "rightEye", recursively: true)
            else { return }
        
        
        let rotation = SCNAction.rotateBy(x: 0, y: 0, z: 1, duration: 0.55)
        // the phrase is 3DText objects that are childNodes to the letter space
        // rotating the tube after the words are embeded gives the node the laughing man signature look
        
        container.scale = SCNVector3(0.0014, 0.0014, 0.0014) //scale of laughing man
        letterSpace.runAction(SCNAction.repeatForever(rotation))
        
        if let textCoverBorder = textCoverBorder.geometry as? SCNText,
           let leftEye = leftEye.geometry as? SCNText,
           let rightEye = rightEye.geometry as? SCNText {
                textCoverBorder.flatness = 0
                leftEye.flatness = 0
                rightEye.flatness = 0
            
            //you need to set the flatness for these objects in the scenekit editor to something other than 0
            // set them to 0 in code only
            //when the node renders everything looks correct
        }
        
        addChildNode(node)
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) as not been implemented")
        
    }
    
    
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        let faceGeometry = geometry as! ARSCNFaceGeometry
        faceGeometry.update(from: anchor.geometry)
    }
    
    
    
}// end of LaughingMan
