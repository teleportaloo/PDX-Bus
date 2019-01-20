//
//  MapViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/17/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapViewController.h"
#import <MapKit/MapKit.h>
#import <MapKit/MkAnnotation.h>
#import "DepartureData.h"
#import "XMLDepartures.h"
#import "MapPinColor.h"
#import "DepartureTimesView.h"
#import "DepartureDetailView.h"
#import "QuartzCore/QuartzCore.h"
#import "DepartureData+iOSUI.h"
#import "BearingAnnotationView.h"
#import "RoutePolyline.h"
#import "RoutePin.h"

#define kPrev  NSLocalizedString(@"Prev", @"Short button text for previous")
#define kStart NSLocalizedString(@"Start", @"Short button text for start")
#define kNext  NSLocalizedString(@"Next", @"Short button text for next")
#define kEnd   NSLocalizedString(@"End", @"Short button text for end")

#define kNoButton -1


@implementation MapViewController

- (void)dealloc {
    self.mapView.delegate = nil;
    self.mapView.showsUserLocation=FALSE;
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    if (self.displayLink)
    {
        [self.displayLink invalidate];
    }
   
    
    // A bug in the SDK means that releasing a mapview can cause a crash as it may be animating
    // we delay 4 seconds for the release.
    // [_mapView retain];
    [_mapView performSelector:@selector(self) withObject:nil afterDelay:(NSTimeInterval)4.0];
}

- (instancetype)init {
    if ((self = [super init]))
    {
        self.title = NSLocalizedString(@"Transit Map", @"page title");
        self.annotations = [NSMutableArray array];
    }
    return self;
}

#pragma mark Helper functions

- (void)addPin:(id<MapPinColor>) pin
{
    [self.annotations addObject:pin];
}

- (bool)hasXML
{
    return NO;
}

#pragma mark Prev/Next Segment controller

- (void)setSegText:(UISegmentedControl*)seg
{
    if (_selectedAnnotation > 1)
    {
        [seg setTitle:kPrev forSegmentAtIndex:0];
    }
    else {
        [seg setTitle:kStart forSegmentAtIndex:0];
    }

    if (_selectedAnnotation <  self.annotations.count-2)
    {
        [seg setTitle:kNext forSegmentAtIndex:1];
    }
    else {
        [seg setTitle:kEnd forSegmentAtIndex:1];
    }
}

- (void)prevNext:(id)sender
{
    UISegmentedControl *segControl = sender;
    switch (segControl.selectedSegmentIndex)
    {
        case 0:    // UIPickerView
        {
            // Prev
            if (_selectedAnnotation > 0)
            {
                _selectedAnnotation--;
                
            }
            break;
        }
        case 1:    // UIPickerView
        {
            if (_selectedAnnotation < (self.annotations.count-1) )
            {
                _selectedAnnotation++;
            }
            break;
        }
    }
    
    [self setSegText:segControl];
    
    [self.mapView deselectAnnotation:self.annotations[_selectedAnnotation] animated:NO];
    [self.mapView selectAnnotation:self.annotations[_selectedAnnotation] animated:YES];
}


#pragma mark UI Callbacks

- (void)toggleMap:(id)sender
{
    UISegmentedControl *segControl = sender;
    switch (segControl.selectedSegmentIndex)
    {
        case 0:    // UIPickerView
        {
            self.mapView.mapType = MKMapTypeStandard;
            break;
        }
        case 1:    // UIPickerView
        {
            self.mapView.mapType = MKMapTypeHybrid;
            break;
        }
    }
}

