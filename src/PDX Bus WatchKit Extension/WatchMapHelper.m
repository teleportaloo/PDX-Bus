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

+ (void)displayMap:(WKInterfaceMap *)map
         purplePin:(CLLocation *)purplePin
         otherPins:(NSArray<id<WatchPinColor> > *)otherPins {
    CLLocationCoordinate2D topLeftCoord;
    
    topLeftCoord.latitude = -90;
    topLeftCoord.longitude = 180;
    
    CLLocationCoordinate2D bottomRightCoord;
    
    bottomRightCoord.latitude = 90;
    bottomRightCoord.longitude = -180;
    
    MapAnnotationImageFactory *mapAnnotionImage = [MapAnnotationImageFactory autoSingleton];
    
    mapAnnotionImage.forceRetinaImage = YES;
    
    [map removeAllAnnotations];
    
    if (purplePin != nil) {
        [map addAnnotation:purplePin.coordinate withPinColor:WKInterfaceMapPinColorPurple];
        
        topLeftCoord.longitude = fmin(topLeftCoord.longitude, purplePin.coordinate.longitude);
        topLeftCoord.latitude = fmax(topLeftCoord.latitude, purplePin.coordinate.latitude);
        
        bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, purplePin.coordinate.longitude);
        bottomRightCoord.latitude = fmin(bottomRightCoord.latitude,  purplePin.coordinate.latitude);
    }
    
    if (otherPins != nil) {
        for (NSInteger i = 0; i < otherPins.count && i < 6; i++) {
            id<WatchPinColor> pin = otherPins[i];
            
            if (pin.hasCoord) {
                CLLocationCoordinate2D loc = pin.coord;
                
                topLeftCoord.longitude = fmin(topLeftCoord.longitude, loc.longitude);
                topLeftCoord.latitude = fmax(topLeftCoord.latitude,  loc.latitude);
                
                bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, loc.longitude);
                bottomRightCoord.latitude = fmin(bottomRightCoord.latitude,  loc.latitude);
                
                if (pin.pinTint == nil) {
                    [map addAnnotation:loc withPinColor:pin.pinColor];
                } else if (pin.hasBearing) {
                    bool bus = [pin.pinTint isEqual:[UIColor modeAwareBusColor]];
                    UIImage *plainImage = [mapAnnotionImage getImage:pin.doubleBearing mapRotation:0.0 bus:bus named:mapAnnotionImage.forceRetinaImage ? kIconUp2x : kIconUp];
                    
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
}

@end
