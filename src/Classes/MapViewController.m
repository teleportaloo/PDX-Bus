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

#define kPrev  NSLocalizedString(@"Prev", @"Short button text for previous")
#define kStart NSLocalizedString(@"Start", @"Short button text for start")
#define kNext  NSLocalizedString(@"Next", @"Short button text for next")
#define kEnd   NSLocalizedString(@"End", @"Short button text for end")

#define kNoButton -1

enum{
    ActionButtonStopId,
    ActionButtonAction,
    ActionButtonAppleMap,
    ActionButtonCancel,
    ActionButtonGoogleMap,
    ActionButtonMotionXMap,
    ActionButtonMotionXHdMap,
    ActionButtonWazeMap
};


@implementation MapViewController

@synthesize annotations = _annotations;
@synthesize lines = _lines;
@synthesize tappedAnnot = _tappedAnnot;
@synthesize lineCoords = _lineCoords;
@synthesize routePolyLines = _routePolyLines;
@synthesize circle = _circle;
@synthesize compassButton = _compassButton;
@synthesize animating = _animating;
@synthesize previousHeading = _previousHeading;
@synthesize displayLink = _displayLink;
@synthesize mapView = _mapView;
@synthesize msgText = _msgText;
@synthesize actionButtons = _actionButtons;

- (void)dealloc {
	self.annotations = nil;
	self.mapView.delegate = nil;
	self.mapView.showsUserLocation=FALSE;
	self.routePolyLines = nil;
	[self.mapView removeAnnotations:self.mapView.annotations];
	self.tappedAnnot = nil;
	self.lineCoords = nil;
	self.circle = nil;
    self.compassButton = nil;
    self.msgText = nil;
    self.actionButtons = nil;
    
    if (self.displayLink)
    {
        [self.displayLink invalidate];
    }
    self.displayLink = nil;
   
	[_segPrevNext release];
	// A bug in the SDK means that releasing a mapview can cause a crash as it may be animating
	// we delay 4 seconds for the release.
    [_mapView retain];
	[_mapView performSelector:@selector(release) withObject:nil afterDelay:(NSTimeInterval)4.0];
    self.mapView = nil;
	[super dealloc];
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
		case 0:	// UIPickerView
		{
			// Prev
			if (_selectedAnnotation > 0)
			{
				_selectedAnnotation--;
				
			}
			break;
		}
		case 1:	// UIPickerView
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
		case 0:	// UIPickerView
		{
			self.mapView.mapType = MKMapTypeStandard;
			break;
		}
		case 1:	// UIPickerView
		{
			self.mapView.mapType = MKMapTypeHybrid;
			break;
		}
	}
}

