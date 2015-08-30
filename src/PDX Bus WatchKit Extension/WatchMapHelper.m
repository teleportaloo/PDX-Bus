//
//  WatchMapHelper.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

#import "WatchMapHelper.h"

@implementation WatchMapHelper

+ (void)displayMap:(WKInterfaceMap*)map purplePin:(CLLocation*)purplePin redPins:(NSArray*)redPins
{
    CLLocationCoordinate2D topLeftCoord;
    topLeftCoord.latitude = -90;
    topLeftCoord.longitude = 180;
    
    CLLocationCoordinate2D bottomRightCoord;
    bottomRightCoord.latitude = 90;
    bottomRightCoord.longitude = -180;
    
    if (purplePin!=nil)
    {
        [map addAnnotation:purplePin.coordinate withPinColor:WKInterfaceMapPinColorPurple];
        
        topLeftCoord.longitude      = fmin(topLeftCoord.longitude,purplePin.coordinate.longitude);
        topLeftCoord.latitude       = fmax(topLeftCoord.latitude, purplePin.coordinate.latitude);
    
        bottomRightCoord.longitude  = fmax(bottomRightCoord.longitude, purplePin.coordinate.longitude);
        bottomRightCoord.latitude   = fmin(bottomRightCoord.latitude,  purplePin.coordinate.latitude);
    }
    
    if (redPins!=nil)
    {
        for(NSInteger i = 0; i < redPins.count && i < 6; i++)
        {
            CLLocation *loc = [redPins objectAtIndex:i];
        
            topLeftCoord.longitude      = fmin(topLeftCoord.longitude, loc.coordinate.longitude);
            topLeftCoord.latitude       = fmax(topLeftCoord.latitude,  loc.coordinate.latitude);
        
            bottomRightCoord.longitude  = fmax(bottomRightCoord.longitude, loc.coordinate.longitude);
            bottomRightCoord.latitude   = fmin(bottomRightCoord.latitude, loc.coordinate.latitude);
        
            [map addAnnotation:loc.coordinate withPinColor:WKInterfaceMapPinColorRed];
        }
    }
    
    MKCoordinateRegion region;
    region.center.latitude      = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
    region.center.longitude     = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
    region.span.latitudeDelta   = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.6; // Add a little extra space on the sides
    region.span.longitudeDelta  = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.2; // Add a little extra space on the sides
    
    if (region.span.latitudeDelta == 0.0)
    {
        region.span.latitudeDelta = 0.004;
        region.span.longitudeDelta= 0.004;
        
    }
    
    [map setRegion:region];
    map.hidden = NO;
}

@end
