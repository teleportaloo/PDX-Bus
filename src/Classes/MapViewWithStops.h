//
//  MapViewWithStops.h
//  PDX Bus
//
//  Created by Andrew Wallace on 3/6/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapViewController.h"
#import "XMLStops.h"
#import "Stop.h"

@interface MapViewWithStops : MapViewController
{
    XMLStops *_stopData;
    NSString *_locId;
    
}

@property (nonatomic, retain) XMLStops *stopData;
@property (nonatomic, retain) NSString *locId;

- (void)fetchStopsInBackground:(id<BackgroundTaskProgress>) callback route:(NSString*)routeid direction:(NSString*)dir
                    returnStop:(id<ReturnStop>)returnStop;
@end
