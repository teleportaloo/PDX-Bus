//
//  NearestVehiclesMap.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//

#import "MapViewController.h"
#import "XMLLocateVehicles.h"

@interface NearestVehiclesMap : MapViewController
{
    XMLLocateVehicles *_locator;
}


@property (nonatomic, retain) XMLLocateVehicles *locator;
- (void)fetchNearestVehiclesInBackground:(id<BackgroundTaskProgress>)background location:(CLLocation *)here maxDistance:(double)dist;


@end
