//
//  TorchController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/30/11.
//  Copyright (c) 2011 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TorchController.h"

@implementation TorchController

+(bool)supported
{
    static bool checkDone = NO;
    static bool supported = NO;
    
    if (!checkDone)
    {
        Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
        if (captureDeviceClass != nil)
        {
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            
            if ([device hasTorch] && [device hasFlash])
            {
                supported = YES;
            }
        }
        checkDone = YES;
    }
    return supported;
}

- (id)init
{
    if ((self = [super init]))
    {

    }
    
    return self;
    
}

- (void)on
{
    
    if ([TorchController supported] && [UserPrefs getSingleton].flashLed) {
        
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        [device lockForConfiguration:nil];
        
        [device setTorchMode:AVCaptureTorchModeOn];
        [device setFlashMode:AVCaptureFlashModeOn];
        
        [device unlockForConfiguration];
        
    }

}

- (void)off
{
    if ([TorchController supported]) {
     
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        [device lockForConfiguration:nil];
        
        [device setTorchMode:AVCaptureTorchModeOff];
        [device setFlashMode:AVCaptureFlashModeOff];
        
        [device unlockForConfiguration];
        
    }
}

- (void)toggle
{
    if ([TorchController supported]) {
        
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        [device lockForConfiguration:nil];
        
        if (device.torchMode != AVCaptureTorchModeOn && [UserPrefs getSingleton].flashLed)
        {
            [device setTorchMode:AVCaptureTorchModeOn];
            [device setFlashMode:AVCaptureFlashModeOn];            
        }
        else
        {
            [device setTorchMode:AVCaptureTorchModeOff];
            [device setFlashMode:AVCaptureFlashModeOff];
 
        }
    }
}

- (void)dealloc
{
    [self off];
    [super dealloc];
}

@end
