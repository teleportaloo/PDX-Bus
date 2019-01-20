//
//  WatchArrivalMap.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/17/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>
#import "WatchRow.h"

@interface WatchArrivalMap : WatchRow

@property (strong, nonatomic) IBOutlet WKInterfaceMap *map;

@end
