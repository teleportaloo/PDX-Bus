//
//  MapViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/17/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "MapViewController.h"
#import "BearingAnnotationView.h"
#import "CLLocation+Helper.h"
#import "DebugLogging.h"
#import "Departure.h"
#import "DepartureData+iOSUI.h"
#import "DepartureDetailViewController.h"
#import "DepartureTimesViewController.h"
#import "Icons.h"
#import "MapPin.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "PDXBusAppDelegate+Methods.h"
#import "QuartzCore/QuartzCore.h"
#import "RouteMultiPolyline.h"
#import "RoutePin.h"
#import "TaskDispatch.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIApplication+Compat.h"
#import "UIBarButtonItem+Icons.h"
#import "ViewControllerBase+MapPinAction.h"
#import "WebViewController.h"
#import "XMLDepartures.h"
#import <MapKit/MapKit.h>
#import <MapKit/MkAnnotation.h>

#define kPrev NSLocalizedString(@"Prev", @"Short button text for previous")
#define kStart NSLocalizedString(@"Start", @"Short button text for start")
#define kNext NSLocalizedString(@"Next", @"Short button text for next")
#define kEnd NSLocalizedString(@"End", @"Short button text for end")

#define kNoButton -1

@interface MapViewController () {
    int _selectedAnnotation;
    UISegmentedControl *_segPrevNext;
    CGRect _portraitMapRect;
    bool _backgroundRefresh;
}

@property(nonatomic, strong) NSMutableArray *routePolyLines;
@property(nonatomic, strong) UIBarButtonItem *compassButton;
@property(atomic) bool animating;
@property(readonly) bool hasXML;
@property(nonatomic) CLLocationDirection previousHeading;
@property(nonatomic, strong) CADisplayLink *displayLink;
@property(nonatomic, strong) NSMutableSet<RoutePin *> *overlayAnnotations;
@property(nonatomic, strong) UIBarButtonItem *segButton;

- (void)modifyMapViewFrame:(CGRect *)frame;
- (MKAnnotationView *)mapView:(MKMapView *)mapView
            viewForAnnotation:(id<MKAnnotation>)annotation;
- (void)mapView:(MKMapView *)mapView
                   annotationView:(MKAnnotationView *)view
    calloutAccessoryControlTapped:(UIControl *)control;
- (void)removeAnnotations;

@end

@implementation MapViewController

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Transit Map", @"page title");
        _annotations = [NSMutableArray array];
    }

    return self;
}

- (void)dealloc {
    _mapView.delegate = nil;
    _mapView.showsUserLocation = FALSE;
    [_mapView removeAnnotations:self.mapView.annotations];

    if (_displayLink) {
        [_displayLink invalidate];
    }

    // A bug in the SDK means that releasing a mapview can cause a crash as it
    // may be animating we delay 4 seconds for the release.
    [_mapView performSelector:@selector(self)
                   withObject:nil
                   afterDelay:(NSTimeInterval)4.0];
}

#pragma mark Helper functions

- (void)addPin:(id<MapPin>)pin {
    [self.annotations addObject:pin];
}

- (bool)hasXML {
    return NO;
}

#pragma mark Prev/Next Segment controller

- (void)setSegText:(UISegmentedControl *)seg {
    if (_selectedAnnotation > 1) {
        [seg setTitle:kPrev forSegmentAtIndex:0];
    } else {
        [seg setTitle:kStart forSegmentAtIndex:0];
    }

    if (_selectedAnnotation < self.annotations.count - 2) {
        [seg setTitle:kNext forSegmentAtIndex:1];
    } else {
        [seg setTitle:kEnd forSegmentAtIndex:1];
    }
}

- (void)prevNext:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
    case 0: {
        // Prev
        if (_selectedAnnotation > 0) {
            _selectedAnnotation--;
        }

        break;
    }

    case 1: {
        if (_selectedAnnotation < (self.annotations.count - 1)) {
            _selectedAnnotation++;
        }

        break;
    }
    }

    [self setSegText:sender];

    [self.mapView deselectAnnotation:self.annotations[_selectedAnnotation]
                            animated:NO];
    [self.mapView selectAnnotation:self.annotations[_selectedAnnotation]
                          animated:YES];
}

#pragma mark UI Callbacks

- (void)toggleMap:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
    case 0: {
        self.mapView.mapType = MKMapTypeStandard;
        break;
    }

    case 1: {
        self.mapView.mapType = MKMapTypeHybrid;
        break;
    }
    }
}

#pragma mark ViewControllerBase methods

