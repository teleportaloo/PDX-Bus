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
#import "VehicleData+iOSUI.h"
#import "XMLStreetcarLocations.h"
#import "SimpleAnnotation.h"
#import "TriMetInfo.h"
#import "FormatDistance.h"
#import "MapAnnotationImage.h"
#import "DebugLogging.h"
#import "XMLLocateStops+iOSUI.h"
#import "StopDistanceData+iOSUI.h"
#import "CLLocation+Helper.h"
#import "KMLRoutes.h"
#import "ShapeRoutePath.h"

@implementation NearestVehiclesMap

#define XML_DEBUG_RAW_DATA(X) if (X.rawData) [self.xml addObject:X];


- (bool)displayErrorIfNoneFound:(XMLLocateVehicles*)locator progress:(id<BackgroundTaskController>)progress
{
    NSThread *thread = [NSThread currentThread];
    
    if (locator.noErrorAlerts)
    {
        return false;
    }
    
    if (locator.count == 0 && !locator.gotData)
    {
        
        if (!thread.cancelled)
        {
            [thread cancel];
            [progress taskSetErrorMsg:@"Network problem: please try again later."];
            
            return true;
        }
        
    }
    else if (locator.count == 0)
    {
        if (!thread.cancelled)
        {
            [thread cancel];
            
            
            [progress taskSetErrorMsg:[NSString stringWithFormat:@"No vehicles were found within %@, note Streetcar is not supported.",
                                             [FormatDistance formatMetres:locator.dist]]];
            return true;
        }
    }
    
    return false;
    
}



- (void)fetchNearestVehicles:(XMLLocateVehicles*) locator taskController:(id<BackgroundTaskController>)task backgroundRefresh:(bool)backgroundRefresh
{
    [task taskRunAsync:^{
        self.backgroundRefresh = backgroundRefresh;
        
        self.xml = [NSMutableArray array];
        
        TripMode mode = TripModeAll;
        
        NSSet<NSString*> *streetcarRoutesForVehicles = self.streetcarRoutes;
        
        if (self.stopLocator)
        {
            mode = self.stopLocator.mode;
        }
        
        bool fetchVehicles = [UserPrefs sharedInstance].useBetaVehicleLocator;
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
            if (mode != TripModeBusOnly && fetchVehicles)
            {
                if (streetcarRoutesForVehicles == nil)
                {
                    streetcarRoutesForVehicles = [TriMetInfo streetcarRoutes];
                }
            }
            
            operations += streetcarRoutesForVehicles.count;
        }
        
        if ((self.allRoutes || self.trimetRoutes.count > 0 || self.streetcarRoutes.count>0) && [UserPrefs sharedInstance].kmlRoutes)
        {
            operations++;
        }
        
        
        [task taskStartWithItems:operations title:@"getting items"];
        
        int taskCount=0;
        
        if ((self.allRoutes || self.trimetRoutes.count > 0 || self.streetcarRoutes.count>0) && [UserPrefs sharedInstance].kmlRoutes)
        {
            [task taskSubtext:@"getting shapes"];
            KMLRoutes * kml = [KMLRoutes xml];
            self.lineCoords = [NSMutableArray array];
            
            NSSet<NSString*> *all = [self.streetcarRoutes setByAddingObjectsFromSet:self.trimetRoutes];
            
            kml.oneTimeDelegate = task;
            
            if (self.allRoutes)
            {
                [kml fetch];
                
                for (NSString *key in kml.keyEnumerator)
                {
                    [self.lineCoords addObject:[kml lineCoordsForKey:key]];
                }
    
            }
            else
            {
                [kml fetch];
                
                for (NSString *route in all)
                {
                    if (self.direction)
                    {
                        ShapeRoutePath *path = [kml lineCoordsForRoute:route direction:self.direction];
                        
                        if (path)
                        {
                            [self.lineCoords addObject:path];
                        }
                    }
                    else
                    {
                        ShapeRoutePath *path = [kml lineCoordsForRoute:route direction:kKmlFirstDirection];
                        
                        if (path)
                        {
                            [self.lineCoords addObject:path];
                        }
                        
                        ShapeRoutePath *second = [kml lineCoordsForRoute:route direction:kKmlOptionalDirection];
                    
                        if (second)
                        {
                            [self.lineCoords addObject:second];
                        }
                    }
                    [task taskItemsDone:++taskCount];
                }
            }
            
            [task taskItemsDone:++taskCount];
            
            
            self.lineOptions = MapViewFitLines;
        }
        
        
        
        if ((self.trimetRoutes == nil || self.trimetRoutes.count > 0) && fetchVehicles)
        {
            locator.noErrorAlerts = YES;
            
            [task taskSubtext:@"locating TriMet vehicles"];
            locator.oneTimeDelegate = task;
            [locator findNearestVehicles:self.trimetRoutes direction:self.direction blocks:nil vehicles:nil];
            XML_DEBUG_RAW_DATA(locator);
            
            [task taskItemsDone:++taskCount];
            
            if (![self displayErrorIfNoneFound:locator progress:task])
            {
                for (int i=0; i< locator.count && !task.taskCancelled; i++)
                {
                    VehicleData *ui = locator.items[i];
                    
                    if ([ui typeMatchesMode:mode] && (self.stopLocator == nil || [ui.location distanceFromLocation:self.stopLocator.location] <= self.stopLocator.minDistance))
                    {
                        [self addPin:ui];
                    }
                }
            }
        }
        
        if (streetcarRoutesForVehicles.count > 0 && mode != TripModeBusOnly && fetchVehicles)
        {
            for (NSString *route in streetcarRoutesForVehicles)
            {
                XMLStreetcarLocations *loc = [XMLStreetcarLocations sharedInstanceForRoute:route];
                
                [task taskSubtext:@"locating Streetcar vehicles"];
                loc.oneTimeDelegate = task;
                [loc getLocations];
                
                XML_DEBUG_RAW_DATA(loc);
                
                [task taskItemsDone:++taskCount];
                
                [loc.locations enumerateKeysAndObjectsUsingBlock:^(NSString *streecarId, VehicleData *vehicle, BOOL *stop)
                 {
                     if (self.direction==nil || vehicle.direction == nil || [vehicle.direction isEqualToString:self.direction])
                     {
                         if (self.stopLocator == nil || [vehicle.location  distanceFromLocation:self.stopLocator.location] <= self.stopLocator.minDistance)
                         {
                             [self addPin:vehicle];
                         }
                     }
                 }];
            }
        }
        
        if (includeStops && !self.stopLocator.gotData)
        {
            [task taskSubtext:@"locating stops"];
            self.stopLocator.oneTimeDelegate = task;
            [self.stopLocator findNearestStops];
            
            [task taskItemsDone:++taskCount];
            
            if (![self.stopLocator displayErrorIfNoneFound:task])
            {
                for (int i=0; i< self.stopLocator.count && !task.taskCancelled; i++)
                {
                    [self addPin:self.stopLocator.items[i]];
                }
            }
        }
        
        return (UIViewController *)self;
    }];
}

