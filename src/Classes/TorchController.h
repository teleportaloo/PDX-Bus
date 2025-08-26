//
//  TorchController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/30/11.
//  Copyright (c) 2011 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Settings.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

@interface TorchController : NSObject

- (instancetype)init;
- (void)on;
- (void)off;
- (void)toggle;

+ (bool)supported;

@end
