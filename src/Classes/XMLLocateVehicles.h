//
//  XMLLocateVehicles.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TriMetXML.h"
#import <CoreLocation/CoreLocation.h>
#import "Vehicle.h"

@interface XMLLocateVehicles : TriMetXML
{
    CLLocation *_location;
    double     _dist;

}

@property (nonatomic, retain) CLLocation *location;
@property (nonatomic)         double     dist;

- (BOOL)findNearestVehicles;
- (bool)displayErrorIfNoneFound:(id<BackgroundTaskProgress>)progress;
@end