- (NSMutableString *)safeString:(NSString *)str
{
    NSMutableString *newStr = [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding].mutableCopy;
    
    static NSDictionary *replacements = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        replacements = @{
                         @"%2F" : @"/",
                         @"%26" : @"&",
                         @"%23" : @"#",
                         @"%2B" : @"+",
                         @"%3A" : @":",
                         @"%3D" : @"=",
                        };
    });
    
    [replacements enumerateKeysAndObjectsUsingBlock: ^void (NSString* key, NSString* original, BOOL *stop)
     {
         [newStr replaceOccurrencesOfString:original withString:key options:NSCaseInsensitiveSearch range:NSMakeRange(0, newStr.length)];
     }];
    
    return newStr;
}

#pragma mark ViewControllerBase methods

-(void)infoAction:(id)sender
{
    UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Info", @"alert title")
                                                       message:NSLocalizedString(@"The route path does not reflect future service changes until they come into effect.\n"
                                                                "Route and arrival data provided by permission of TriMet.", @"trip planner information")
                                                      delegate:nil
                                             cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
                                             otherButtonTitles:nil ];
    [alert show];
    
    
}

- (void) updateToolbarItems:(NSMutableArray *)toolbarItems
{
    // add a segmented control to the button bar
    UISegmentedControl    *buttonBarSegmentedControl;
    buttonBarSegmentedControl = [[UISegmentedControl alloc] initWithItems:
                                 @[@"Map", @"Hybrid"]];
    [buttonBarSegmentedControl addTarget:self action:@selector(toggleMap:) forControlEvents:UIControlEventValueChanged];
    buttonBarSegmentedControl.selectedSegmentIndex = 0.0;    // start by showing the normal picker
    
    UIBarButtonItem *zoom = [[UIBarButtonItem alloc]
                              initWithImage:[TableViewWithToolbar getToolbarIcon:kIconEye]
                              style:UIBarButtonItemStylePlain
                              target:self action:@selector(fitToViewAction:)];
    
    
    
    [toolbarItems addObjectsFromArray:@[[UIToolbar flexSpace],  zoom, [UIToolbar flexSpace]]];
    
    if ([MKMapView instancesRespondToSelector:@selector(setUserTrackingMode:animated:)])
    {
        self.compassButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    }
    
    if (self.compassButton)
    {
        [toolbarItems addObjectsFromArray:@[self.compassButton, [UIToolbar flexSpace]]];
    }
    
    UIBarButtonItem *segItem = [[UIBarButtonItem alloc] initWithCustomView:buttonBarSegmentedControl];
    
    [toolbarItems addObject:segItem];
    
    if (self.lineOptions != MapViewNoLines && self.nextPrevButtons)
    {
        // create the system-defined "OK or Done" button
        UIBarButtonItem *info = [[UIBarButtonItem alloc]
                                  initWithTitle:NSLocalizedString(@"info", @"button text")
                                  style:UIBarButtonItemStylePlain
                                  target:self action:@selector(infoAction:)];
        
        [toolbarItems addObjectsFromArray:@[[UIToolbar flexSpace],  info]];
    }
    
    if (self.hasXML)
    {
        [toolbarItems addObject:[UIToolbar flexSpace]];
        [self updateToolbarItemsWithXml:toolbarItems];
    }
    else
    {
        [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
    }
    
}


- (void)removeAnnotations
{
    NSArray *oldAnnotations = self.mapView.annotations;
    
    if (oldAnnotations !=nil && oldAnnotations.count >0)
    {
        [self.mapView removeAnnotations:oldAnnotations];
    }
    
}

#pragma mark View functions

- (void)fitToViewAction:(id)unused
{
    [self fitToView];
}

- (bool)fitAnnotation:(id<MapPinColor>)pin
{
    return YES;
}

- (void)fitToView
{
    NSMutableArray<id<MapPinColor>> *pinsToFit = [NSMutableArray array];
    if (self.annotations!=nil)
    {
        for (id<MapPinColor> pin in self.annotations)
        {
            if ([self fitAnnotation:pin])
            {
                [pinsToFit addObject:pin];
            }
        }
    }
    
    NSInteger pins = pinsToFit.count;
    NSUInteger lines = 0;
    
    if (self.lineCoords && (self.lineOptions==MapViewFitLines || pins == 0))
    {
        lines = self.lineCoords.count;
    }
    
    // Walk the list of overlays and annotations and create a MKMapRect that
    // bounds all of them and store it into flyTo.
    
    
    if (pins == 1 && lines == 0)
    {
        
        /*Region and Zoom*/
        MKCoordinateRegion region;
        region.center.latitude = 0.0;
        region.center.longitude = 0.0;
        MKCoordinateSpan span;
        span.latitudeDelta=0.005;
        span.longitudeDelta=0.005;
        
        region.span=span;
        
        if (self.annotations != nil && self.annotations.count > 0)
        {
            region.center = self.annotations.firstObject.coordinate;
        }

        [self.mapView regionThatFits:region];
        [self.mapView setRegion:region animated:TRUE];
    }
    else
    {
        MKMapRect flyTo = MKMapRectNull;
        
        for(id<MapPinColor> pin in pinsToFit)
        {
            DEBUG_LOG(@"Coords %f %f %@\n", pin.coordinate.latitude, pin.coordinate.longitude, [pin title]);
            MKMapPoint annotationPoint = MKMapPointForCoordinate(pin.coordinate);
            MKMapRect pointRect = MakeMapRectWithPointAtCenter(annotationPoint.x, annotationPoint.y, 300, 1000);
            flyTo = MKMapRectUnion(flyTo, pointRect);
        }
        
        if (lines > 0)
        {
            for(ShapeRoutePath *path in self.lineCoords)
            {
                for (ShapeSegment *seg in path.segments)
                {
                    NSUInteger i;
                    CLLocationCoordinate2D *c;
                    ShapeCompactSegment *compact = seg.compact;
                    
                    for (i=0, c = compact.coords; i< compact.count; i++, c++)
                    {
                        MKMapPoint annotationPoint = MKMapPointForCoordinate(*c);
                        MKMapRect pointRect = MakeMapRectWithPointAtCenter(annotationPoint.x, annotationPoint.y, 300, 1000);
                        flyTo = MKMapRectUnion(flyTo, pointRect);
                    }
                }
            }
        }
        
        UIEdgeInsets insets = {
            100, 30,
            60, 30
        };
        
        [self.mapView setVisibleMapRect:[self.mapView mapRectThatFits:flyTo edgePadding:insets] animated:YES];
    }
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)addDataToMap:(bool)zoom {
  

    [self removeAnnotations];
    
    {
        NSArray *oldOverlays = self.mapView.overlays;
        
        if (oldOverlays !=nil && oldOverlays.count >0)
        {
            [self.mapView removeOverlays:oldOverlays];
        }
        
    }
    

    if (self.lineCoords != nil && self.nextPrevButtons)
    {
        _segPrevNext = [[UISegmentedControl alloc] initWithItems:@[kPrev,kNext] ];
        _segPrevNext.frame = CGRectMake(0, 0, 80, 30.0);
        _segPrevNext.momentary = YES;
        [_segPrevNext addTarget:self action:@selector(prevNext:) forControlEvents:UIControlEventValueChanged];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView: _segPrevNext];
        
        _selectedAnnotation = 0;
        
        [self setSegText:_segPrevNext];
        
    }
    
    if (self.annotations != nil)
    {
        for (id<MKAnnotation> annotation in self.annotations)
        {
            [self.mapView addAnnotation:annotation];
        }
    }
    
    if (self.lineOptions!=MapViewNoLines && self.lineCoords.count > 0) { // overlays!
        self.routePolyLines = [NSMutableArray array];
        for (ShapeRoutePath *path in self.lineCoords)
        {
            [path addPolylines:self.routePolyLines];
        }
        [self.mapView addOverlays:self.routePolyLines];
    }
    
    if (self.circle)
    {
        [self.mapView addOverlay:self.circle];
        
    }
    
    if (zoom)
    {
        [self fitToView];
    }
    
    [self updateToolbar];
}

