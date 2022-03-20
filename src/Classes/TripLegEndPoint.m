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
#import "NSString+Helper.h"

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
    ep.xml_description = [self.desc copyWithZone:zone];
    ep.xml_stopId = [self.strStopId copyWithZone:zone];
    ep.displayText = [self.displayText copyWithZone:zone];
    ep.displayText = [self.displayText copyWithZone:zone];
    ep.mapText = [self.mapText copyWithZone:zone];
    ep.xml_number = [self.displayRouteNumber copyWithZone:zone];
    ep.callback = self.callback;
    ep.displayModeText = [self.displayModeText copyWithZone:zone];
    ep.displayTimeText = [self.displayTimeText copyWithZone:zone];
    ep.leftColor = self.leftColor;
    ep.index = self.index;
    
    return ep;
}

#pragma mark Map callbacks

- (NSString *)stopId {
    if (self.strStopId) {
        return [NSString stringWithFormat:@"%d", self.strStopId.intValue];
    }
    
    return nil;
}

- (MapPinColorValue)pinColor {
    return MAP_PIN_COLOR_GREEN;
}

- (NSString *)pinStopId {
    return [self stopId];
}

- (bool)pinUseAction {
    return self.callback != nil;
}

- (bool)pinAction:(id<TaskController>)progress {
    [self.callback chosenEndpoint:self];
    
    return YES;
}

- (NSString *)pinMarkedUpType {
    return nil;
}

- (CLLocationCoordinate2D)coordinate {
    return self.loc.coordinate;
}

- (bool)pinActionMenu {
    return self.strStopId != nil || self.callback != nil;
}

- (NSString *)title {
    return self.desc;
}

- (NSString *)subtitle {
    if (self.mapText != nil) {
        return [NSString stringWithFormat:@"%d: %@", self.index, self.mapText];
    }
    
    return nil;
}

- (NSString *)pinMarkedUpSubtitle {
    if (self.mapText != nil) {
        return [NSString stringWithFormat:@"#R#b%d:#D %@", self.index, self.mapText];
    }
    
    return nil;
}

- (UIColor *)pinTint {
    return nil;
}

- (bool)pinHasBearing {
    return NO;
}

- (CLLocation *)loc {
    if (self.lat != nil && self.lon != nil) {
        _loc = [CLLocation fromStringsLat:self.lat lng:self.lon];
        
        self.xml_lat = nil;
        self.xml_lon = nil;
        return _loc;
    }
    
    return _loc;
}

- (void)setLoc:(CLLocation *)loc {
    _loc = loc;
    
    self.xml_lat = nil;
    self.xml_lon = nil;
}

@end
