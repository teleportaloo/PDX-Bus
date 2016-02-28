//
//  NearestVehiclesMap.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "NearestVehiclesMap.h"
#import "XMLLocateVehicles.h"
#import "VehicleUI.h"
#import "XMLStreetcarLocations.h"
#import "SimpleAnnotation.h"
#import "TriMetRouteColors.h"
#import "FormatDistance.h"
#import "MapAnnotationImage.h"
#import "DebugLogging.h"
#import "XMLLocateStopsUI.h"
#import "StopDistanceUI.h"

@implementation NearestVehiclesMap

@synthesize locator = _locator;
@synthesize streetcarRoutes = _streetcarRoutes;
@synthesize direction = _direction;
@synthesize trimetRoutes = _triMetRoutes;
@synthesize stopLocator = _stopLocator;

- (void)dealloc
{
    self.locator = nil;
    self.streetcarRoutes = nil;
    self.trimetRoutes = nil;
    self.direction = nil;
    self.stopLocator = nil;
    [super dealloc];
}




- (bool)displayErrorIfNoneFound:(XMLLocateVehicles*)locator progress:(id<BackgroundTaskProgress>)progress
{
    NSThread *thread = [NSThread currentThread];
    
    if (locator.noErrorAlerts)
    {
        return false;
    }
    
    if ([locator safeItemCount] == 0 && ![locator gotData])
    {
        
        if (![thread isCancelled])
        {
            [thread cancel];
            //UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Nearby stops"
            //												   message:@"Network problem: please try again later."
            //												  delegate:delegate
            //										 cancelButtonTitle:@"OK"
            //										 otherButtonTitles:nil] autorelease];
            //[delegate retain];
            //[alert show];
            
            [progress backgroundSetErrorMsg:@"Network problem: please try again later."];
            
            return true;
        }
        
    }
    else if ([locator safeItemCount] == 0)
    {
        if (![thread isCancelled])
        {
            [thread cancel];
            
            
            [progress backgroundSetErrorMsg:[NSString stringWithFormat:@"No vehicles were found within %@, note Streetcar is not supported.",
                                             [FormatDistance formatMetres:locator.dist]]];
            return true;
        }
    }
    
    return false;
    
}


- (void)fetchNearestVehicles:(XMLLocateVehicles*) locator
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSThread *thread = [NSThread currentThread];
    
    TripMode mode = TripModeAll;
    
    if (self.stopLocator)
    {
        mode = self.stopLocator.mode;
    }
    
    bool fetchVehicles = [UserPrefs getSingleton].useBetaVehicleLocator;
    bool includeStops  = self.stopLocator != nil;
	
    int operations = 0;
    
    if (self.trimetRoutes == nil && fetchVehicles)
    {
        operations ++;
    }
    else if (self.trimetRoutes.count > 0 && fetchVehicles)
    {
        operations ++;
    }
    
    if (includeStops && !self.stopLocator.gotData)
    {
        operations ++;
    }
    
    if (mode != TripModeBusOnly && fetchVehicles)
    {
        if (self.streetcarRoutes == nil)
        {
            self.streetcarRoutes = [TriMetRouteColors streetcarRoutes];
        }

        operations += self.streetcarRoutes.count;
    }
    
	[self.backgroundTask.callbackWhenFetching backgroundStart:operations title:@"getting items"];
    
    int task=0;
    
    if ((self.trimetRoutes == nil || self.trimetRoutes.count > 0) && fetchVehicles)
    {
        locator.noErrorAlerts = YES;
        
        [self.backgroundTask.callbackWhenFetching backgroundSubtext:@"locating TriMet vehicles"];
        
        [locator findNearestVehicles:self.trimetRoutes direction:self.direction blocks:nil];
    
   
        [self.backgroundTask.callbackWhenFetching backgroundItemsDone:++task];
    
        if (![self displayErrorIfNoneFound:locator progress:self.backgroundTask.callbackWhenFetching])
        {
            for (int i=0; i< [locator safeItemCount] && ![thread isCancelled]; i++)
            {
                VehicleUI *ui = [VehicleUI createFromData:[locator.itemArray objectAtIndex:i]];
                
                if ([ui.data typeMatchesMode:mode] && (self.stopLocator == nil || [ui.data.location distanceFromLocation:self.stopLocator.location] <= self.stopLocator.minDistance))
                {
                    [self addPin:ui];
                }
            }
		}
	}
    
    if (self.streetcarRoutes.count > 0 && mode != TripModeBusOnly && fetchVehicles)
    {
        for (NSString *route in self.streetcarRoutes)
        {
            XMLStreetcarLocations *loc = [XMLStreetcarLocations getSingletonForRoute:route];
            
            
            [self.backgroundTask.callbackWhenFetching backgroundSubtext:@"locating Streetcar vehicles"];
            [loc getLocations];
            
            [self.backgroundTask.callbackWhenFetching backgroundItemsDone:++task];
            
            for (NSString *streetcarId in loc.locations)
            {
                VehicleData *vehicle = [loc.locations objectForKey:streetcarId];
                
                if (self.direction==nil || vehicle.direction == nil || [vehicle.direction isEqualToString:self.direction])
                {
                    if (self.stopLocator == nil || [vehicle.location  distanceFromLocation:self.stopLocator.location] <= self.stopLocator.minDistance)
                    {
                        VehicleUI *ui = [VehicleUI createFromData:vehicle];
                        [self addPin:ui];
                    }
                }
            }
        }
    }
    
    if (includeStops && !self.stopLocator.gotData)
    {
        [self.backgroundTask.callbackWhenFetching backgroundSubtext:@"locating stops"];

        [self.stopLocator findNearestStops];
        
        [self.backgroundTask.callbackWhenFetching backgroundItemsDone:++task];
        
        if (![self.stopLocator displayErrorIfNoneFound:self.backgroundTask.callbackWhenFetching])
        {
            for (int i=0; i< [self.stopLocator safeItemCount] && ![thread isCancelled]; i++)
            {
                StopDistanceUI *ui = [StopDistanceUI createFromData:[self.stopLocator.itemArray objectAtIndex:i]];
                [self addPin:ui];
            }
        }
    }
    
    [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
    
	[pool release];
}