- (void)modifyMapViewFrame:(CGRect *)frame
{
    
}

- (void)reloadData
{
    [super reloadData];
    self.mapView.frame = [self calculateFrame];
}

-(CGRect)calculateFrame
{
    CGRect mapViewRect = self.middleWindowRect;
    [self modifyMapViewFrame:&mapViewRect];
    return mapViewRect;
}




/** Returns the distance of |pt| to |poly| in meters
 *
 * from http://paulbourke.net/geometry/pointlineplane/DistancePoint.java
 *
 */
- (double)distanceOfPoint:(MKMapPoint)pt toPoly:(MKPolyline *)poly
{
    double distance = MAXFLOAT;
    
    MKMapPoint* ptA = poly.points;
    MKMapPoint* ptB = poly.points+1;
    
    for (int n = 0; n < poly.pointCount - 1; n++,ptA++,ptB++) {
        double xDelta = ptB->x - ptA->x;
        double yDelta = ptB->y - ptA->y;
        
        if (xDelta == 0.0 && yDelta == 0.0) {
            
            // Points must not be equal
            continue;
        }
        double u = ((pt.x - ptA->x) * xDelta + (pt.y - ptA->y) * yDelta) / (xDelta * xDelta + yDelta * yDelta);
        MKMapPoint ptClosest;
        if (u < 0.0) {
            
            ptClosest = *ptA;
        }
        else if (u > 1.0) {
            
            ptClosest = *ptB;
        }
        else {
            
            ptClosest = MKMapPointMake(ptA->x + u * xDelta, ptA->y + u * yDelta);
        }
        CLLocationDistance closest = MKMetersBetweenMapPoints(ptClosest, pt);
        distance = MIN(distance, closest);
    }
    
    return distance;
}

