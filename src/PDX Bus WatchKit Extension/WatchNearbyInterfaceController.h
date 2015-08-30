//
//  WatchNearbyInterfaceController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/17/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

/* INSERT_LICENSE */

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "XMLLocateStops.h"
#import "InterfaceControllerWithBackgroundThread.h"

@interface WatchNearbyInterfaceController : InterfaceControllerWithBackgroundThread <CLLocationManagerDelegate>
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
- (IBAction)menuItemHome;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *locationStatusLabel;



- (IBAction)doShowListAction;

@end