- (void)infoAction:(id)sender {
    UIAlertController *alert = [UIAlertController
        simpleOkWithTitle:NSLocalizedString(@"Info", @"Alert title")
                  message:NSLocalizedString(
                              @"The route path does not reflect future service "
                              @"changes until they come into effect.\n"
                               "Route and departure data provided by "
                               "permission of TriMet.",
                              @"trip planner information")];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateToolbarMainThread {
    if (self.segButton == nil) {
        self.segButton = [self segBarButtonWithItems:@[ @"Map", @"Hybrid" ]
                                              action:@selector(toggleMap:)
                                       selectedIndex:0];
    }
    if ([MKMapView instancesRespondToSelector:@selector
                   (setUserTrackingMode:animated:)]) {
        self.compassButton =
            [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    }
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    UIBarButtonItem *zoom =
        [UIBarButtonItem withSystemImage:kSFIconEye
                                   style:UIBarButtonItemStylePlain
                                  target:self
                                  action:@selector(fitToViewAction:)];

    [toolbarItems addObjectsFromArray:@[ zoom, [UIToolbar flexSpace] ]];

    if (self.compassButton) {
        [toolbarItems
            addObjectsFromArray:@[ self.compassButton, [UIToolbar flexSpace] ]];
    }

    [toolbarItems addObject:self.segButton];

    if (self.lineOptions != MapViewNoLines && self.nextPrevButtons) {
        // create the system-defined "OK or Done" button
        UIBarButtonItem *info =
            [UIToolbar textButton:NSLocalizedString(@"info", @"button text")
                           target:self
                           action:@selector(infoAction:)];

        [toolbarItems addObjectsFromArray:@[ [UIToolbar flexSpace], info ]];
    }

    if (self.hasXML) {
        [toolbarItems addObject:[UIToolbar flexSpace]];
        [self updateToolbarItemsWithXml:toolbarItems];
    } else {
        [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
    }
}

- (void)removeAnnotations {
    DEBUG_FUNC();
    @autoreleasepool {
        NSArray *oldAnnotations = self.mapView.annotations;

        if (oldAnnotations != nil && oldAnnotations.count > 0) {
            [self.mapView removeAnnotations:oldAnnotations];
        }
    }
    DEBUG_FUNCEX();
}

#pragma mark View functions

- (void)fitToViewAction:(id)unused {
    [self fitToView];
}

- (bool)fitAnnotation:(id<MapPin>)pin {
    return YES;
}

- (void)fitToView {
    NSMutableArray<id<MapPin>> *pinsToFit = [NSMutableArray array];

    if (self.annotations != nil) {
        for (id<MapPin> pin in self.annotations) {
            if ([self fitAnnotation:pin]) {
                [pinsToFit addObject:pin];
            }
        }
    }

    NSInteger pins = pinsToFit.count;
    NSUInteger lines = 0;

    if (self.shapes && (self.lineOptions == MapViewFitLines || pins == 0)) {
        lines = self.shapes.count;
    }

    // Walk the list of overlays and annotations and create a MKMapRect that
    // bounds all of them and store it into flyTo.

    if (pins == 1 && lines == 0) {
        /*Region and Zoom*/
        MKCoordinateRegion region;
        region.center.latitude = 0.0;
        region.center.longitude = 0.0;
        MKCoordinateSpan span;
        span.latitudeDelta = 0.005;
        span.longitudeDelta = 0.005;

        region.span = span;

        if (self.annotations != nil && self.annotations.count > 0) {
            region.center = self.annotations.firstObject.coordinate;
        }

        [self.mapView regionThatFits:region];
        [self.mapView setRegion:region animated:TRUE];
    } else {
        MKMapRect flyTo = MKMapRectNull;

        for (id<MapPin> pin in pinsToFit) {
            DEBUG_LOG(@"Coords %@ %@\n", COORD_TO_LAT_LNG_STR(pin.coordinate),
                      [pin title]);
            MKMapPoint annotationPoint =
                MKMapPointForCoordinate(pin.coordinate);
            MKMapRect pointRect = MakeMapRectWithPointAtCenter(
                annotationPoint.x, annotationPoint.y, 300, 1000);
            flyTo = MKMapRectUnion(flyTo, pointRect);
        }

        if (lines > 0) {
            for (ShapeRoutePath *path in self.shapes) {
                for (id<ShapeSegment> seg in path.segments) {
                    NSUInteger i;
                    CLLocationCoordinate2D *c;
                    ShapeCompactSegment *compact = seg.compact;

                    for (i = 0, c = compact.coords; i < compact.count;
                         i++, c++) {
                        MKMapPoint annotationPoint =
                            MKMapPointForCoordinate(*c);
                        MKMapRect pointRect = MakeMapRectWithPointAtCenter(
                            annotationPoint.x, annotationPoint.y, 300, 1000);
                        flyTo = MKMapRectUnion(flyTo, pointRect);
                    }
                }
            }
        }

        UIEdgeInsets insets = {100, 30, 60, 30};

        [self.mapView setVisibleMapRect:[self.mapView mapRectThatFits:flyTo
                                                          edgePadding:insets]
                               animated:YES];
    }
}

- (void)removeOverlays {
    NSArray *oldOverlays = self.mapView.overlays;

    if (oldOverlays != nil && oldOverlays.count > 0) {
        [self.mapView removeOverlays:oldOverlays];
    }
}

- (BearingAnnotationView *)bearingViewForAnnotation:(id<MKAnnotation>)annot {
    MKAnnotationView *annotationView = [self.mapView viewForAnnotation:annot];

    if (annotationView &&
        [annotationView isKindOfClass:[BearingAnnotationView class]]) {
        return (BearingAnnotationView *)annotationView;
    }

    return nil;
}

// Implement viewDidLoad to do additional setup after loading the view,
// typically from a nib.
- (void)addDataToMap:(bool)zoom animate:(bool)animate {

    if (!animate) {
        [self removeAnnotations];
    }

    DEBUG_HERE();

    @autoreleasepool {
        if (!self.staticOverlays) {
            [self removeOverlays];
        }
    }

    DEBUG_HERE();

    if (self.shapes != nil && self.nextPrevButtons) {
        self.navigationItem.rightBarButtonItem =
            [self segBarButtonWithItems:@[ kPrev, kNext ]
                                 action:@selector(prevNext:)
                          selectedIndex:kSegNoSelectedIndex];

        _segPrevNext = self.navigationItem.rightBarButtonItem.customView;
        _segPrevNext.frame = CGRectMake(0, 0, 80, 30.0);
        _segPrevNext.momentary = YES;

        _selectedAnnotation = 0;

        [self setSegText:_segPrevNext];
    }

    if (!animate) {
        if (self.annotations != nil) {
            for (id<MKAnnotation> annotation in self.annotations) {
                [self.mapView addAnnotation:annotation];
            }
        }
    } else {

        NSArray<id<MKAnnotation>> *oldAnnotations = self.mapView.annotations;

        NSMutableArray *annotationsToRemove = [NSMutableArray array];
        NSMutableArray *annotationsToAdd = [NSMutableArray array];
        NSMutableDictionary<NSString *, id<MapPin>> *lookup =
            [NSMutableDictionary dictionary];
        NSSet<id<MapPin>> *staticAnnotations =
            [NSSet setWithArray:self.staticAnnotations];

        // Remove all annotations that have no key, and are not static, they
        // will get added back we hope
        for (id<MKAnnotation> old in oldAnnotations) {
            if ([old conformsToProtocol:@protocol(MapPin)]) {
                if ([old respondsToSelector:@selector(key)] &&
                    ((id<MapPin>)old).key != nil) {
                    id<MapPin> mapPin = (id<MapPin>)old;
                    [lookup setObject:mapPin forKey:mapPin.key];
                } else {
                    id<MapPin> mapPin = (id<MapPin>)old;
                    if (![staticAnnotations containsObject:mapPin]) {
                        [annotationsToRemove addObject:old];
                    }
                }
            }
        }

        [UIView animateWithDuration:0.3f
            animations:^{
              for (id<MapPin> pin in self.annotations) {
                  if (![pin respondsToSelector:@selector(key)]) {
                      [annotationsToAdd addObject:pin];
                  } else if ([pin respondsToSelector:@selector
                                  (setCoordinate:)]) {
                      id<MapPin> old = lookup[pin.key];

                      if (old != nil) {
                          bool latestLocation = YES;

                          if ([old respondsToSelector:@selector(lastUpdated)] &&
                              [pin respondsToSelector:@selector(lastUpdated)] &&
                              old.lastUpdated != nil &&
                              pin.lastUpdated != nil) {
                              NSTimeInterval diff = [pin.lastUpdated
                                  timeIntervalSinceDate:old.lastUpdated];
                              if (diff < -1.0) {
                                  latestLocation = NO;
                              }
                          }

                          if (latestLocation &&
                              (old.coordinate.longitude !=
                                   pin.coordinate.longitude ||
                               old.coordinate.latitude !=
                                   pin.coordinate.latitude ||
                               old.pinBearing != pin.pinBearing)) {
                              old.coordinate = pin.coordinate;

                              if ([old respondsToSelector:@selector
                                       (setPinBearing:)]) {
                                  old.pinBearing = pin.pinBearing;
                              }

                              MKAnnotationView *av =
                                  [self.mapView viewForAnnotation:old];

                              BearingAnnotationView *bearingView =
                                  [self bearingViewForAnnotation:old];

                              if (bearingView) {
                                  [bearingView
                                      updateDirectionInPlace:self.mapView];
                              }

                              [annotationsToAdd addObject:pin];
                              [annotationsToRemove addObject:old];
                              [av layoutIfNeeded];
                          }

                          [lookup removeObjectForKey:pin.key];

                      } else {
                          [annotationsToAdd addObject:pin];
                      }
                  }
              }
            }
            completion:^(BOOL finished) {
              [lookup enumerateKeysAndObjectsUsingBlock:^(
                          NSString *_Nonnull key, id<MapPin> _Nonnull obj,
                          BOOL *_Nonnull stop) {
                [annotationsToRemove addObject:obj];
              }];

              if (annotationsToAdd.count > 0) {
                  [self.mapView addAnnotations:annotationsToAdd];
              }

              if (annotationsToRemove.count > 0) {
                  [self.mapView removeAnnotations:annotationsToRemove];
              }
            }];
    }

    NSArray *oldOverlays = self.mapView.overlays;

    if (oldOverlays == nil || oldOverlays.count == 0) {
        if (self.lineOptions != MapViewNoLines &&
            self.shapes.count > 0) { // overlays!
            self.routePolyLines = [NSMutableArray array];

            for (ShapeRoutePath *path in self.shapes) {
                [path addPolylines:self.routePolyLines];
            }

            DEBUG_LOG_long(self.routePolyLines.count);

            [self.mapView addOverlays:self.routePolyLines];
        }
    }

    if (zoom) {
        [self fitToView];
    }

    [self updateToolbar];
}

- (void)modifyMapViewFrame:(CGRect *)frame {
}

- (void)reloadData {
    [super reloadData];
    self.mapView.frame = [self calculateFrame];
}

- (CGRect)calculateFrame {
    CGRect mapViewRect = self.middleWindowRect;

    [self modifyMapViewFrame:&mapViewRect];
    return mapViewRect;
}

/** Returns the distance of |pt| to |poly| in meters
 *
 * from http://paulbourke.net/geometry/pointlineplane/DistancePoint.java
 *
 */

- (double)distanceOfPoint:(MKMapPoint)pt
              toMultiPoly:(const MKMultiPolyline *)poly {
    double distance = MAXFLOAT;

    for (MKPolyline *p in poly.polylines) {
        double segDistance = [self distanceOfPoint:pt toPoly:p];

        if (segDistance < distance) {
            distance = segDistance;
        }
    }

    return distance;
}
- (double)distanceOfPoint:(MKMapPoint)pt toPoly:(const MKPolyline *)poly {
    double distance = MAXFLOAT;

    MKMapPoint *ptA = poly.points;
    MKMapPoint *ptB = poly.points + 1;

    for (int n = 0; n < poly.pointCount - 1; n++, ptA++, ptB++) {
        double xDelta = ptB->x - ptA->x;
        double yDelta = ptB->y - ptA->y;

        if (xDelta == 0.0 && yDelta == 0.0) {
            // Points must not be equal
            continue;
        }

        double u = ((pt.x - ptA->x) * xDelta + (pt.y - ptA->y) * yDelta) /
                   (xDelta * xDelta + yDelta * yDelta);
        MKMapPoint ptClosest;

        if (u < 0.0) {
            ptClosest = *ptA;
        } else if (u > 1.0) {
            ptClosest = *ptB;
        } else {
            ptClosest =
                MKMapPointMake(ptA->x + u * xDelta, ptA->y + u * yDelta);
        }

        CLLocationDistance closest = MKMetersBetweenMapPoints(ptClosest, pt);
        distance = MIN(distance, closest);
    }

    return distance;
}

/** Converts |px| to meters at location |pt| */
- (double)metersFromPixel:(NSUInteger)px atPoint:(CGPoint)pt {
    CGPoint ptB = CGPointMake(pt.x + px, pt.y);

    CLLocationCoordinate2D coordA = [self.mapView convertPoint:pt
                                          toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D coordB = [self.mapView convertPoint:ptB
                                          toCoordinateFromView:self.mapView];

    return MKMetersBetweenMapPoints(MKMapPointForCoordinate(coordA),
                                    MKMapPointForCoordinate(coordB));
}

- (void)delayedBlock:(dispatch_block_t)block {
    MainTaskDelay(0.6, block);
}

+ (CLLocationCoordinate2D)calculateCoordinateFrom:
                              (CLLocationCoordinate2D)coordinate
                                        onBearing:(double)bearingInRadians
                                       atDistance:(double)distanceInMetres {
    double coordinateLatitudeInRadians = coordinate.latitude * M_PI / 180;
    double coordinateLongitudeInRadians = coordinate.longitude * M_PI / 180;

    double distanceComparedToEarth = distanceInMetres / 6378100;

    double resultLatitudeInRadians =
        asin(sin(coordinateLatitudeInRadians) * cos(distanceComparedToEarth) +
             cos(coordinateLatitudeInRadians) * sin(distanceComparedToEarth) *
                 cos(bearingInRadians));
    double resultLongitudeInRadians =
        coordinateLongitudeInRadians +
        atan2(sin(bearingInRadians) * sin(distanceComparedToEarth) *
                  cos(coordinateLatitudeInRadians),
              cos(distanceComparedToEarth) - sin(coordinateLatitudeInRadians) *
                                                 sin(resultLatitudeInRadians));

    CLLocationCoordinate2D result;

    result.latitude = resultLatitudeInRadians * 180 / M_PI;
    result.longitude = resultLongitudeInRadians * 180 / M_PI;
    return result;
}

#define MAX_DISTANCE_PX 22.0f

- (void)handleTap:(UITapGestureRecognizer *)tap {
    if ((tap.state & UIGestureRecognizerStateRecognized) ==
        UIGestureRecognizerStateRecognized) {
        // Get map coordinate from touch point

        CGPoint touchPt = [tap locationInView:self.mapView];
        DEBUG_LOG_CGPoint(touchPt);
        CLLocationCoordinate2D coord = [self.mapView convertPoint:touchPt
                                             toCoordinateFromView:self.mapView];

        UIView *touchedView = [self.mapView hitTest:touchPt withEvent:nil];

        if ([touchedView isKindOfClass:[MKAnnotationView class]]) {
            // Let the parent do the selection
        } else {
            double maxMeters = [self metersFromPixel:MAX_DISTANCE_PX
                                             atPoint:touchPt];

            float nearestDistance = MAXFLOAT;
            NSMutableSet<RoutePin *> *nearestPolysPins = [NSMutableSet set];

            // RoutePolyline *nearestPoly = nil;

            // for every overlay ...
            for (id<MKOverlay> overlay in self.mapView.overlays) {
                // .. if MKPolyline ...
                if ([overlay isKindOfClass:[RouteMultiPolyline class]]) {
                    // ... get the distance ...

                    RouteMultiPolyline *polyLine =
                        (RouteMultiPolyline *)overlay;
                    float distance =
                        [self distanceOfPoint:MKMapPointForCoordinate(coord)
                                  toMultiPoly:(const MKMultiPolyline *)overlay];

                    // ... and find the nearest one
                    if (distance < nearestDistance) {
                        nearestDistance = distance;
                        [nearestPolysPins removeAllObjects];
                        [nearestPolysPins addObject:polyLine.routePin];
                    }

                    if (distance == nearestDistance) {
                        [nearestPolysPins addObject:polyLine.routePin];
                    }
                }
            }

            DEBUG_LOG_double(nearestDistance);
            DEBUG_LOG_double(maxMeters);

            if (nearestDistance <= maxMeters) {
                // Add a special pin at this point and show the callout.  The
                // pin is for the route.
                bool reselect = NO;

                // If the previous selection near to the current touch
                if ([self.overlayAnnotations isEqualToSet:nearestPolysPins]) {
                    RoutePin *old = self.overlayAnnotations.anyObject;
                    CGPoint oldPoint =
                        [self.mapView convertCoordinate:old.coordinate
                                          toPointToView:self.mapView];

                    CGFloat xGap = oldPoint.x - touchPt.x;
                    CGFloat yGap = oldPoint.y - touchPt.y;
                    CGFloat distSq = yGap * yGap + xGap * xGap;

                    if (distSq < 50.0 * 50.0) {
                        reselect = YES;
                    }
                }

                if (reselect) {
                    bool found = NO;

                    for (id<MKAnnotation> annot in self.mapView
                             .selectedAnnotations) {
                        for (RoutePin *p in self.overlayAnnotations) {
                            if ([p isEqual:annot]) {
                                found = YES;
                                [self.mapView selectAnnotation:p animated:YES];
                            }
                        }
                    }

                    if (!found) {
                        [self delayedBlock:^{
                          [self.mapView
                              selectAnnotation:self.overlayAnnotations.anyObject
                                      animated:YES];
                        }];
                    }
                } else {
                    if (self.overlayAnnotations) {
                        for (RoutePin *pin in self.overlayAnnotations) {
                            [self.mapView removeAnnotation:pin];
                        }

                        self.overlayAnnotations = nil;
                    }

                    double distance = [self
                        metersFromPixel:(15 * nearestPolysPins.count) / 2.0
                                atPoint:touchPt];

                    double radiansBetweenAnnotations =
                        (M_PI * 2) / nearestPolysPins.count;

                    NSInteger hits = nearestPolysPins.count;

                    if (hits > 1) {
                        // Show pins in a circle around the point touched
                        int i = 0;

                        for (RoutePin *pin in nearestPolysPins) {
                            double heading = radiansBetweenAnnotations * i;
                            CLLocationCoordinate2D newCoordinate =
                                [MapViewController
                                    calculateCoordinateFrom:coord
                                                  onBearing:heading
                                                 atDistance:distance];
                            pin.touchPosition = newCoordinate;
                            [self.mapView addAnnotation:pin];
                            i++;
                        }
                    } else {
                        RoutePin *pin = nearestPolysPins.anyObject;
                        pin.touchPosition = coord;
                        [self.mapView addAnnotation:pin];
                    }

                    self.overlayAnnotations = nearestPolysPins;

                    bool found = NO;

                    for (id<MKAnnotation> annot in self.mapView
                             .selectedAnnotations) {
                        for (RoutePin *p in self.overlayAnnotations) {
                            if ([p isEqual:annot]) {
                                found = YES;
                                break;
                            }
                        }
                    }

                    if (!found) {
                        [self delayedBlock:^{
                          [self.mapView
                              selectAnnotation:self.overlayAnnotations.anyObject
                                      animated:YES];
                        }];
                    }
                }
            }

            /*
             else if (self.touchAnnotation)
             {
             for (RoutePolyline *poly in self.touchAnnotation)
             {
             [self.mapView removeAnnotation:poly];
             }
             self.touchAnnotation = nil;
             }
             */
        }
    }
}

// Implement viewDidLoad to do additional setup after loading the view,
// typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

    // Get the size of the diagonal
    CGRect mapViewRect = [self calculateFrame];

    self.mapView = [[MKMapView alloc] initWithFrame:mapViewRect];
    self.mapView.showsUserLocation = TRUE;
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.delegate = self;
    self.mapView.autoresizingMask =
        (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

    [self addDataToMap:YES animate:NO];

    [self.view insertSubview:self.mapView atIndex:0];

    // Add Gesture Recognizer to MapView to detect taps
    UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(handleTap:)];

    // we require all gesture recognizer except other single-tap gesture
    // recognizers to fail
    for (UIGestureRecognizer *gesture in self.view.gestureRecognizers) {
        if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
            UITapGestureRecognizer *systemTap =
                (UITapGestureRecognizer *)gesture;

            if (systemTap.numberOfTapsRequired > 1) {
                [tap requireGestureRecognizerToFail:systemTap];
            }
        } else {
            [tap requireGestureRecognizerToFail:gesture];
        }
    }

    [self.mapView addGestureRecognizer:tap];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[RouteMultiPolyline class]]) {
        return [(RouteMultiPolyline *)overlay renderer];
    }

    return [[MKCircleRenderer alloc]
        initWithCircle:[MKCircle circleWithMapRect:MKMapRectNull]];
    ;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self updateOverlayLineWidthForMapView:mapView];
}