/** Converts |px| to meters at location |pt| */
- (double)metersFromPixel:(NSUInteger)px atPoint:(CGPoint)pt
{
    CGPoint ptB = CGPointMake(pt.x + px, pt.y);
    
    CLLocationCoordinate2D coordA = [self.mapView convertPoint:pt toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D coordB = [self.mapView convertPoint:ptB toCoordinateFromView:self.mapView];
    
    return MKMetersBetweenMapPoints(MKMapPointForCoordinate(coordA), MKMapPointForCoordinate(coordB));
}

- (void)delayedBlock:(dispatch_block_t)block
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(),block);
}


+ (CLLocationCoordinate2D)calculateCoordinateFrom:(CLLocationCoordinate2D)coordinate onBearing:(double)bearingInRadians atDistance:(double)distanceInMetres {
    
    double coordinateLatitudeInRadians = coordinate.latitude * M_PI / 180;
    double coordinateLongitudeInRadians = coordinate.longitude * M_PI / 180;
    
    double distanceComparedToEarth = distanceInMetres / 6378100;
    
    double resultLatitudeInRadians = asin(sin(coordinateLatitudeInRadians) * cos(distanceComparedToEarth) + cos(coordinateLatitudeInRadians) * sin(distanceComparedToEarth) * cos(bearingInRadians));
    double resultLongitudeInRadians = coordinateLongitudeInRadians + atan2(sin(bearingInRadians) * sin(distanceComparedToEarth) * cos(coordinateLatitudeInRadians), cos(distanceComparedToEarth) - sin(coordinateLatitudeInRadians) * sin(resultLatitudeInRadians));
    
    CLLocationCoordinate2D result;
    result.latitude = resultLatitudeInRadians * 180 / M_PI;
    result.longitude = resultLongitudeInRadians * 180 / M_PI;
    return result;
}