- (NSMutableString *)safeString:(NSString *)str
{
    NSMutableString *newStr = [[str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding].mutableCopy autorelease];
    
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
                        }.retain;
    });
    
    [replacements enumerateKeysAndObjectsUsingBlock: ^void (NSString* key, NSString* original, BOOL *stop)
     {
         [newStr replaceOccurrencesOfString:original withString:key options:NSCaseInsensitiveSearch range:NSMakeRange(0, newStr.length)];
     }];
    
    return newStr;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch(self.actionButtons[buttonIndex].integerValue)
    {
        case ActionButtonAppleMap:
            
        {
            NSString *url = nil;
            
            url = [NSString stringWithFormat:@"http://maps.apple.com/?q=%f,%f&ll=%f,%f",
                   //[self.tappedAnnot.title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                   self.tappedAnnot.coordinate.latitude, self.tappedAnnot.coordinate.longitude,
                   self.tappedAnnot.coordinate.latitude, self.tappedAnnot.coordinate.longitude];
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
            break;
            
        }
        case ActionButtonGoogleMap:
        {
            
            NSString *url = [NSString stringWithFormat:@"comgooglemaps://?q=%f,%f@%f,%f",
                             // [self.tappedAnnot.title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                             self.tappedAnnot.coordinate.latitude, self.tappedAnnot.coordinate.longitude,
                             self.tappedAnnot.coordinate.latitude, self.tappedAnnot.coordinate.longitude];
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
            break;
            
        }
        case ActionButtonMotionXHdMap:
        {
            
            NSString *url = [NSString stringWithFormat:@"motionxgpshd://addWaypoint?name=%@&lat=%f&lon=%f",
                             [self safeString:self.tappedAnnot.title],
                             self.tappedAnnot.coordinate.latitude, self.tappedAnnot.coordinate.longitude];
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
            break;
        }
        case ActionButtonMotionXMap:
        {
            
            NSString *url = [NSString stringWithFormat:@"motionxgps://addWaypoint?name=%@&lat=%f&lon=%f",
                             [self safeString:self.tappedAnnot.title],
                             self.tappedAnnot.coordinate.latitude, self.tappedAnnot.coordinate.longitude];
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
            break;
        }
        case ActionButtonWazeMap:
        {
            
            NSString *url = [NSString stringWithFormat:@"waze://?ll=%f,%f",
                             //[self.tappedAnnot.title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                             self.tappedAnnot.coordinate.latitude, self.tappedAnnot.coordinate.longitude];
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
            break;
        }
        case ActionButtonCancel:
        default:
            break;
        case ActionButtonAction:
        {
            if ([self.tappedAnnot respondsToSelector: @selector(mapTapped:)] && [self.tappedAnnot mapTapped:self.backgroundTask])
            {
                break;
            }
            else if ([self.tappedAnnot respondsToSelector: @selector(mapDeparture)])
            {
                DepartureData *departure = [self.tappedAnnot mapDeparture];
                DepartureDetailView *departureDetailView = [DepartureDetailView viewController];
                departureDetailView.callback = self.callback;
                
                [departureDetailView fetchDepartureAsync:self.backgroundTask dep:departure allDepartures:nil];
            }
            break;
        }
        case ActionButtonStopId:
        {
            if ([self.tappedAnnot respondsToSelector: @selector(mapStopId)])
            {
                DepartureTimesView *departureViewController = [DepartureTimesView viewController];
                departureViewController.callback = self.callback;
                [departureViewController fetchTimesForLocationAsync:self.backgroundTask loc:[self.tappedAnnot mapStopId]];
            }
            break;
        }
    }
    self.actionButtons = nil;
}


#pragma mark ViewControllerBase methods

-(void)infoAction:(id)sender
{
    UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Info", @"alert title")
													   message:NSLocalizedString(@"The route path does not reflect future service changes until they come into effect.\n"
																"Route and arrival data provided by permission of TriMet.", @"trip planner information")
													  delegate:nil
											 cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
											 otherButtonTitles:nil ] autorelease];
	[alert show];
	
	
}