- (void)updateOverlayLineWidthForMapView:(MKMapView *)mapView {
    CGFloat zoomScale =
        mapView.bounds.size.width / mapView.visibleMapRect.size.width;

    for (id<MKOverlay> overlay in mapView.overlays) {
        MKOverlayRenderer *renderer = [mapView rendererForOverlay:overlay];
        if ([renderer isKindOfClass:[MKOverlayPathRenderer class]]) {
            MKOverlayPathRenderer *pathRenderer =
                (MKOverlayPathRenderer *)renderer;
            pathRenderer.lineWidth = MAX(zoomScale * 2.0, 1);
            [pathRenderer invalidatePath];
        }
    }
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    [self removeOverlays];

    // Release any cached data, images, etc that aren't in use.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.prompt = self.msgText;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.displayLink =
        [CADisplayLink displayLinkWithTarget:self
                                    selector:@selector(displayLinkFired:)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                           forMode:NSRunLoopCommonModes];
}

- (void)viewWillDisappear:(BOOL)animated {
    DEBUG_FUNC();

    // [UIView setAnimationsEnabled:NO];
    self.navigationItem.prompt = nil;
    // [UIView setAnimationsEnabled:YES];

    if (self.userActivity != nil) {
        [self.userActivity invalidate];
        self.userActivity = nil;
    }

    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    // Drop the heading part if the view disappears, but keep the tracking part
    if (self.compassButton &&
        self.mapView.userTrackingMode != MKUserTrackingModeNone) {
        self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    }

    [self.displayLink invalidate];
    self.displayLink = nil;

    [super viewDidDisappear:animated];
}

