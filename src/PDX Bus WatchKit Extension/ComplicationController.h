//
//  ComplicationController.h
//  PDX Bus WatchKit Extension
//
//  Created by Andrew Wallace on 11/17/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <WatchKit/WatchKit.h>
#import <ClockKit/ClockKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ComplicationController : NSObject<CLKComplicationDataSource>

@end

NS_ASSUME_NONNULL_END
