//
//  FaceDetectorCameraViewManager.swift
//  FaceDetectionApp
//
//  Created by  Gleb Volchetskiy on 11/7/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

import React

import Foundation
import UIKit

@objc(FaceDetectorCameraViewManager)
class FaceDetectorCameraViewManager: RCTViewManager {
    
    @objc
    override func view() -> UIView! {
        return FaceDetectorCameraView()
    }
    
    @objc
    func startRecording(_ node: NSNumber, args: [AnyHashable : Any], callback: @escaping RCTResponseSenderBlock) {
        DispatchQueue.main.async {
            let component = self.getFaceDetectorCameraViewInstance(node)
            component.startRecording(args, callback: callback)
        }
    }
    
    @objc
    func stopRecording(_ node: NSNumber, args: [AnyHashable : Any], callback: @escaping RCTResponseSenderBlock) {
        DispatchQueue.main.async {
            let component = self.getFaceDetectorCameraViewInstance(node)
            component.stopRecording(args, callback: callback)
        }
    }
    
    func getFaceDetectorCameraViewInstance(_ reactNode: NSNumber) -> FaceDetectorCameraView {
        return self.bridge.uiManager.view(
            forReactTag: reactNode
            ) as! FaceDetectorCameraView
    }
    
}