#pragma mark MapView functions

- (void)didEnterBackground {
    // It can crash if overlays are left behind
    [self removeOverlays];
    [super didEnterBackground];
}

- (void)didBecomeActive {
    [self addDataToMap:NO animate:NO];
    [super didBecomeActive];
}

- (MKAnnotationView *)mapView:(MKMapView *)mv
            viewForAnnotation:(id<MKAnnotation>)annotation {
    MKAnnotationView *retView = nil;

    if (annotation == self.mapView.userLocation) {
        return nil;
    } else {
        if ([annotation conformsToProtocol:@protocol(MapPin)]) {
            retView = [BearingAnnotationView viewForPin:(id<MapPin>)annotation
                                                mapView:self.mapView
                                              urlAction:self.linkActionForPin];
        }

        if ([DepartureTimesViewController canGoDeeper]) {
            retView.rightCalloutAccessoryView =
                [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        } else {
            retView.rightCalloutAccessoryView = nil;
        }

        retView.canShowCallout = YES;
    }

    return retView;
}

- (void)mapView:(MKMapView *)mapView
    didSelectAnnotationView:(MKAnnotationView *)view {
    if (_segPrevNext &&
        ([view.annotation conformsToProtocol:@protocol(MapPin)])) {
        for (int i = 0; i < self.annotations.count; i++) {
            if (view.annotation == self.annotations[i]) {
                _selectedAnnotation = i;
                [self setSegText:_segPrevNext];
                break;
            }
        }
    }
}

+ (void)actionIfAppInstalled:(UIAlertController *)alert
                         url:(NSString *)url
                       title:(NSString *)title
                      action:
                          (void (^__nullable)(UIAlertAction *action))handler {
    DEBUG_LOG_NSString(url);
    DEBUG_LOG_NSString(title);

    if ([[UIApplication sharedApplication]
            canOpenURL:[NSURL URLWithString:url]]) {
        DEBUG_LOG(@"open");
        [alert
            addAction:[UIAlertAction actionWithTitle:title
                                               style:UIAlertActionStyleDefault
                                             handler:handler]];
    }
}

- (void)mapView:(MKMapView *)mapView
                   annotationView:(MKAnnotationView *)view
    calloutAccessoryControlTapped:(UIControl *)control {
    id<MapPin> tappedAnnot = (id<MapPin>)view.annotation;

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:tappedAnnot.title
                         message:nil
                  preferredStyle:UIAlertControllerStyleActionSheet];

    [alert addAction:
               [UIAlertAction
                   actionWithTitle:NSLocalizedString(@"Show in Apple map app",
                                                     "map action")
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *action) {
                             NSString *url = nil;
                             url = [NSString
                                 stringWithFormat:[WebViewController
                                                      namedURL:@"Apple Maps 2"],
                                                  tappedAnnot.title
                                                      .fullyPercentEncodeString,
                                                  COORD_TO_LAT_LNG_STR(
                                                      tappedAnnot.coordinate)];

                             [[UIApplication sharedApplication]
                                 compatOpenURL:[NSURL URLWithString:url]];
                           }]];

    UIApplication *app = [UIApplication sharedApplication];

    const CGFloat side = 1;
    CGRect frame = control.frame;
    CGRect sourceRect =
        CGRectMake((frame.size.width - side) / 2.0,
                   (frame.size.height - side) / 2.0, side, side);