- (void) updateToolbarItems:(NSMutableArray *)toolbarItems
{
	// add a segmented control to the button bar
	UISegmentedControl	*buttonBarSegmentedControl;
	buttonBarSegmentedControl = [[UISegmentedControl alloc] initWithItems:
								 @[@"Map", @"Hybrid"]];
	[buttonBarSegmentedControl addTarget:self action:@selector(toggleMap:) forControlEvents:UIControlEventValueChanged];
	buttonBarSegmentedControl.selectedSegmentIndex = 0.0;	// start by showing the normal picker
    
    UIBarButtonItem *zoom = [[[UIBarButtonItem alloc]
                              initWithImage:[TableViewWithToolbar getToolbarIcon:kIconEye]
                               style:UIBarButtonItemStylePlain
                               target:self action:@selector(fitToViewAction:)] autorelease];
    
	
    
    [toolbarItems addObjectsFromArray:@[[UIToolbar autoFlexSpace],  zoom, [UIToolbar autoFlexSpace]]];

    if ([MKMapView instancesRespondToSelector:@selector(setUserTrackingMode:animated:)])
    {
        self.compassButton = [[[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView] autorelease];
    }
    
    if (self.compassButton)
    {
        [toolbarItems addObjectsFromArray:@[self.compassButton, [UIToolbar autoFlexSpace]]];
    }
    
    UIBarButtonItem *segItem = [[UIBarButtonItem alloc] initWithCustomView:buttonBarSegmentedControl];
    
    [toolbarItems addObject:segItem];
    
    if (self.lines)
    {
        // create the system-defined "OK or Done" button
        UIBarButtonItem *info = [[[UIBarButtonItem alloc]
                                  initWithTitle:NSLocalizedString(@"info", @"button text")
                                  style:UIBarButtonItemStylePlain
                                  target:self action:@selector(infoAction:)] autorelease];
        
        [toolbarItems addObjectsFromArray:@[[UIToolbar autoFlexSpace],  info]];
    }
    
    if (self.hasXML)
    {
        [toolbarItems addObject:[UIToolbar autoFlexSpace]];
        [self updateToolbarItemsWithXml:toolbarItems];
    }
    else
    {
        [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
    }
    
	[segItem release];
	[buttonBarSegmentedControl release];
}


- (void)removeAnnotations
{
    NSArray *oldAnnotations = [self.mapView.annotations retain];
    
    if (oldAnnotations !=nil && oldAnnotations.count >0)
    {
        [self.mapView removeAnnotations:oldAnnotations];
    }
    
     [oldAnnotations release];
}

#pragma mark View functions

- (void)fitToViewAction:(id)unused
{
    [self fitToView];
}

- (void)fitToView
{
    if (self.annotations !=nil && self.annotations.count < 2)
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
        
        
        
        // MKPinAnnotationView * pin = [[[MKPinAnnotationView alloc] initWithAnnotation:pinPos reuseIdentifier:@"mainPin"] autorelease];
        
        // pin.pinColor = MKPinAnnotationColorRed;
        // pin.animatesDrop = YES;
        
        
        [self.mapView regionThatFits:region];
        [self.mapView setRegion:region animated:TRUE];
    }
    else if (self.annotations !=nil && self.annotations.count >= 2)
    {
        // Walk the list of overlays and annotations and create a MKMapRect that
        // bounds all of them and store it into flyTo.
        MKMapRect flyTo = MKMapRectNull;
        
        for(id<MapPinColor> pin in self.annotations)
        {
            DEBUG_LOG(@"Coords %f %f %@\n", pin.coordinate.latitude, pin.coordinate.longitude, [pin title]);
            MKMapPoint annotationPoint = MKMapPointForCoordinate(pin.coordinate);
            MKMapRect pointRect = MakeMapRectWithPointAtCenter(annotationPoint.x, annotationPoint.y, 300, 1000);
            flyTo = MKMapRectUnion(flyTo, pointRect);
        }
        
        if (self.lines && self.lineCoords != nil)
        {
            for(NSObject * coordObj in self.lineCoords)
            {
                if ([coordObj isKindOfClass:[ShapeCoordEnd class]])
                {
                     continue;
                }
                
                ShapeCoord *coord = (ShapeCoord *)coordObj;
                
                MKMapPoint annotationPoint = MKMapPointForCoordinate(coord.coord);
                MKMapRect pointRect = MakeMapRectWithPointAtCenter(annotationPoint.x, annotationPoint.y, 300, 1000);
                flyTo = MKMapRectUnion(flyTo, pointRect);
            }
            
        }
        
        UIEdgeInsets insets = {
            100, 30,
            60, 30
        };
        
        [self.mapView setVisibleMapRect:[self.mapView mapRectThatFits:flyTo edgePadding:insets] animated:YES];
    }
    else if (self.annotations !=nil && self.annotations.count >= 2)
    {
        CLLocationDegrees maxLat = -90;
        CLLocationDegrees maxLon = -180;
        CLLocationDegrees minLat = 90;
        CLLocationDegrees minLon = 180;
        
        for(id<MapPinColor> pin in self.annotations)
        {
            CLLocationCoordinate2D coord = pin.coordinate;
            if(coord.latitude > maxLat)
            {
                maxLat = coord.latitude;
            }
            if(coord.latitude < minLat)
            {
                minLat = coord.latitude;
            }
            if(coord.longitude > maxLon)
            {
                maxLon = coord.longitude;
            }
            if(coord.longitude < minLon)
            {
                minLon = coord.longitude;
            }
        }
        
        if (self.lines && self.lineCoords != nil)
        {
            for(NSObject * coordObj in self.lineCoords)
            {
                if (![coordObj isKindOfClass:[ShapeCoord class]])
                {
                    continue;
                }
                
                ShapeCoord *coord =  (ShapeCoord *)coordObj;
                
                if(coord.latitude > maxLat)
                {
                    maxLat = coord.latitude;
                }
                if(coord.latitude < minLat)
                {
                    minLat = coord.latitude;
                }
                if(coord.longitude > maxLon)
                {
                    maxLon = coord.longitude;
                }
                if(coord.longitude < minLon)
                {
                    minLon = coord.longitude;
                }
            }
            
        } 
        
        MKCoordinateRegion region;
        region.center.latitude     = (maxLat + minLat) / 2;
        region.center.longitude    = (maxLon + minLon) / 2;
        region.span.latitudeDelta  = maxLat - minLat + 0.001;
        region.span.longitudeDelta = maxLon - minLon + 0.001;
        
        [self.mapView regionThatFits:region];
        [self.mapView setRegion:region animated:TRUE];
    }
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)addDataToMap:(bool)zoom {
  

    [self removeAnnotations];
    
    {
        NSArray *oldOverlays = [self.mapView.overlays retain];
        
        if (oldOverlays !=nil && oldOverlays.count >0)
        {
            [self.mapView removeOverlays:oldOverlays];
        }
        
        [oldOverlays release];
    }
    

    if (self.lineCoords != nil)
	{
		[_segPrevNext release];
		_segPrevNext = [[UISegmentedControl alloc] initWithItems:@[kPrev,kNext] ];
		_segPrevNext.frame = CGRectMake(0, 0, 80, 30.0);
		_segPrevNext.momentary = YES;
		[_segPrevNext addTarget:self action:@selector(prevNext:) forControlEvents:UIControlEventValueChanged];
		
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView: _segPrevNext]
                                                  autorelease];
		
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
	
    if (zoom)
    {
        [self fitToView];
    }
	
	
    if (self.lines && self.lineCoords.count > 0) { // overlays!
        
		CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * self.lineCoords.count);
        self.routePolyLines  = [NSMutableArray array];

		int j = 0;
		for (NSObject *coordObj in self.lineCoords)
		{            
			if ([coordObj isKindOfClass:[ShapeCoordEnd class]])
			{
                ShapeCoordEnd *end = (ShapeCoordEnd *)coordObj;
                
                if (end.direct)
                {
                    RoutePolyline *polyLine = [RoutePolyline polylineWithCoordinates:coords count:j];
                    
                    polyLine.direct = YES;
                    polyLine.color = end.color;
                    
                    [self.routePolyLines addObject:polyLine];
    
                }
                else
                {
                    RoutePolyline *polyLine = [RoutePolyline polylineWithCoordinates:coords count:j];
                    
                    polyLine.direct = NO;
                    polyLine.color = end.color;
                    
                    [self.routePolyLines addObject:polyLine];
                    
                }
				 j=0;
				
			}
			else if ([coordObj isKindOfClass:[ShapeCoord class]])
            {
                
                ShapeCoord *coord = (ShapeCoord *)coordObj;
				
				coords[j] = coord.coord;
				j++;
			}

		}
				 
		free(coords);
	
		[self.mapView addOverlays:self.routePolyLines];
	}
	
	if (self.circle)
	{
		[self.mapView addOverlay:self.circle];
		
	}
	
    [self updateToolbar];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Get the size of the diagonal
    CGRect mapViewRect = [self getMiddleWindowRect];
    
	//if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
	//	self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
	//{
    //    mapViewRect.origin.x = _portraitMapRect.origin.y;
    //    mapViewRect.origin.y = _portraitMapRect.origin.x;
    //}
    
    
    mapViewRect.size.height -= self.navigationController.navigationBar.frame.size.height + self.tabBarController.view.frame.size.height;
    mapViewRect.origin.y += self.navigationController.navigationBar.frame.size.height + self.tabBarController.view.frame.size.height;
    
    self.mapView=[[[MKMapView alloc] initWithFrame:mapViewRect] autorelease];
	self.mapView.showsUserLocation=TRUE;
	self.mapView.mapType=MKMapTypeStandard;
	self.mapView.delegate=self;
	self.mapView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    
    [self addDataToMap:YES];
    
    [self.view insertSubview:self.mapView atIndex:0];
}

