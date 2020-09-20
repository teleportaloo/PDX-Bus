//
//  BearingAnnotationView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/19/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <MapKit/MapKit.h>
#import "MapPinColor.h"
#import "MapAnnotationImageFactory.h"

@interface BearingAnnotationView : MKAnnotationView

@property (nonatomic, strong) MapAnnotationImageFactory *annotationImage;

- (void)updateDirectionalAnnotationView:(MKMapView *)mapView;

+ (MKAnnotationView *)viewForPin:(id<MapPinColor>)pin mapView:(MKMapView *)mapView;

@end