#define MAX_DISTANCE_PX 22.0f
// #define MAX_DISTANCE_PX 75.0f
- (void)handleTap:(UITapGestureRecognizer *)tap
{
    if ((tap.state & UIGestureRecognizerStateRecognized) == UIGestureRecognizerStateRecognized) {
        
        // Get map coordinate from touch point
        CGPoint touchPt = [tap locationInView:self.mapView];
        CLLocationCoordinate2D coord = [self.mapView convertPoint:touchPt toCoordinateFromView:self.mapView];
        
        UIView *touchedView = [self.mapView hitTest:touchPt withEvent:nil];
        
        if ([touchedView isKindOfClass:[MKAnnotationView class]])
        {
            //annotation view was tapped, select it...
            id<MKAnnotation> annot =  ((MKAnnotationView *)touchedView).annotation;
            [self.mapView selectAnnotation:annot animated:YES];
        }
        else
        {
            double maxMeters = [self metersFromPixel:MAX_DISTANCE_PX atPoint:touchPt];
            
            float nearestDistance = MAXFLOAT;
            NSMutableSet<RoutePin*> *nearestPolysPins = [NSMutableSet set];
            
            // RoutePolyline *nearestPoly = nil;
            
            // for every overlay ...
            for (id <MKOverlay> overlay in self.mapView.overlays) {
                
                // .. if MKPolyline ...
                if ([overlay isKindOfClass:[RoutePolyline class]]) {
                    
                    // ... get the distance ...
                    float distance = [self distanceOfPoint:MKMapPointForCoordinate(coord)
                                                    toPoly:overlay];
                    
                    // ... and find the nearest one
                    if (distance < nearestDistance) {
                        
                        nearestDistance = distance;
                        [nearestPolysPins removeAllObjects];
                        [nearestPolysPins addObject:((RoutePolyline*)overlay).routePin];
                    }
                    if (distance == nearestDistance)
                    {
                        [nearestPolysPins addObject:((RoutePolyline*)overlay).routePin];
                    }
                }
            }
            
            DEBUG_LOGF(nearestDistance);
            DEBUG_LOGF(maxMeters);
            
            if (nearestDistance <= maxMeters) {
                // Add a special pin at this point and show the callout.  The pin is for the route.
                bool reselect = NO;
                
                // If the previous selection near to the current touch
                if ([self.overlayAnnotations isEqualToSet:nearestPolysPins])
                {
                    RoutePin *old = self.overlayAnnotations.anyObject;
                    CGPoint oldPoint = [self.mapView convertCoordinate:old.coordinate toPointToView:self.mapView];
                    
                    CGFloat xGap = oldPoint.x - touchPt.x;
                    CGFloat yGap = oldPoint.y - touchPt.y;
                    CGFloat distSq = yGap * yGap + xGap * xGap;
                    
                    if (distSq < 50.0*50.0)
                    {
                        reselect = YES;
                    }
                }
                
                if (reselect)
                {
                    [self delayedBlock:^{
                        bool found = NO;
                        for (id<MKAnnotation> annot in self.mapView.selectedAnnotations)
                        {
                            for (RoutePin *p in self.overlayAnnotations)
                            {
                                if ([p isEqual:annot])
                                {
                                    found = YES;
                                    [self.mapView selectAnnotation:p animated:YES];
                                }
                            }
                        }
                        
                        if (!found)
                        {
                            [self.mapView selectAnnotation:self.overlayAnnotations.anyObject animated:YES];
                        }
                    }];
                }
                else
                {
                    if (self.overlayAnnotations)
                    {
                        for (RoutePin *pin in self.overlayAnnotations)
                        {
                            [self.mapView removeAnnotation:pin];
                        }
                        self.overlayAnnotations = nil;
                    }
                    
                    double distance = [self metersFromPixel:(15 * nearestPolysPins.count) / 2.0 atPoint:touchPt];
                    
                    double radiansBetweenAnnotations = (M_PI * 2) / nearestPolysPins.count;
                    
                    NSInteger hits = nearestPolysPins.count;
                    
                    if  (hits > 1)
                    {
                        // Show pins in a circle around the point touched
                        int i=0;
                        for (RoutePin *pin in nearestPolysPins) {
                            double heading = radiansBetweenAnnotations * i;
                            CLLocationCoordinate2D newCoordinate = [MapViewController calculateCoordinateFrom:coord onBearing:heading atDistance:distance];
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
                
                    [self delayedBlock:^{
                        bool found = NO;
                        for (id<MKAnnotation> annot in self.mapView.selectedAnnotations)
                        {
                            for (RoutePin *p in self.overlayAnnotations)
                            {
                                if ([p isEqual:annot])
                                {
                                    found = YES;
                                    break;
                                }
                            }
                        }
                        
                        if (!found)
                        {
                            [self.mapView selectAnnotation:self.overlayAnnotations.anyObject animated:YES];
                        }
                    }];
                    
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

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Get the size of the diagonal
    CGRect mapViewRect = [self calculateFrame];
    
    self.mapView=[[MKMapView alloc] initWithFrame:mapViewRect];
    self.mapView.showsUserLocation=TRUE;
    self.mapView.mapType=MKMapTypeStandard;
    self.mapView.delegate=self;
    self.mapView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    
    [self addDataToMap:YES];
    
    [self.view insertSubview:self.mapView atIndex:0];
    
    // Add Gesture Recognizer to MapView to detect taps
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    
    // we require all gesture recognizer except other single-tap gesture recognizers to fail
    for (UIGestureRecognizer *gesture in self.view.gestureRecognizers) {
        if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
            UITapGestureRecognizer *systemTap = (UITapGestureRecognizer *)gesture;
            
            if (systemTap.numberOfTapsRequired > 1) {
                [tap requireGestureRecognizerToFail:systemTap];
            }
        } else {
            [tap requireGestureRecognizerToFail:gesture];
        }
    }
    
    [self.mapView addGestureRecognizer:tap];
    
}


- (MKOverlayRenderer*)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[RoutePolyline class]])
    {
        return [(RoutePolyline *)overlay renderer];
    }
    else if (overlay == self.circle)
    {
        MKCircleRenderer *circleView = [[MKCircleRenderer alloc] initWithCircle:overlay];
        circleView.strokeColor = [UIColor greenColor];
        circleView.lineWidth = 3.0;
        return circleView;
    }
    
    return [[MKCircleRenderer alloc] initWithCircle:[MKCircle circleWithMapRect:MKMapRectNull]];
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.prompt = self.msgText;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkFired:)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void) viewWillDisappear:(BOOL)animated
{
    DEBUG_FUNC();
    
    // [UIView setAnimationsEnabled:NO];
    self.navigationItem.prompt = nil;
    // [UIView setAnimationsEnabled:YES];
    
    if (self.userActivity!=nil)
    {
        [self.userActivity invalidate];
        self.userActivity = nil;
    }
    
    [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
    // Drop the heading part if the view disappears, but keep the tracking part
    if (self.compassButton && self.mapView.userTrackingMode != MKUserTrackingModeNone)
    {
        self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    }
    
    [self.displayLink invalidate];
    self.displayLink = nil;
    
    [super viewDidDisappear:animated];
}


#pragma mark MapView functions

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKAnnotationView *retView = nil;
    
    if (annotation == self.mapView.userLocation)
    {
        return nil;
    }
    else
    {
        if ([annotation conformsToProtocol:@protocol(MapPinColor)])
        {
            retView = [BearingAnnotationView viewForPin:(id<MapPinColor>)annotation mapView:self.mapView];
        }
        
        if ( [ DepartureTimesView canGoDeeper ] ) // && [pin showActionMenu])
        {
            retView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        }
        else
        {
            retView.rightCalloutAccessoryView = nil;
        }
        
        retView.canShowCallout = YES;

    }
    return retView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if (_segPrevNext && ([view.annotation conformsToProtocol:@protocol(MapPinColor)]))
    {
        for (int i=0; i<self.annotations.count; i++)
        {
            if (view.annotation == self.annotations[i])
            {
                _selectedAnnotation = i;
                [self setSegText:_segPrevNext];
                break;
            }
        }
    }
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    id<MapPinColor> tappedAnnot = (id<MapPinColor>)view.annotation;
    
    NSString *action = nil;
    NSString *stopIdAction = nil;
    
    if ([tappedAnnot showActionMenu])
    {
        // action = @"Show details";
        if ([tappedAnnot respondsToSelector: @selector(mapTapped:)]) //  && [self.tappedAnnot mapTapped])
        {
            action = nil;
            
            if ([tappedAnnot respondsToSelector:@selector(tapActionText)])
            {
                action = [tappedAnnot tapActionText];
            }
            if (action == nil)
            {
                action = NSLocalizedString(@"Choose this stop", @"button text");
            }
        }
        else if ([tappedAnnot respondsToSelector: @selector(mapDeparture)])
        {
            action = NSLocalizedString(@"Show details", @"button text");
        }
        
        
        if ([tappedAnnot respondsToSelector: @selector(mapStopId)])
        {
            if ([tappedAnnot respondsToSelector: @selector(mapStopIdText)])
            {
                stopIdAction = [tappedAnnot mapStopIdText];
            }
            else
            {
                stopIdAction = NSLocalizedString(@"Show arrivals", @"button text");
            }
        }
    }
    
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:tappedAnnot.title
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    
    
    if (stopIdAction !=nil)
    {
        [alert addAction:[UIAlertAction actionWithTitle:stopIdAction
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action){
                                                    if ([tappedAnnot respondsToSelector: @selector(mapStopId)])
                                                    {
                                                        DepartureTimesView *departureViewController = [DepartureTimesView viewController];
                                                        departureViewController.callback = self.callback;
                                                        [departureViewController fetchTimesForLocationAsync:self.backgroundTask loc:[tappedAnnot mapStopId]];
                                                    }
                                                }]];
    }
    
    if (action !=nil)
    {
        [alert addAction:[UIAlertAction actionWithTitle:action
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action){
                                                    if ([tappedAnnot respondsToSelector: @selector(mapTapped:)] && [tappedAnnot mapTapped:self.backgroundTask])
                                                    {
                                                        
                                                    }
                                                    else if ([tappedAnnot respondsToSelector: @selector(mapDeparture)])
                                                    {
                                                        DepartureData *departure = [tappedAnnot mapDeparture];
                                                        DepartureDetailView *departureDetailView = [DepartureDetailView viewController];
                                                        departureDetailView.callback = self.callback;
                                                        
                                                        [departureDetailView fetchDepartureAsync:self.backgroundTask dep:departure allDepartures:nil backgroundRefresh:NO];
                                                    }
                                                    
                                                }]];
    }
    
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Show in Apple map app", "map action")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action){
                                                
                                                NSString *url = nil;
                                                url = [NSString stringWithFormat:@"http://maps.apple.com/?q=%f,%f&ll=%f,%f",
                                                       //[self.tappedAnnot.title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                                       tappedAnnot.coordinate.latitude, tappedAnnot.coordinate.longitude,
                                                       tappedAnnot.coordinate.latitude, tappedAnnot.coordinate.longitude];
                                                
                                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
                                            }]];
    
    
    UIApplication *app = [UIApplication sharedApplication];
    
    typedef void (^external_app_block)(NSString *url, NSString *title, void (^handler)(UIAlertAction *action) );

    external_app_block external_app = ^(NSString *url, NSString *title, void (^handler)(UIAlertAction *handler))
    {
        DEBUG_LOGS(url);
        DEBUG_LOGS(title);
        
        if ([app canOpenURL:[NSURL URLWithString:url]])
        {
            DEBUG_LOG(@"open");
            [alert addAction:[UIAlertAction actionWithTitle:title
                                                      style:UIAlertActionStyleDefault
                                                    handler:handler]];
        }
    };
    external_app(@"comgooglemaps:",
                 NSLocalizedString(@"Show in Google map app", "map action"),
                 ^(UIAlertAction *action){
                     NSString *url = [NSString stringWithFormat:@"comgooglemaps://?q=%f,%f@%f,%f",
                                      tappedAnnot.coordinate.latitude, tappedAnnot.coordinate.longitude,
                                      tappedAnnot.coordinate.latitude, tappedAnnot.coordinate.longitude];
                     
                     [app openURL:[NSURL URLWithString:url]];
                 });
    external_app(@"waze:",
                 NSLocalizedString(@"Show in Waze map app", "map action"),
                 ^(UIAlertAction *action){
                     NSString *url = [NSString stringWithFormat:@"waze://?ll=%f,%f",
                                      tappedAnnot.coordinate.latitude, tappedAnnot.coordinate.longitude];
                     
                     [app openURL:[NSURL URLWithString:url]];
                 });
    external_app(@"motionxgps:",
                 NSLocalizedString(@"Import to MotionX-GPS", "map action"),
                 ^(UIAlertAction *action){
                     NSString *url = [NSString stringWithFormat:@"motionxgps://addWaypoint?name=%@&lat=%f&lon=%f",
                                      [self safeString:tappedAnnot.title],
                                      tappedAnnot.coordinate.latitude, tappedAnnot.coordinate.longitude];
                     
                     [app openURL:[NSURL URLWithString:url]];
                 });
    external_app(@"motionxgpshd:",
                 NSLocalizedString(@"Import to MotionX-GPS HD", "map action"),
                 ^(UIAlertAction *action){
                     NSString *url = [NSString stringWithFormat:@"motionxgpshd://addWaypoint?name=%@&lat=%f&lon=%f",
                                      [self safeString:tappedAnnot.title],
                                      tappedAnnot.coordinate.latitude, tappedAnnot.coordinate.longitude];
                     
                     [app openURL:[NSURL URLWithString:url]];
                 });
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"button text") style:UIAlertActionStyleCancel handler:nil]];

    const CGFloat side = 1;
    CGRect frame = control.frame;
    CGRect sourceRect = CGRectMake((frame.size.width - side)/2.0, (frame.size.height-side)/2.0, side, side);
    
    
    alert.popoverPresentationController.sourceView  = control;
    alert.popoverPresentationController.sourceRect = sourceRect;
        
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    
}
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{

}

