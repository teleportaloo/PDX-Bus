//
//  TorchController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/30/11.
//  Copyright (c) 2011 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "UserPrefs.h"


@interface TorchController : NSObject
{
 
}

+ (bool)supported;

- (instancetype)init;
- (void)on;
- (void)off;
- (void)toggle;

@end
