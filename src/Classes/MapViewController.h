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
#import "LegShapeParser.h"
#import "RoutePolyline.h"

@interface LinesAnnotation : NSObject <MKAnnotation>
{
	CLLocationCoordinate2D _middle;
}

@property (nonatomic) CLLocationCoordinate2D middle;


@end


@interface MapViewController : ViewControllerBase <MKMapViewDelegate, UIActionSheetDelegate, BackgroundTaskDone> {
	MKMapView *                         _mapView;
	NSMutableArray<id<MapPinColor>> *   _annotations;
	NSMutableArray<ShapeObject*> *      _lineCoords;
	NSMutableArray<RoutePolyline *> *   _routePolyLines;
	MKCircle *                          _circle;
	bool                                _lines;
	int                                 _selectedAnnotation;
	id<MapPinColor>                     _tappedAnnot;
    NSMutableArray<NSNumber *>*         _actionButtons;
	UISegmentedControl *                _segPrevNext;
    UIBarButtonItem *                   _compassButton;
    CGRect                              _portraitMapRect;
    CLLocationDirection                 _previousHeading;
    CADisplayLink *                     _displayLink;
    NSString *                          _msgText;
    bool                                _backgroundRefresh;
}

@property (nonatomic, retain) NSMutableArray<NSNumber *> * actionButtons;
@property (nonatomic, retain) MKMapView *mapView;
@property (nonatomic, retain) NSMutableArray *routePolyLines;
@property (nonatomic, retain) id<MapPinColor> tappedAnnot;
@property (nonatomic, retain) NSMutableArray<id<MapPinColor>> *annotations;
@property (nonatomic) bool lines;
@property (nonatomic, retain) NSMutableArray<ShapeObject*> *lineCoords;
@property (nonatomic, retain) MKCircle *circle;
@property (nonatomic, retain) UIBarButtonItem *compassButton;
@property (atomic)            bool animating;
@property (nonatomic)         bool backgroundRefresh;
@property (readonly)          bool hasXML;
@property (nonatomic) CLLocationDirection previousHeading;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, copy)   NSString *msgText;

// - (void)setMapLocationLat:(NSString *)lat lng:(NSString *)lng title:(NSString *)title;
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation;
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;
- (void)addPin:(id<MapPinColor>) pin;
- (void)removeAnnotations;

@end
