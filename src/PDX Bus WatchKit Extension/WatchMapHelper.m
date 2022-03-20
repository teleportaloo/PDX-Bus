//
//  WatchMapHelper.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchMapHelper.h"
#import "WatchPinColor.h"
#import "MapAnnotationImageFactory.h"
#import "UIImage+Tint.h"

#define kIconUp   @"icon_arrow_up.png"
#define kIconUp2x @"icon_arrow_up@2x.png"

@implementation WatchMapHelper

+ (void)expandTopLeft:(CLLocationCoordinate2D *)tl bottomRight:(CLLocationCoordinate2D *)br loc:(CLLocationCoordinate2D)loc
{
    tl->longitude = fmin(tl->longitude, loc.longitude);
    tl->latitude  = fmax(tl->latitude, loc.latitude);
    
    br->longitude = fmax(br->longitude, loc.longitude);
    br->latitude  = fmin(br->latitude,  loc.latitude);
}

+ (void)displayMap:(WKInterfaceMap *)map
         purplePin:(CLLocation *)purplePin
         otherPins:(NSArray<id<WatchPinColor> > *)otherPins
   currentLocation:(CLLocation *)currentLocation {
    CLLocationCoordinate2D topLeftCoord;
    
    topLeftCoord.latitude = -90;
    topLeftCoord.longitude = 180;
    
    CLLocationCoordinate2D bottomRightCoord;
    
    bottomRightCoord.latitude = 90;
    bottomRightCoord.longitude = -180;
    
    MapAnnotationImageFactory *mapAnnotionImage = [MapAnnotationImageFactory autoSingleton];
    
    mapAnnotionImage.forceRetinaImage = YES;
    
    [map removeAllAnnotations];
    
    if (currentLocation != nil) {
        [WatchMapHelper expandTopLeft:&topLeftCoord bottomRight:&bottomRightCoord loc:currentLocation.coordinate];
    }
    
    
    if (purplePin != nil) {
        [map addAnnotation:purplePin.coordinate withPinColor:WKInterfaceMapPinColorPurple];
        
        [WatchMapHelper expandTopLeft:&topLeftCoord bottomRight:&bottomRightCoord loc:purplePin.coordinate];
    }
    
    if (otherPins != nil) {
        for (NSInteger i = 0; i < otherPins.count && i < 6; i++) {
            id<WatchPinColor> pin = otherPins[i];
            
            if (pin.pinHasCoord) {
                CLLocationCoordinate2D loc = pin.pinCoord;
                
                [WatchMapHelper expandTopLeft:&topLeftCoord bottomRight:&bottomRightCoord loc:loc];
                                
                if (pin.pinTint == nil) {
                    [map addAnnotation:loc withPinColor:pin.pinColor];
                } else if (pin.pinHasBearing) {
                    bool bus = [pin.pinTint isEqual:[UIColor modeAwareBusColor]];
                    UIImage *plainImage = [mapAnnotionImage getImage:pin.pinBearing mapRotation:0.0 bus:bus named:mapAnnotionImage.forceRetinaImage ? kIconUp2x : kIconUp];
                    
                    if (!bus || mapAnnotionImage.tintableImage) {
                        UIImage *tintedImage = [plainImage tintImageWithColor:pin.pinTint];
                        [map addAnnotation:loc withImage:tintedImage centerOffset:CGPointZero];
                    } else {
                        [map addAnnotation:loc withImage:plainImage centerOffset:CGPointZero];
                    }
                }
            }
        }
    }
    
    MKCoordinateRegion region;
    
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.6;   // Add a little extra space on the sides
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.2;  // Add a little extra space on the sides
    
    if (region.span.latitudeDelta == 0.0) {
        region.span.latitudeDelta = 0.004;
        region.span.longitudeDelta = 0.004;
    }
    
    [map setRegion:region];
    map.hidden = NO;
    
    if (currentLocation)
    {
        if (@available(watchOS 6.1, *)) {
            map.showsUserLocation = YES;
        }
        else
        {
            [map addAnnotation:purplePin.coordinate withPinColor:WKInterfaceMapPinColorGreen];
        }
    }
}

@end