- (void)fetchNearestVehiclesInBackground:(id<BackgroundTaskProgress>)background
{
	self.backgroundTask.callbackWhenFetching = background;
	
    self.locator = [[[XMLLocateVehicles alloc] init] autorelease];
    
    CLLocation *here = nil;
    
    {
        CLLocationDegrees X0 = 45.255797;
        CLLocationDegrees X1 = 45.657207;
        CLLocationDegrees Y0 = -122.249926;
        CLLocationDegrees Y1 = -123.153522;
        
        
        CLLocationCoordinate2D triMetCenter = { (X0 + X1) / 2.0, (Y0 + Y1) /2.0  };
        
        here = [[[CLLocation alloc] initWithLatitude:triMetCenter.latitude longitude:triMetCenter.longitude] autorelease];
    }
	
	self.locator.location = here;
    self.locator.dist     = 0.0;
	
    if ([UserPrefs getSingleton].useBetaVehicleLocator || self.alwaysFetch)
    {
        [NSThread detachNewThreadSelector:@selector(fetchNearestVehicles:) toTarget:self withObject:self.locator];
    }
    else
    {
        [background backgroundCompleted:self];
    }
	
}

- (void)removeAnnotations
{
    NSArray *annotions = self.mapView.annotations;
    
    for (id<MKAnnotation> annot in annotions)
    {
        if ([annot isKindOfClass:[VehicleUI class]])
        {
            [self.mapView removeAnnotation:annot];
            [self.annotations removeObject:annot];
        }
    }
}

-(void)refreshAction:(id)arg
{
    if (!self.backgroundRefresh)
    {
        self.backgroundRefresh = YES;
    
        XMLLocateVehicles * locator =[self.locator retain];
    
        [self removeAnnotations];
    
        [self fetchNearestVehiclesInBackground:self.backgroundTask];
    
        [locator release];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([UserPrefs getSingleton].useBetaVehicleLocator || self.alwaysFetch)
    {
        
        // add our custom add button as the nav bar's custom right view
        UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
                                          initWithTitle:NSLocalizedString(@"Refresh", @"")
                                          style:UIBarButtonItemStyleBordered
                                          target:self
                                          action:@selector(refreshAction:)];
        self.navigationItem.rightBarButtonItem = refreshButton;
        [refreshButton release];
    }
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (bool)hasXML
{
    return YES;
}

-(void) appendXmlData:(NSMutableData *)buffer
{
    [self.locator appendQueryAndData:buffer];
    
    for (NSString *route in self.streetcarRoutes)
    {
        XMLStreetcarLocations *loc = [XMLStreetcarLocations getSingletonForRoute:route];
        
        [loc appendQueryAndData:buffer];
    }
}



- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    
    [[MapAnnotationImage getSingleton] clearCache];
    
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)fetchNearestVehiclesAndStopsInBackground:(id<BackgroundTaskProgress>)background location:(CLLocation *)here maxToFind:(int)max minDistance:(double)min mode:(TripMode)mode
{
    self.backgroundTask.callbackWhenFetching = background;
    self.stopLocator = [[[XMLLocateStopsUI alloc] init] autorelease];
    
    self.locator = [[[XMLLocateVehicles alloc] init] autorelease];
    self.locator.location = here;
    self.locator.dist     = min;
    
    self.stopLocator.maxToFind = max;
    self.stopLocator.location = here;
    self.stopLocator.mode = mode;
    self.stopLocator.minDistance = min;
        
    [NSThread detachNewThreadSelector:@selector(fetchNearestVehicles:) toTarget:self withObject:self.locator];
    
}

@end
