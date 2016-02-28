//
//  BearingAnnotationView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/19/15.
//  Copyright © 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <MapKit/MapKit.h>
#import "MapPinColor.h"
#import "MapAnnotationImage.h"

@interface BearingAnnotationView : MKAnnotationView
{
    MapAnnotationImage *_annotationImage;
}

@property (nonatomic, retain) MapAnnotationImage *annotationImage;

- (void)updateDirectionalAnnotationView:(MKMapView *)mapView;

+ (MKAnnotationView*)viewForPin:(id<MapPinColor>)pin mapView:(MKMapView*)mapView;

@end
