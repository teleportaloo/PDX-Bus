//
//  QrCodeReaderViewController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/16/17.
//  Copyright © 2017 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ViewControllerBase.h"
#import <AVFoundation/AVFoundation.h>

@interface QrCodeReaderViewController : ViewControllerBase <AVCaptureMetadataOutputObjectsDelegate>

@end