#define PROTOCOL_GOOGLE_MAPS @"https:"

    [MapViewController
        actionIfAppInstalled:alert
                         url:PROTOCOL_GOOGLE_MAPS
                       title:NSLocalizedString(@"Show in Google maps",
                                               "map action")
                      action:^(UIAlertAction *action) {
                        NSString *url = [WebViewController
                            namedURL:@"Google Maps"
                               param:COORD_TO_LAT_LNG_STR(
                                         tappedAnnot.coordinate)];

                        [app compatOpenURL:[NSURL URLWithString:url]];
                      }];

#define PROTOCOL_WAZE @"https:"

    [MapViewController
        actionIfAppInstalled:alert
                         url:PROTOCOL_WAZE
                       title:NSLocalizedString(@"Navigate here using Waze",
                                               "map action")
                      action:^(UIAlertAction *action) {
                        NSString *url = [WebViewController
                            namedURL:@"Waze"
                               param:COORD_TO_LAT_LNG_STR(
                                         tappedAnnot.coordinate)];

                        [app compatOpenURL:[NSURL URLWithString:url]];
                      }];

#define PROTOCOL_MOTION_X_GPS @"motionxgps:"

    [MapViewController
        actionIfAppInstalled:alert
                         url:PROTOCOL_MOTION_X_GPS
                       title:NSLocalizedString(@"Import to MotionX-GPS",
                                               "map action")
                      action:^(UIAlertAction *action) {
                        NSString *url = [NSString
                            stringWithFormat:
                                PROTOCOL_MOTION_X_GPS
                                @"//addWaypoint?name=%@&lat=%@&lon=%@",
                                tappedAnnot.title.fullyPercentEncodeString,
                                COORD_TO_STR(tappedAnnot.coordinate.latitude),
                                COORD_TO_STR(tappedAnnot.coordinate.longitude)];

                        [app compatOpenURL:[NSURL URLWithString:url]];
                      }];

