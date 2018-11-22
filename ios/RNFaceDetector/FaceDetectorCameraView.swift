//
//  FaceDetectorCameraView.swift
//  FaceDetectionApp
//
//  Created by  Gleb Volchetskiy on 11/7/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

import React

import UIKit
import AVFoundation
import AssetsLibrary

class FaceDetectorCameraView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    static let cameraTypes: [String: String] = [
        "BACK": "back",
        "FRONT": "front",
        ]
    
    var faceDetectorManager: FaceDetectorManager!
    
    var session: AVCaptureSession!
    var sessionQueue: DispatchQueue!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    var fileManager: FileManager
    
    private var _cameraType = AVCaptureDevice.Position.front
    
    @objc
    var options: [String: Any] = [:] {
        didSet {
            if (faceDetectorManager != nil) {
                faceDetectorManager.configurate(options)
            }
        }
    }
    
    @objc
    var cameraType = FaceDetectorCameraView.cameraTypes["BACK"] {
        didSet {
            if (
                cameraType == FaceDetectorCameraView.cameraTypes["BACK"] &&
                    _cameraType == AVCaptureDevice.Position.front
                    ||
                    cameraType == FaceDetectorCameraView.cameraTypes["FRONT"] &&
                    _cameraType == AVCaptureDevice.Position.back
                ) {
                switch cameraType {
                case FaceDetectorCameraView.cameraTypes["BACK"]:
                    _cameraType = AVCaptureDevice.Position.back
                case FaceDetectorCameraView.cameraTypes["FRONT"]:
                    _cameraType = AVCaptureDevice.Position.front
                default: return
                }
                setup()
            }
        }
    }
    
    @objc var onFacesDetected: RCTDirectEventBlock?
    
    override init(frame: CGRect) {
        self.fileManager = FileManager()
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var outputFileUrl: URL!
    var videoWriterInput: AVAssetWriterInput!
    var audioWriterInput: AVAssetWriterInput!
    var assetWriter: AVAssetWriter!
    var isRecordingWritingStarted = false;
    var isRecordingStarted = false;
    var isRecordingSessionStarted = false;
    
    func setup() -> Void {
        
        if (self.faceDetectorManager == nil) {
            self.faceDetectorManager = FaceDetectorManager()
            self.faceDetectorManager.cameraView = self
            self.faceDetectorManager.configurate(self.options)
        }
        
        if (self.session != nil) {
            self.session.stopRunning()
            self.videoPreviewLayer.removeFromSuperlayer()
        }
        
        self.session = AVCaptureSession();
        self.session.sessionPreset = AVCaptureSessionPreset1280x720
        self.sessionQueue = DispatchQueue(label: "camera_session_queue");
        
        guard let cameraDevice = self.selectCaptureDevice(_cameraType)
            else {
                print("Unable to access camera")
                return
        }
        
        do {
            // camera setup
            let cameraInput = try AVCaptureDeviceInput(device: cameraDevice)
            let videoOutput = AVCaptureVideoDataOutput()
            
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA
            ]
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            
            //audio setup
            let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            
            let audioOutput = AVCaptureAudioDataOutput()
            audioOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            
            var videoPreviewOrientation = AVCaptureVideoOrientation.portrait
            
            //TODO: add orientation param
            //      switch (UIDevice.current.orientation) {
            //      case .portrait:
            //        videoPreviewOrientation = AVCaptureVideoOrientation.portrait
            //        break
            //      case .portraitUpsideDown:
            //        videoPreviewOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            //        break
            //      case .landscapeLeft:
            //        if (self._cameraType == .front) {
            //          videoPreviewOrientation = AVCaptureVideoOrientation.landscapeLeft
            //        } else {
            //          videoPreviewOrientation = AVCaptureVideoOrientation.landscapeRight
            //        }
            //        break
            //      case .landscapeRight:
            //        if (self._cameraType == .front) {
            //          videoPreviewOrientation = AVCaptureVideoOrientation.landscapeRight
            //        } else {
            //          videoPreviewOrientation = AVCaptureVideoOrientation.landscapeLeft
            //        }
            //        break
            //      case .faceUp:
            //        break
            //      case .faceDown:
            //        break
            //      case .unknown:
            //        break
            //      }
            
            if (
                    session.canAddInput(cameraInput) &&
                    session.canAddInput(audioInput) &&
                    session.canAddOutput(videoOutput) &&
                    session.canAddOutput(audioOutput)
                ) {
                session.addInput(cameraInput)
                session.addInput(audioInput)
                
                session.addOutput(videoOutput)
                session.addOutput(audioOutput)
                
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
                
                videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect
                
                videoPreviewLayer?.connection?.videoOrientation = videoPreviewOrientation
                self.layer.addSublayer(videoPreviewLayer!)
                
                DispatchQueue.global(qos: .userInitiated).async {
                    self.session.startRunning()
                    DispatchQueue.main.async {
                        self.videoPreviewLayer.frame = self.frame
                    }
                }
            }
            
        }
        catch let error  {
            print("Error Unable to initialize camera:  \(error.localizedDescription)")
        }
    }
    
    @objc
    func startRecording(_ args: [AnyHashable : Any], callback: @escaping RCTResponseSenderBlock) {
        do {
            var videoInputTransform = CGAffineTransform( rotationAngle: CGFloat(( 90 * Double.pi ) / 180) )
            
            switch (UIDevice.current.orientation) {
            case .portrait:
                videoInputTransform = CGAffineTransform( rotationAngle: CGFloat(( 90 * Double.pi ) / 180) )
                break
            case .portraitUpsideDown:
                videoInputTransform = CGAffineTransform( rotationAngle: CGFloat(( -90 * Double.pi ) / 180) )
                break
            case .landscapeLeft:
                if (self._cameraType == .front) {
                    videoInputTransform = CGAffineTransform( rotationAngle: CGFloat(( -180 * Double.pi ) / 180) )
                } else {
                    videoInputTransform = CGAffineTransform( rotationAngle: CGFloat(( 0 * Double.pi ) / 180) )
                }
                break
            case .landscapeRight:
                if (self._cameraType == .front) {
                    videoInputTransform = CGAffineTransform( rotationAngle: CGFloat(( 0 * Double.pi ) / 180) )
                } else {
                    videoInputTransform = CGAffineTransform( rotationAngle: CGFloat(( -180 * Double.pi ) / 180) )
                }
                break
            case .faceUp:
                break
            case .faceDown:
                break
            case .unknown:
                break
            }
            
            let videoWriterSettings = [
                AVVideoCodecKey : AVVideoCodecH264,
                AVVideoWidthKey : 1280,
                AVVideoHeightKey : 720,
                ] as [String : Any]
            
            let audioWriterSettings = [
                AVFormatIDKey : kAudioFormatAppleIMA4,
                AVNumberOfChannelsKey : 1,
                AVSampleRateKey : 16000.0
                ] as [String : Any]
            
            
            self.videoWriterInput = try AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoWriterSettings)
            self.audioWriterInput = try AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioWriterSettings)
            
            self.videoWriterInput.transform = videoInputTransform
            
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
            let outputPath = "\(documentsPath)/\(Date().timeIntervalSinceReferenceDate).mov"
            self.outputFileUrl = URL(fileURLWithPath: outputPath)
            if self.fileManager.isDeletableFile(atPath: self.outputFileUrl.path) {
                _ = try? self.fileManager.removeItem(atPath: self.outputFileUrl.path)
            }
            
            self.assetWriter = try AVAssetWriter(outputURL: outputFileUrl, fileType: AVFileTypeQuickTimeMovie)
            
            self.videoWriterInput.expectsMediaDataInRealTime = true
            self.audioWriterInput.expectsMediaDataInRealTime = true
            
            self.assetWriter.add(videoWriterInput)
            self.assetWriter.add(audioWriterInput)
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.stopRunning()
                self.isRecordingWritingStarted = true;
                self.assetWriter.startWriting()
                self.session.startRunning()
                callback([true])
            }
        }
        catch let error  {
            print("Error Unable to initialize camera:  \(error.localizedDescription)")
            callback([false, error.localizedDescription])
        }
    }
    
    var recordingStartTime: Double = 0
    let recordingDelay = 0.3
    
    func startRecordingSession(_ presentationTime: CMTime) {
        self.isRecordingSessionStarted = true
        
        // workaround: avoid recording video fadein on start
        DispatchQueue.main.asyncAfter(deadline: .now() + self.recordingDelay) {
            let startTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(presentationTime) + self.recordingDelay, presentationTime.timescale)
            self.recordingStartTime = Double(startTime.value) / Double(startTime.timescale);
            self.assetWriter?.startSession(atSourceTime: startTime)
            self.isRecordingStarted = true
        }
    }
    
    @objc
    func stopRecording(_ args: [AnyHashable : Any], callback: @escaping RCTResponseSenderBlock) {
        if (isRecordingStarted) {
            do {
                self.videoWriterInput.markAsFinished()
                self.audioWriterInput.markAsFinished()
                try self.assetWriter.finishWriting(completionHandler: {
                    self.recordingStartTime = 0
                    self.isRecordingStarted = false
                    self.isRecordingWritingStarted = false
                    self.isRecordingSessionStarted = false
                    callback([
                        [
                            "hasError": false,
                            "path": self.outputFileUrl.path,
                        ],
                    ])
                })
            }
            catch let error {
                callback([
                    [
                        "hasError": false,
                        "errorMessage": error.localizedDescription,
                    ]
                ])
            }
        }
    }
    
    func saveAsMPEG4(_ movVideoUrl: URL, outputUrl: NSString) -> Void {
        let avAsset = AVURLAsset(url: movVideoUrl)
        let startDate = Date()
        let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough)
        
        let docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let myDocPath = NSURL(fileURLWithPath: docDir).appendingPathComponent("temp.mp4")?.absoluteString
        
        let docDir2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as NSURL
        
        let filePath = docDir2.appendingPathComponent("rendered-Video.mp4")
        deleteFile(filePath!)
        
        if FileManager.default.fileExists(atPath: myDocPath!){
            do{
                try FileManager.default.removeItem(atPath: myDocPath!)
            }catch let error{
                print(error)
            }
        }
        
        exportSession?.outputURL = filePath
        exportSession?.outputFileType = AVFileTypeMPEG4
        exportSession?.shouldOptimizeForNetworkUse = true
        
        let start = CMTimeMakeWithSeconds(0.0, 0)
        let range = CMTimeRange(start: start, duration: avAsset.duration)
        exportSession?.timeRange = range
        
        exportSession!.exportAsynchronously{() -> Void in
            switch exportSession!.status{
            case .failed:
                print("\(exportSession!.error!)")
            case .cancelled:
                print("Export cancelled")
            case .completed:
                let endDate = Date()
                let time = endDate.timeIntervalSince(startDate)
                print(time)
                print("Successful")
                print(exportSession?.outputURL ?? "")
            //        UISaveVideoAtPathToSavedPhotosAlbum(URL(filePath), nil, nil, nil)
            default:
                break
            }
            
        }
    }
    
    func deleteFile(_ filePath:URL) {
        guard FileManager.default.fileExists(atPath: filePath.path) else{
            return
        }
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
        }catch{
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        faceDetectorManager.recognitionQueue.async { [unowned self] in
            
            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            
            if (self.isRecordingWritingStarted && !self.isRecordingSessionStarted) {
                self.startRecordingSession(presentationTime);
            }
            
            let description = CMSampleBufferGetFormatDescription(sampleBuffer)!
            let recording = self.isRecordingWritingStarted && self.isRecordingSessionStarted && self.isRecordingStarted
            
            if CMFormatDescriptionGetMediaType(description) == kCMMediaType_Audio {
                if (recording && self.audioWriterInput!.isReadyForMoreMediaData) {
                    self.audioWriterInput?.append(sampleBuffer)
                }
            } else {
                var currnetTime: Double = 0
                if (recording && self.videoWriterInput!.isReadyForMoreMediaData) {
                    if !self.videoWriterInput!.append(sampleBuffer) {
                        print("Error writing video buffer \(String(describing: self.assetWriter.error))");
                    }
                    currnetTime = Double(presentationTime.value) / Double(presentationTime.timescale)
                }
                self.faceDetectorManager.recognize(buffer: sampleBuffer, callback: self.handleFacesDetection, recordingTime: currnetTime - self.recordingStartTime)
            }
        }
    }
    
    func handleFacesDetection(_ data: [AnyHashable : Any]) -> Void {
        if (onFacesDetected != nil) {
            onFacesDetected!(data)
        }
    }
    
    func selectCaptureDevice(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return AVCaptureDevice.devices().filter {
            ($0 as AnyObject).hasMediaType(AVMediaTypeVideo) &&
                ($0 as AnyObject).position == position
            }.first as? AVCaptureDevice
    }
    
}
