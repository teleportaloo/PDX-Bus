//
//  TaskLocator.h
//  PDX Bus
//
//  Created by Andy Wallace on 7/17/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "CoreLocation/CoreLocation.h"
#import "TaskState.h"
#import "BackgroundTaskContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface TaskLocator : NSObject <CLLocationManagerDelegate>

+ (CLLocation*)locateWithAccuracy:(CLLocationAccuracy)accuracy taskState:(TaskState *)state;

@end

NS_ASSUME_NONNULL_END