#define PROTOCOL_MOTION_X_GPS_HD @"motionxgpshd:"

    [MapViewController
        actionIfAppInstalled:alert
                         url:PROTOCOL_MOTION_X_GPS_HD
                       title:NSLocalizedString(@"Import to MotionX-GPS HD",
                                               "map action")
                      action:^(UIAlertAction *action) {
                        NSString *url = [NSString
                            stringWithFormat:
                                PROTOCOL_MOTION_X_GPS_HD
                                @"//addWaypoint?name=%@&lat=%@&lon=%@",
                                tappedAnnot.title.fullyPercentEncodeString,
                                COORD_TO_STR(tappedAnnot.coordinate.latitude),
                                COORD_TO_STR(tappedAnnot.coordinate.longitude)];

                        [app compatOpenURL:[NSURL URLWithString:url]];
                      }];

    [alert
        addAction:
            [UIAlertAction
                actionWithTitle:NSLocalizedString(@"Share...", @"button text")
                          style:UIAlertActionStyleDefault
                        handler:^(UIAlertAction *action) {
                          NSArray *activities = @[ [NSURL
                              URLWithString:
                                  [WebViewController
                                      namedURL:@"Apple Maps"
                                         param:COORD_TO_LAT_LNG_STR(
                                                   tappedAnnot.coordinate)]] ];

                          UIActivityViewController *activityViewControntroller =
                              [[UIActivityViewController alloc]
                                  initWithActivityItems:activities
                                  applicationActivities:nil];
                          activityViewControntroller.excludedActivityTypes =
                              @[];

                          if ([[UIDevice currentDevice] userInterfaceIdiom] ==
                              UIUserInterfaceIdiomPad) {
                              activityViewControntroller
                                  .popoverPresentationController.sourceView =
                                  control;
                              activityViewControntroller
                                  .popoverPresentationController.sourceRect =
                                  sourceRect;
                          }

                          [self presentViewController:activityViewControntroller
                                             animated:true
                                           completion:nil];
                        }]];

    [alert addAction:[UIAlertAction
                         actionWithTitle:NSLocalizedString(@"Cancel",
                                                           @"button text")
                                   style:UIAlertActionStyleCancel
                                 handler:nil]];

    alert.popoverPresentationController.sourceView = control;
    alert.popoverPresentationController.sourceRect = sourceRect;

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
}