- (MKOverlayRenderer*)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[RoutePolyline class]])
    {
        RoutePolyline *poly = (RoutePolyline *)overlay;
        
        MKPolylineRenderer *lineView = [[MKPolylineRenderer alloc] initWithPolyline:(MKPolyline*)overlay];
     
        lineView.strokeColor = poly.color;
        
        
        lineView.lineWidth = 3.0;
        
        if (poly.direct)
        {
            lineView.lineDashPattern = @[ @2, @15 ];
        }
        else
        {
            lineView.lineDashPattern = @[ @3,  @5 ];

        }
        
        return [lineView autorelease];
    }
    

	if (overlay == self.circle)
	{
		MKCircleRenderer *circleView = [[MKCircleRenderer alloc] initWithCircle:overlay];
		circleView.strokeColor = [UIColor greenColor];
		circleView.lineWidth = 3.0;
		return [circleView autorelease];
		
	}
	
	return [[[MKCircleRenderer alloc] initWithCircle:[MKCircle circleWithMapRect:MKMapRectNull]] autorelease];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
    
    self.navigationItem.prompt = self.msgText;

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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // [self checkRotation:YES newOrientation:toInterfaceOrientation];
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
	self.tappedAnnot = (id<MapPinColor>)view.annotation;
	
    NSString *action = nil;
    NSString *stopIdAction = nil;
	
	if ([self.tappedAnnot showActionMenu])
	{
		// action = @"Show details";
		if ([self.tappedAnnot respondsToSelector: @selector(mapTapped:)]) //  && [self.tappedAnnot mapTapped])
		{
			action = nil;
			
			if ([self.tappedAnnot respondsToSelector:@selector(tapActionText)])
			{
				action = [self.tappedAnnot tapActionText];
			}
			if (action == nil)
			{
                action = NSLocalizedString(@"Choose this stop", @"button text");
			}
		}
		else if ([self.tappedAnnot respondsToSelector: @selector(mapDeparture)])
		{
			action = NSLocalizedString(@"Show details", @"button text");
		}
        
        
        if ([self.tappedAnnot respondsToSelector: @selector(mapStopId)])
        {
            if ([self.tappedAnnot respondsToSelector: @selector(mapStopIdText)])
            {
                stopIdAction = [self.tappedAnnot mapStopIdText];
            }
            else
            {
                stopIdAction = NSLocalizedString(@"Show arrivals", @"button text");
            }
        }
    }
    
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Map Actions", @"alert title")
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    self.actionButtons = [NSMutableArray array];
    
    
    if (stopIdAction !=nil)
    {
        self.actionButtons[[actionSheet addButtonWithTitle:stopIdAction]] = @(ActionButtonStopId);
    }
    
    if (action !=nil)
    {
        self.actionButtons[[actionSheet addButtonWithTitle:action]] = @(ActionButtonAction);
    }
    
    self.actionButtons[[actionSheet addButtonWithTitle:NSLocalizedString(@"Show in Apple map app", "map action")]] = @(ActionButtonAppleMap);
    
    UIApplication *app = [UIApplication sharedApplication];
    
