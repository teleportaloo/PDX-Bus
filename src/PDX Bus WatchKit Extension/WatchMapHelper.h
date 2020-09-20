//
//  WatchMapHelper.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Andrew Wallace
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>
#import "WatchPinColor.h"



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


@interface WatchMapHelper : NSObject

+ (void)displayMap:(WKInterfaceMap *)map purplePin:(CLLocation *)purplePin otherPins:(NSArray<id<WatchPinColor> > *)pins;

@end