- (void)fetchNearestVehiclesAsync:(id<BackgroundTaskController>)task
{
    [self fetchNearestVehiclesAsync:task backgroundRefresh:NO];
}

- (void)fetchNearestVehiclesAsync:(id<BackgroundTaskController>)task backgroundRefresh:(bool)backgroundRefresh
{
    
    
    self.locator = [XMLLocateVehicles xml];
    
    CLLocation *here = nil;
    
    {
        CLLocationDegrees X0 = 45.255797;
        CLLocationDegrees X1 = 45.657207;
        CLLocationDegrees Y0 = -122.249926;
        CLLocationDegrees Y1 = -123.153522;
        
        
        CLLocationCoordinate2D triMetCenter = { (X0 + X1) / 2.0, (Y0 + Y1) /2.0  };
        
        here = [CLLocation withLat:triMetCenter.latitude lng:triMetCenter.longitude];
    }
    
    self.locator.location = here;
    self.locator.dist     = 0.0;

    
    if ([UserPrefs sharedInstance].useBetaVehicleLocator || self.alwaysFetch)
    {
        [self fetchNearestVehicles:self.locator taskController:task backgroundRefresh:backgroundRefresh];
    }
    else
    {
        [task taskCompleted:self];
    }
    
}

- (void)removeAnnotations
{
    NSArray *annotions = self.mapView.annotations;
    
    for (id<MapPinColor> annot in annotions)
    {
        if ([annot isKindOfClass:[VehicleData class]])
        {
            [self.mapView removeAnnotation:annot];
            [self.annotations removeObject:annot];
        }
    }
}

-(void)refreshAction:(id)unused
{
    if (!self.backgroundRefresh)
    {
        [self removeAnnotations];
    
        [self fetchNearestVehiclesAsync:self.backgroundTask backgroundRefresh:YES];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([UserPrefs sharedInstance].useBetaVehicleLocator || self.alwaysFetch)
    {
        
        // add our custom add button as the nav bar's custom right view
        UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
                                          initWithTitle:NSLocalizedString(@"Refresh", @"")
                                          style:UIBarButtonItemStylePlain
                                          target:self
                                          action:@selector(refreshAction:)];
        self.navigationItem.rightBarButtonItem = refreshButton;
    }
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (bool)hasXML
{
    return YES;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    
    [[MapAnnotationImage autoSingleton] clearCache];
    
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)fetchNearestVehiclesAndStopsAsync:(id<BackgroundTaskController>)task location:(CLLocation *)here maxToFind:(int)max minDistance:(double)min mode:(TripMode)mode
{
    self.stopLocator = [XMLLocateStops xml];
    
    self.locator = [XMLLocateVehicles xml];
    self.locator.location = here;
    self.locator.dist     = min;
    
    self.stopLocator.maxToFind = max;
    self.stopLocator.location = here;
    self.stopLocator.mode = mode;
    self.stopLocator.minDistance = min;
    
    [self fetchNearestVehicles:self.locator taskController:task backgroundRefresh:NO];
}

@end
