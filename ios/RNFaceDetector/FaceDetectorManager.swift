//
//  FaceDetectorManager.swift
//  FaceDetectionApp
//
//  Created by  Gleb Volchetskiy on 11/5/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

import Foundation
import AVFoundation
import FirebaseMLVision
import React


@objc(FaceDetectorManager)
class FaceDetectorManager: NSObject {
    
    
    var recognitionQueue: DispatchQueue!
    
    var cameraView: FaceDetectorCameraView!
    
    static let configurationErrorCode = "CONFIGURATION_ERROR"
    static let configurationErrorMessage = "FaceDetector not cofigurated"
    
    static let recognitionErrorCode = "RECOGNITION_ERROR"
    static let recognitionErrorMessage = "Can't recognize face"
    
    static let landmarksTypes : [String: FaceLandmarkType] = [
        "NOSE_BASE": FaceLandmarkType.noseBase,
        "MOUTH_LEFT": FaceLandmarkType.mouthLeft,
        "MOUTH_RIGHT": FaceLandmarkType.mouthRight,
        "MOUTH_BOTTOM": FaceLandmarkType.mouthBottom,
        "LEFT_EAR": FaceLandmarkType.leftEar,
        "RIGHT_EAR": FaceLandmarkType.rightEar,
        "LEFT_EYE": FaceLandmarkType.leftEye,
        "RIGHT_EYE": FaceLandmarkType.rightEye,
        "LEFT_CHEEK": FaceLandmarkType.leftCheek,
        "RIGHT_CHEEK": FaceLandmarkType.rightCheek,
        ]
    
    static let contoursTypes : [String: FaceContourType] = [
        "ALL": FaceContourType.all,
        "FACE": FaceContourType.face,
        "LEFT_EYE": FaceContourType.leftEye,
        "LEFT_EYEBROW_BOTTOM": FaceContourType.leftEyebrowBottom,
        "LEFT_EYEBROW_TOP": FaceContourType.leftEyebrowTop,
        "RIGHT_EYE": FaceContourType.rightEye,
        "RIGHT_EYEBROW_BOTTOM": FaceContourType.rightEyebrowBottom,
        "RIGHT_EYEBROW_TOP": FaceContourType.rightEyebrowTop,
        "NOSE_BOTTOM": FaceContourType.noseBottom,
        "NOSE_BRIDGE": FaceContourType.noseBridge,
        "UPPER_LIP_TOP": FaceContourType.upperLipTop,
        "UPPER_LIP_BOTTOM": FaceContourType.upperLipBottom,
        "LOWER_LIP_TOP": FaceContourType.lowerLipTop,
        "LOWER_LIP_BOTTOM": FaceContourType.lowerLipBottom,
        ]
    
    static let perfomanceModes: [String: String] = [
        "FAST": "fast",
        "ACCURATE": "accurate",
        ]
    
    static let landmarkModes: [String: String] = [
        "NONE": "none",
        "ALL": "all",
        ]
    
    static let contourModes: [String: String] = [
        "NONE": "none",
        "ALL": "all",
        ]
    
    static let classificationModes: [String: String] = [
        "NONE": "none",
        "ALL": "all",
        ]
    
    @objc
    static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    
    var faceDetector: VisionFaceDetector?
    
    @objc
    func configurate(_ options: [String: Any]) -> Void {
        recognitionQueue = DispatchQueue(label: "recognition_session_queue")
        let faceDetectorOptions = VisionFaceDetectorOptions()
        
        if (options["performanceMode"] != nil) {
            switch options["performanceMode"] as? String {
            case FaceDetectorManager.perfomanceModes["FAST"]:
                faceDetectorOptions.performanceMode = .fast
            case FaceDetectorManager.perfomanceModes["ACCURATE"]:
                faceDetectorOptions.performanceMode = .accurate
            default: break
            }
        }
        
        if (options["landmarkMode"] != nil) {
            switch options["landmarkMode"] as? String {
            case FaceDetectorManager.landmarkModes["NONE"]:
                faceDetectorOptions.landmarkMode = .none
            case FaceDetectorManager.landmarkModes["ALL"]:
                faceDetectorOptions.landmarkMode = .all
            default: break
            }
        }
        
        if (options["contourMode"] != nil) {
            switch options["contourMode"] as? String {
            case FaceDetectorManager.contourModes["NONE"]:
                faceDetectorOptions.contourMode = .none
            case FaceDetectorManager.contourModes["ALL"]:
                faceDetectorOptions.contourMode = .all
            default: break
            }
        }
        
        if (options["classificationMode"] != nil) {
            switch options["classificationMode"] as? String {
            case FaceDetectorManager.classificationModes["NONE"]:
                faceDetectorOptions.classificationMode = .none
            case FaceDetectorManager.classificationModes["ALL"]:
                faceDetectorOptions.classificationMode = .all
            default: break
            }
        }
        
        if (options["minFaceSize"] != nil) {
            faceDetectorOptions.minFaceSize = options["minFaceSize"] as! CGFloat
        }
        
        if (options["isTrackingEnabled"] != nil) {
            faceDetectorOptions.isTrackingEnabled = options["isTrackingEnabled"] as! Bool
        }
        
        self.faceDetector = Vision.vision().faceDetector(options: faceDetectorOptions)
        
    }
    
