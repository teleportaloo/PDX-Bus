//
//  WatchNearbyInterfaceController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/17/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "XMLLocateStops.h"
#import "InterfaceControllerWithCommuterBookmark.h"

#define kNearbyScene @"Nearby"

@interface WatchNearbyInterfaceController : InterfaceControllerWithCommuterBookmark <CLLocationManagerDelegate>

@property (strong, nonatomic) IBOutlet WKInterfaceTable *stopTable;
@property (strong, nonatomic) IBOutlet WKInterfaceMap *map;
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *loadingGroup;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *loadingLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *locationStatusLabel;

- (IBAction)swipeDown:(id)sender;
- (IBAction)menuItemHome;
- (IBAction)menuItemCommute;

@end