#pragma mark BackgroundTask callbacks

-(void)backgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled
{
    if (self.backgroundRefresh)
    {
        self.backgroundRefresh = false;
        
        if (!cancelled)
        {
            [self addDataToMap:NO];

            // [[(MainTableViewController *)[self.navigationController topViewController] tableView] reloadData];
        }
        else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else {
        if (!cancelled)
        {
            [self.navigationController pushViewController:viewController animated:YES];
        }
    }    
}


- (UIInterfaceOrientation)backgroundTaskOrientation
{
    return [UIApplication sharedApplication].statusBarOrientation;
}



- (void)updateAnnotations
{
    for (id <MKAnnotation> annotation in self.mapView.annotations)
    {
         MKAnnotationView *av = [self.mapView viewForAnnotation:annotation];
        
        if (av && [av isKindOfClass:[BearingAnnotationView class]])
        {
            BearingAnnotationView *bv = (BearingAnnotationView*)av;
            
            [bv updateDirectionalAnnotationView:self.mapView];
            
        }
        
    }
}

- (void)displayLinkFired:(id)sender
{
    if (self.mapView)
    {
        double difference = ABS(self.previousHeading - self.mapView.camera.heading);
    
        if (difference < .001)
            return;
    
        self.previousHeading = self.mapView.camera.heading;
    
        [self updateAnnotations];
    }
}

@end