    @objc
    func recognize(_ base64String: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        if (self.faceDetector != nil) {
            let image = VisionImage(image: self.base64ToUIImage(base64String))
            
            self.faceDetector?.process(image) { faces, error in
                guard error == nil, let faces = faces, !faces.isEmpty else {
                    reject(FaceDetectorManager.recognitionErrorCode, FaceDetectorManager.recognitionErrorMessage, error);
                    return
                }
                
                resolve(faces.map {self.visionFaceToHashable($0, false, false)})
            }
        }
        else {
            reject(FaceDetectorManager.configurationErrorCode, FaceDetectorManager.configurationErrorMessage, nil)
        }
    }
    
    
    var width = 0
    var height = 0
    var disabled = false
    
    func recognize(buffer: CMSampleBuffer, callback: @escaping ([AnyHashable : Any]) -> Void, recordingTime: Double) -> Void {
        //    recognitionQueue.async {
        if (self.faceDetector != nil && !self.disabled) {
            self.disabled = true
            
            let metadata = VisionImageMetadata()
            
            var devicePosition: AVCaptureDevice.Position = .back
            
            switch (self.cameraView.cameraType) {
            case FaceDetectorCameraView.cameraTypes["BACK"]:
                devicePosition = .back
                break
            case FaceDetectorCameraView.cameraTypes["FRONT"]:
                devicePosition = .front
                break
            case .none:
                break
            case .some(_):
                break
            }
            
            var horizontalMirrored = false
            var verticalMirrored = false
            
            metadata.orientation = VisionDetectorImageOrientation.leftTop
            
            switch (UIDevice.current.orientation) {
            case .portrait:
                if (devicePosition == .front) {
                    metadata.orientation = .leftTop
                }
                else {
                    metadata.orientation = .rightTop
                    horizontalMirrored = true
                }
            case .landscapeLeft:
                metadata.orientation = devicePosition == .front ? .bottomRight : .bottomLeft
                if (devicePosition == .front) {
                    metadata.orientation = .bottomRight
                }
                else {
                    metadata.orientation = .topLeft
                    horizontalMirrored = true
                }
            case .portraitUpsideDown:
                if (devicePosition == .front) {
                    metadata.orientation = .rightBottom
                }
                else {
                    metadata.orientation = .leftBottom
                    horizontalMirrored = true
                }
            case .landscapeRight:
                if (devicePosition == .front) {
                    metadata.orientation = .topLeft
                }
                else {
                    metadata.orientation = .bottomRight
                    horizontalMirrored = true
                }
            case .faceDown, .faceUp, .unknown:
                metadata.orientation = VisionDetectorImageOrientation.leftTop
            }
            
            if (self.width == 0 && self.height == 0) {
                let  imageBuffer = CMSampleBufferGetImageBuffer(buffer);
                // Lock the base address of the pixel buffer
                //        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
                //
                //
                //        // Get the number of bytes per row for the pixel buffer
                //        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!);
                //
                //        // Get the number of bytes per row for the pixel buffer
                //        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!);
                // Get the pixel buffer width and height
                self.width = CVPixelBufferGetWidth(imageBuffer!);
                self.height = CVPixelBufferGetHeight(imageBuffer!);
            }
            
            //        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            //          let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            //          let resizedCIImage = ciImage.applying(CGAffineTransform(scaleX: 0.5 y: 0.5))
            //
            //          let context = CIContext()
            //          if let image = context.createCGImage(resizedCIImage, from: resizedCIImage.extent) {
            //            var im = UIImage(cgImage: image)
            //          }
            //        }
            
            let image = VisionImage(buffer: buffer)
            image.metadata = metadata
            
            self.faceDetector?.process(image) { faces, error in
                guard error == nil, let faces = faces, !faces.isEmpty else {
                    self.disabled = false
                    return
                }
                
                self.disabled = false
                callback([
                    "faces": faces.map {self.visionFaceToHashable($0, horizontalMirrored, verticalMirrored)},
                    // TODO add orientation param
                    "width": self.height,
                    "height": self.width,
                    "recordingTime": recordingTime,
                    ])
            }
        }
        //    }
    }
    
