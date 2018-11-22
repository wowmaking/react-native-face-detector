//
//  FaceDetectorBridge.m
//  FaceDetectionApp
//
//  Created by  Gleb Volchetskiy on 11/5/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_REMAP_MODULE(FaceDetector, FaceDetectorManager, NSObject)

RCT_EXTERN_METHOD(configurate: (NSDictionary *)options)

RCT_EXTERN_METHOD(
                  recognize: (NSString)base64String
                  resolver: (RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject
                  )

@end