#pragma mark BackgroundTask callbacks

- (void)backgroundTaskDone:(UIViewController *)viewController
                 cancelled:(bool)cancelled {
    if (self.backgroundRefresh) {
        self.backgroundRefresh = false;

        if (!cancelled) {
            [self addDataToMap:NO animate:YES];

            // [[(MainTableViewController *)[self.navigationController
            // topViewController] tableView] reloadData];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        if (!cancelled) {
            [self.navigationController pushViewController:viewController
                                                 animated:YES];
        }
    }
}

- (UIInterfaceOrientation)backgroundTaskOrientation {
    return [UIApplication sharedApplication].compatStatusBarOrientation;
}

- (void)updateAnnotations {
    for (id<MKAnnotation> annotation in self.mapView.annotations) {

        BearingAnnotationView *bearingView =
            [self bearingViewForAnnotation:annotation];

        if (bearingView) {
            [bearingView updateDirectionalAnnotationView:self.mapView];
        }
    }
}

- (void)displayLinkFired:(id)sender {
    if (self.mapView) {
        double difference =
            ABS(self.previousHeading - self.mapView.camera.heading);

        if (difference < .001) {
            return;
        }

        self.previousHeading = self.mapView.camera.heading;

        [self updateAnnotations];
    }
}

- (void)updateOverlays {
    ProgressModalView *modal = nil;
    DEBUG_LOG_long(self.shapes.count);

    DEBUG_LOG_long(UIApplication.sharedApplication.applicationState);
    if (UIApplication.sharedApplication.applicationState !=
        UIApplicationStateBackground) {
        if (self.backgroundTask && self.backgroundTask.progressModal == nil &&
            self.shapes.count > 5) {

            UIViewController *top = UIApplication.topViewController;

            modal = [[ProgressModalView alloc]
                initWithParent:top.view.superview
                         items:1
                         title:@"Updating map"
                      delegate:nil
                   orientation:self.backgroundTaskOrientation];
            [top.view addSubview:modal];
            [top.view bringSubviewToFront:modal];
            [top.view layoutSubviews];

            // Delay executionro allow modal to go up
            MainTaskDelay(0.1, ^{
              DEBUG_LOG(@"Updating polys");
              [self removeOverlays];
              [self addDataToMap:NO animate:NO];

              if (modal) {
                  [modal removeFromSuperview];
              }
              DEBUG_LOG(@"Done");
            });
        } else {
            [self removeOverlays];
            [self addDataToMap:NO animate:NO];
        }
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    DEBUG_LOG_long(previousTraitCollection.userInterfaceStyle);
    DEBUG_LOG_long(self.traitCollection.userInterfaceStyle);

    if (previousTraitCollection.userInterfaceStyle !=
        self.traitCollection.userInterfaceStyle) {
        [self updateOverlays];
    };
}

@end
