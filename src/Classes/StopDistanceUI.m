//
//  StopDistanceUI.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/21/15.
//  Copyright © 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "StopDistanceUI.h"
#import "StopDistanceData.h"

@implementation StopDistanceUI

@synthesize data            = _data;


+ (StopDistanceUI *)createFromData:(StopDistanceData *)data
{
    return [[[StopDistanceUI alloc] initWithData:data] autorelease];
}

- (id)initWithData:(StopDistanceData *)data {
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



- (MKPinAnnotationColor) getPinColor
{
    return MKPinAnnotationColorGreen;
}

- (bool) showActionMenu
{
    return YES;
}

- (CLLocationCoordinate2D)coordinate
{
    return self.data.location.coordinate;
}

- (NSString *)title
{
    
    return self.data.desc;
}

- (NSString *)subtitle
{
    NSString *dir = @"";
    
    if (self.data.dir != nil)
    {
        dir = self.data.dir;
    }
    
    return [NSString stringWithFormat:NSLocalizedString(@"Stop ID %@ %@", @"TriMet Stop identifer <number>"), self.data.locid, dir];
}

- (NSString *) mapStopId
{
    return self.data.locid;
}

- (UIColor *)getPinTint
{
    return nil;
}

- (bool)hasBearing
{
    return NO;
}


@end
