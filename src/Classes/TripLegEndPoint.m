//
//  TripLegEndPoint.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripLegEndPoint.h"
#import "CLLocation+Helper.h"

@interface TripLegEndPoint () {
    CLLocation *_loc;
}

@end

@implementation TripLegEndPoint

@dynamic pinTint;


- (id)copyWithZone:(NSZone *)zone {
    TripLegEndPoint *ep = [[ TripLegEndPoint allocWithZone:zone] init];
    
    // ep.xlat               = [self.xlat            copyWithZone:zone];
    // ep.xlon               = [self.xlon            copyWithZone:zone];
    ep.loc = [self.loc copyWithZone:zone];
    ep.xdescription = [self.xdescription copyWithZone:zone];
    ep.xstopId = [self.xstopId copyWithZone:zone];
    ep.displayText = [self.displayText copyWithZone:zone];
    ep.displayText = [self.displayText copyWithZone:zone];
    ep.mapText = [self.mapText copyWithZone:zone];
    ep.xnumber = [self.xnumber copyWithZone:zone];
    ep.callback = self.callback;
    ep.displayModeText = [self.displayModeText copyWithZone:zone];
    ep.displayTimeText = [self.displayTimeText copyWithZone:zone];
    ep.leftColor = self.leftColor;
    ep.index = self.index;
    
    return ep;
}

#pragma mark Map callbacks

- (NSString *)stopId {
    if (self.xstopId) {
        return [NSString stringWithFormat:@"%d", self.xstopId.intValue];
    }
    
    return nil;
}

- (MapPinColorValue)pinColor {
    return MAP_PIN_COLOR_GREEN;
}

- (NSString *)mapStopId {
    return [self stopId];
}

- (bool)useMapTapped {
    return self.callback != nil;
}

- (bool)mapTapped:(id<TaskController>)progress {
    [self.callback chosenEndpoint:self];
    
    return YES;
}

- (CLLocationCoordinate2D)coordinate {
    return self.loc.coordinate;
}

- (bool)showActionMenu {
    return self.xstopId != nil || self.callback != nil;
}

- (NSString *)title {
    return self.xdescription;
}

- (NSString *)subtitle {
    if (self.mapText != nil) {
        return [NSString stringWithFormat:@"%d: %@", self.index, self.mapText];
    }
    
    return nil;
}

- (UIColor *)pinTint {
    return nil;
}

- (bool)hasBearing {
    return NO;
}

- (CLLocation *)loc {
    if (self.xlat != nil && self.xlon != nil) {
        _loc = [CLLocation fromStringsLat:self.xlat lng:self.xlon];
        
        self.xlat = nil;
        self.xlon = nil;
        return _loc;
    }
    
    return _loc;
}

- (void)setLoc:(CLLocation *)loc {
    _loc = loc;
    
    self.xlat = nil;
    self.xlon = nil;
}

@end