#define EXTERNAL_APP(URL, STR, ACTION) if ([app canOpenURL:[NSURL URLWithString:URL]]) {self.actionButtons[[actionSheet addButtonWithTitle:STR]] = @(ACTION); }
    
    EXTERNAL_APP(@"comgooglemaps:", NSLocalizedString(@"Show in Google map app", "map action"),     ActionButtonGoogleMap);
    EXTERNAL_APP(@"waze:",          NSLocalizedString(@"Show in Waze map app", "map action"),       ActionButtonWazeMap);
    EXTERNAL_APP(@"motionxgps:",    NSLocalizedString(@"Import to MotionX-GPS", "map action"),      ActionButtonMotionXMap);
    EXTERNAL_APP(@"motionxgpshd:",  NSLocalizedString(@"Import to MotionX-GPS HD", "map action"),   ActionButtonMotionXHdMap);
    
    actionSheet.cancelButtonIndex  = [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"button text")];
    
    self.actionButtons[actionSheet.cancelButtonIndex] = @(ActionButtonCancel);
    
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [actionSheet showFromToolbar:self.navigationController.toolbar]; // show from our table view (pops up in the middle of the table)
    [actionSheet release];
    
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    
}
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{

}

#pragma mark BackgroundTask callbacks

-(void)BackgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled
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


- (UIInterfaceOrientation)BackgroundTaskOrientation
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

