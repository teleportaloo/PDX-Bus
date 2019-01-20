//
//  QrCodeReaderViewController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/16/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//

#import "ViewControllerBase.h"
#import <AVFoundation/AVFoundation.h>

@interface QrCodeReaderViewController : ViewControllerBase <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) UIView *viewPreview;
@property (nonatomic) bool isReading;
@property (nonatomic, strong) UISegmentedControl *lightSegControl;

@end
