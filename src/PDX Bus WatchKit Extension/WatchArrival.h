//
//  WatchArrival.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/16/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "DepartureData+watchOSUI.h"
#import "WatchRow.h"

@interface WatchArrival: WatchRow

@property (strong, nonatomic) IBOutlet WKInterfaceImage *lineColor;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *heading;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *mins;
@property (strong, nonatomic) IBOutlet WKInterfaceImage *blockColor;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *exception;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *stale;

@end
