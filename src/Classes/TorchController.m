//
//  TorchController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/30/11.
//  Copyright (c) 2011 Teleportaloo. All rights reserved.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import "TorchController.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"

@implementation TorchController

@synthesize torchSession = _torchSession;

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
        _prefs = [TriMetTimesAppDelegate getSingleton].prefs;
        if ([TorchController supported])
        {
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            
            if ([device hasTorch] && [device hasFlash])
            {
                
                if (device.torchMode == AVCaptureTorchModeOff) 
                {
                    AVCaptureDeviceInput *flashInput = [AVCaptureDeviceInput deviceInputWithDevice:device error: nil];
                    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
                    
                    AVCaptureSession *session = [[AVCaptureSession alloc] init];
                    
                    [session beginConfiguration];
                    [device lockForConfiguration:nil];
                    
                    [session addInput:flashInput];
                    [session addOutput:output];
                    
                    [device unlockForConfiguration];
                    
                    [output release];
                    
                    [session commitConfiguration];
                    [session startRunning];
                    
                    [self setTorchSession:session];
                    [session release];
                }

            }
        }
    }
    
    return self;
    
}

- (void)on
{
    
    if ([TorchController supported] && _prefs.flashLed) {
        
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
        
        if (device.torchMode != AVCaptureTorchModeOn && _prefs.flashLed)
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
    self.torchSession = nil;
    [super dealloc];
}

@end
