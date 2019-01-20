//
//  MapViewController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/17/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "XMLDepartures.h"
#import "MapPinColor.h"
#import "UIToolbar+Auto.h"
#import "ViewControllerBase.h"
#import "ShapeRoutePath.h"
#import "RoutePolyline.h"

@interface LinesAnnotation : NSObject <MKAnnotation>
{
    CLLocationCoordinate2D _middle;
}

@property (nonatomic) CLLocationCoordinate2D middle;


@end

typedef enum _mapViewlineOptions {
    MapViewNoLines,
    MapViewFitLines,
    MapViewNoFitLines
} MapViewLineOptions;

@interface MapViewController : ViewControllerBase <MKMapViewDelegate, BackgroundTaskDone> {
    int                                 _selectedAnnotation;
    UISegmentedControl *                _segPrevNext;
    CGRect                              _portraitMapRect;
    bool                                _backgroundRefresh;
}

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) NSMutableArray *routePolyLines;
@property (nonatomic, strong) NSMutableArray<id<MapPinColor>> *annotations;
@property (nonatomic) MapViewLineOptions lineOptions;
@property (nonatomic, strong) NSMutableArray<ShapeRoutePath*>* lineCoords;
@property (nonatomic, strong) MKCircle *circle;
@property (nonatomic, strong) UIBarButtonItem *compassButton;
@property (atomic)            bool animating;
@property (nonatomic)         bool backgroundRefresh;
@property (readonly)          bool hasXML;
@property (nonatomic) CLLocationDirection previousHeading;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, copy)   NSString *msgText;
@property (nonatomic)         bool nextPrevButtons;
@property (nonatomic, strong)  NSMutableSet<RoutePin*>* overlayAnnotations;

// - (void)setMapLocationLat:(NSString *)lat lng:(NSString *)lng title:(NSString *)title;
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation;
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;
- (void)addPin:(id<MapPinColor>) pin;
- (void)removeAnnotations;
- (void)modifyMapViewFrame:(CGRect *)frame;

@end