    @objc
    func constantsToExport() -> [AnyHashable : Any]! {
        return [
            "OPTIONS": [
                "PERFOMANCE_MODE": FaceDetectorManager.perfomanceModes,
                "LANDMARK_MODE": FaceDetectorManager.landmarkModes,
                "CONTOUR_MODE": FaceDetectorManager.contourModes,
                "CLASSIFICATION_MODE": FaceDetectorManager.classificationModes,
            ],
            "LANDMARK": FaceDetectorManager.landmarksTypes,
            "CONTOUR": FaceDetectorManager.contoursTypes,
        ]
    }
    
    func visionFaceToHashable(_ face: VisionFace, _ horizontalMirrored: Bool, _ verticalMirrored: Bool) -> [AnyHashable : Any]! {
        var result = [AnyHashable : Any]()
        
        result["hasTrakingID"] = face.hasTrackingID
        if face.hasTrackingID {
            result["trackingID"] = face.trackingID
        }
        
        result["hasHeadEulerAngleY"] = face.hasHeadEulerAngleY
        if face.hasHeadEulerAngleY {
            // TODO add orientation param
            result["headEulerAngleY"] = horizontalMirrored ? -face.headEulerAngleY : face.headEulerAngleY
        }
        
        result["hasHeadEulerAngleZ"] = face.hasHeadEulerAngleZ
        if face.hasHeadEulerAngleZ {
            result["headEulerAngleZ"] = face.headEulerAngleZ
        }
        
        result["hasSmilingProbability"] = face.hasSmilingProbability
        if face.hasSmilingProbability {
            result["smilingProbability"] = face.smilingProbability
        }
        
        result["hasLeftEyeOpenProbability"] = face.hasLeftEyeOpenProbability
        if face.hasLeftEyeOpenProbability {
            result["leftEyeOpenProbability"] = face.leftEyeOpenProbability
        }
        
        result["hasRightEyeOpenProbability"] = face.hasRightEyeOpenProbability
        if face.hasLeftEyeOpenProbability {
            result["rightEyeOpenProbability"] = face.rightEyeOpenProbability
        }
        
        var landmarks = [AnyHashable : Any]()
        
        for case (_, let landmarkType) in FaceDetectorManager.landmarksTypes {
            if let landmark = face.landmark(ofType: landmarkType) {
                landmarks[landmarkType] = [
                    "type": landmarkType,
                    "position": self.visionPointToObject(landmark.position, horizontalMirrored, verticalMirrored)
                ]
            }
        }
        
        result["landmarks"] = landmarks
        
        var contours = [AnyHashable : Any]()
        
        for case (_, let contourType) in FaceDetectorManager.contoursTypes {
            if let contour = face.contour(ofType: contourType) {
                contours[contourType] = [
                    "type": contourType,
                    "points": contour.points.map {self.visionPointToObject($0, horizontalMirrored, verticalMirrored)}
                ]
            }
        }
        
        result["contours"] = contours
        
        return result;
    }
    
    func visionPointToObject(_ point: VisionPoint, _ horizontalMirrored: Bool, _ verticalMirrored: Bool) -> [String: NSNumber?] {
        return [
            // TODO add orientation param
            "x": horizontalMirrored ? self.height - Int(point.y) as NSNumber : point.y,
            "y": verticalMirrored ? self.width - Int(point.x) as NSNumber : point.x,
            "z": point.z
        ];
    }
    
    func base64ToUIImage(_ base64String: String?) -> UIImage{
        if (base64String?.isEmpty)! {
            return #imageLiteral(resourceName: "no_image_found")
        }else {
            // !!! Separation part is optional, depends on your Base64String !!!
            let temp = base64String?.components(separatedBy: ",")
            let dataDecoded : Data = Data(base64Encoded: temp![1], options: .ignoreUnknownCharacters)!
            let decodedimage = UIImage(data: dataDecoded)
            return decodedimage!
        }
    }
    
}
