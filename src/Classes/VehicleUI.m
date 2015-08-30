//
//  Vehicle.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "VehicleUI.h"
#import "DepartureTimesView.h"
#import "TriMetRouteColors.h"
#import "DebugLogging.h"

@class DepartureTimesView;

@implementation VehicleUI

@synthesize data            = _data;


+ (VehicleUI *)createFromData:(VehicleData *)data
{
    return [[[VehicleUI alloc] initWithData:data] autorelease];
}

- (id)initWithData:(VehicleData *)data {
    if ((self = [super init]))
    {
        self.data = data;
    }
    return self;
}


- (void)dealloc
{
    self.data = nil;
    
    [super dealloc];
}

- (CLLocationCoordinate2D) coordinate
{
    return _data.location.coordinate;
}

- (NSString*)title
{
    if (_data.signMessage)
    {
        DEBUG_LOG(@"Sign Message %@ b %@\n", _data.signMessage, _data.block);
        return _data.signMessage;
    }
    
    if ([_data.type isEqualToString:kVehicleTypeStreetcar])
    {
        ROUTE_COL *col = [TriMetRouteColors rawColorForRoute:_data.routeNumber];
        
        if (col)
        {
            return col->name;
        }
        return @"Portland Streetcar";
    }
    
    if (_data.garage)
    {
        return [NSString stringWithFormat:@"Garage %@", _data.garage];
    }
    
    return @"";
}

- (NSString*)subtitle
{
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
    
    return [NSString stringWithFormat:@"Seen at %@", [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:TriMetToUnixTime(_data.locationTime)]]];
}

// From MapPinColor
- (MKPinAnnotationColor) getPinColor
{
    if ([_data.type isEqualToString:kVehicleTypeBus])
    {
        return MKPinAnnotationColorRed;
    }
    
    if ([_data.type isEqualToString:kVehicleTypeStreetcar])
    {
        return MKPinAnnotationColorPurple;
    }
    
    return MKPinAnnotationColorGreen;
}
- (bool) showActionMenu
{
    if (_data.lastLocID)
    {
        return YES;
    }
    return NO;
}
- (bool) mapTapped:(id<BackgroundTaskProgress>) progress
{
    DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
    [departureViewController fetchTimesForVehicleInBackground:progress route:_data.routeNumber direction:_data.direction nextLoc:_data.lastLocID block:_data.block];
    [departureViewController release];
    
    return true;
}

- (NSString *) tapActionText
{
    return @"Show next stops";
}

@end
