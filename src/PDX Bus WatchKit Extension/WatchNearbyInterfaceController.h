//
//  WatchNearbyInterfaceController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/17/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
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
{
    CLLocationManager *			_locationManager;
    NSDate *					_timeStamp;
    bool                        _waitingForLocation;
    CLLocation *                _lastLocation;
    XMLLocateStops *            _stops;
}
@property (strong, nonatomic) IBOutlet WKInterfaceTable *stopTable;
@property (strong, nonatomic) IBOutlet WKInterfaceMap *map;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) NSDate *timeStamp;
@property (nonatomic, retain) CLLocation *lastLocation;
@property (nonatomic, retain) XMLLocateStops *stops;
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *loadingGroup;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *loadingLabel;
- (IBAction)menuItemHome;
- (IBAction)menuItemCommute;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *locationStatusLabel;

@end
