//
//  FaceDetectorCameraViewManagerBridge.m
//  FaceDetectionApp
//
//  Created by  Gleb Volchetskiy on 11/6/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(FaceDetectorCameraViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(options, NSDictionary)

RCT_EXPORT_VIEW_PROPERTY(cameraType, NSString)

RCT_EXPORT_VIEW_PROPERTY(onFacesDetected, RCTDirectEventBlock)

RCT_EXTERN_METHOD(
                  startRecording:(nonnull NSNumber *)node
                  args:(NSDictionary *)args
                  callback: (RCTResponseSenderBlock)callback
                  )

RCT_EXTERN_METHOD(
                  stopRecording:(nonnull NSNumber *)node
                  args:(NSDictionary *)args
                  callback: (RCTResponseSenderBlock)callback
                  )

@end
