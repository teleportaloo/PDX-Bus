//
//  NearestVehiclesMap.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "NearestVehiclesMap.h"
#import "XMLLocateVehicles.h"
#import "Vehicle+iOSUI.h"
#import "XMLStreetcarLocations.h"
#import "SimpleAnnotation.h"
#import "TriMetInfo.h"
#import "FormatDistance.h"
#import "MapAnnotationImageFactory.h"
#import "DebugLogging.h"
#import "XMLLocateStops+iOSUI.h"
#import "StopDistance+iOSUI.h"
#import "CLLocation+Helper.h"
#import "KMLRoutes.h"
#import "ShapeRoutePath.h"
#import "TaskState.h"

@interface NearestVehiclesMap ()

@property (nonatomic, strong) XMLLocateStops *stopLocator;
@property (nonatomic, strong) XMLLocateVehicles *locator;

@end

@implementation NearestVehiclesMap

#define XML_DEBUG_RAW_DATA(X) if (X.rawData) [self.xml addObject:X];


- (bool)displayErrorIfNoneFound:(XMLLocateVehicles *)locator progress:(id<TaskController>)progress {
    NSThread *thread = [NSThread currentThread];
    
    if (locator.noErrorAlerts) {
        return false;
    }
    
    if (locator.count == 0 && !locator.gotData) {
        if (!thread.cancelled) {
            [thread cancel];
            [progress taskSetErrorMsg:NSLocalizedString(@"Network problem: please try again later.", @"progress message")];
            
            return true;
        }
    } else if (locator.count == 0) {
        if (!thread.cancelled) {
            [thread cancel];
            
            
            [progress taskSetErrorMsg:[NSString stringWithFormat:NSLocalizedString(@"No vehicles were found within %@, note Streetcar is not supported.", @"error message"),
                                       [FormatDistance formatMetres:locator.dist]]];
            return true;
        }
    }
    
    return false;
}

- (NSSet<NSString *> *)subTaskCalculateTotal:(bool)fetchVehicles includeStops:(bool)includeStops mode:(TripMode)mode streetcarRoutesForVehicles:(NSSet<NSString *> *)streetcarRoutesForVehicles taskState:(TaskState *)taskState {
    taskState.total = 0;
    
    if (self.trimetRoutes == nil && fetchVehicles) {
        taskState.total++;
    } else if (self.trimetRoutes.count > 0 && fetchVehicles) {
        taskState.total++;
    }
    
    if (includeStops && !self.stopLocator.gotData) {
        taskState.total++;
    }
    
    if (mode != TripModeBusOnly && fetchVehicles) {
        if (mode != TripModeBusOnly && fetchVehicles) {
            if (streetcarRoutesForVehicles == nil) {
                streetcarRoutesForVehicles = [TriMetInfo streetcarRoutes];
            }
        }
        taskState.total += streetcarRoutesForVehicles.count;
    }
    
    if ((self.allRoutes || self.trimetRoutes.count > 0 || self.streetcarRoutes.count > 0) && Settings.kmlRoutes) {
        taskState.total++;
    }
    
    return streetcarRoutesForVehicles;
}

- (void)subTaskFetchShapes:(TaskState *)taskState {
    [taskState taskSubtext:NSLocalizedString(@"getting shapes", @"progress message")];
    KMLRoutes *kml = [KMLRoutes xmlWithOneTimeDelegate:taskState];
    self.lineCoords = [NSMutableArray array];
    
    NSSet<NSString *> *all = [self.streetcarRoutes setByAddingObjectsFromSet:self.trimetRoutes];
        
    if (self.allRoutes) {
        [kml fetchInBackground:NO];
        
        for (NSString *key in kml.keyEnumerator) {
            [self.lineCoords addObject:[kml lineCoordsForKey:key]];
        }
    } else {
        [kml fetchInBackground:NO];
        
        for (NSString *route in all) {
            if (self.direction) {
                ShapeRoutePath *path = [kml lineCoordsForRoute:route direction:self.direction];
                
                if (path) {
                    [self.lineCoords addObject:path];
                }
            } else {
                ShapeRoutePath *path = [kml lineCoordsForRoute:route direction:kKmlFirstDirection];
                
                if (path) {
                    [self.lineCoords addObject:path];
                }
                
                ShapeRoutePath *second = [kml lineCoordsForRoute:route direction:kKmlOptionalDirection];
                
                if (second) {
                    [self.lineCoords addObject:second];
                }
            }
            
            [taskState incrementItemsDoneAndDisplay];
        }
    }
    
    [taskState incrementItemsDoneAndDisplay];
    self.lineOptions = MapViewFitLines;
}

- (void)subTaskLocateTriMetVehicles:(XMLLocateVehicles *)locator mode:(TripMode)mode taskState:(TaskState *)taskState {
    locator.noErrorAlerts = YES;
    
    [taskState taskSubtext:NSLocalizedString(@"locating TriMet vehicles", @"progress message")];
    locator.oneTimeDelegate = taskState;
    [locator findNearestVehicles:self.trimetRoutes direction:self.direction blocks:nil vehicles:nil];
    XML_DEBUG_RAW_DATA(locator);
    
    [taskState incrementItemsDoneAndDisplay];
    
    if (![self displayErrorIfNoneFound:locator progress:taskState]) {
        for (int i = 0; i < locator.count && !taskState.taskCancelled; i++) {
            Vehicle *ui = locator.items[i];
            
            if ([ui typeMatchesMode:mode] && (self.stopLocator == nil || [ui.location distanceFromLocation:self.stopLocator.location] <= self.stopLocator.minDistance)) {
                [self addPin:ui];
            }
        }
    }
}

- (void)subTaskLocateStreetcarVehicles:(NSSet<NSString *> *)streetcarRoutesForVehicles taskState:(TaskState *)taskState {
    for (NSString *route in streetcarRoutesForVehicles) {
        XMLStreetcarLocations *loc = [XMLStreetcarLocations sharedInstanceForRoute:route];
        
        [taskState taskSubtext:NSLocalizedString(@"locating Streetcar vehicles", @"progress message")];
        loc.oneTimeDelegate = taskState;
        [loc getLocations];
        
        XML_DEBUG_RAW_DATA(loc);
        
        [taskState incrementItemsDoneAndDisplay];
        
        [loc.locations enumerateKeysAndObjectsUsingBlock:^(NSString *streecarId, Vehicle *vehicle, BOOL *stop)
         {
            if (self.direction == nil || vehicle.direction == nil || [vehicle.direction isEqualToString:self.direction]) {
                if (self.stopLocator == nil || [vehicle.location distanceFromLocation:self.stopLocator.location] <= self.stopLocator.minDistance) {
                    [self addPin:vehicle];
                }
            }
        }];
    }
}

- (void)subTaskLocateStops:(TaskState *)taskState {
    [taskState taskSubtext:NSLocalizedString(@"locating stops", @"progress message")];
    self.stopLocator.oneTimeDelegate = taskState;
    [self.stopLocator findNearestStops];
    
    [taskState incrementItemsDoneAndDisplay];
    
    if (![self.stopLocator displayErrorIfNoneFound:taskState]) {
        for (int i = 0; i < self.stopLocator.count && !taskState.taskCancelled; i++) {
            [self addPin:self.stopLocator.items[i]];
        }
    }
}

- (void)fetchNearestVehicles:(XMLLocateVehicles *)locator
              taskController:(id<TaskController>)taskController
           backgroundRefresh:(bool)backgroundRefresh {
    [taskController taskRunAsync:^(TaskState *taskState) {
        self.backgroundRefresh = backgroundRefresh;
        self.xml = [NSMutableArray array];
        
        TripMode mode = TripModeAll;
        
        NSSet<NSString *> *streetcarRoutesForVehicles = self.streetcarRoutes;
        
        if (self.stopLocator) {
            mode = self.stopLocator.mode;
        }
        
        bool fetchVehicles = Settings.useVehicleLocator;
        bool includeStops  = self.stopLocator != nil;
        
        streetcarRoutesForVehicles = [self subTaskCalculateTotal:fetchVehicles
                                                    includeStops:includeStops
                                                            mode:mode
                                      streetcarRoutesForVehicles:streetcarRoutesForVehicles
                                                       taskState:taskState];
        
        [taskState startTask:@"getting items"];
        
        if ((self.allRoutes || self.trimetRoutes.count > 0 || self.streetcarRoutes.count > 0) && Settings.kmlRoutes) {
            [self subTaskFetchShapes:taskState];
        }
        
        if ((self.trimetRoutes == nil || self.trimetRoutes.count > 0) && fetchVehicles) {
            [self subTaskLocateTriMetVehicles:locator mode:mode taskState:taskState];
        }
        
        if (streetcarRoutesForVehicles.count > 0 && mode != TripModeBusOnly && fetchVehicles) {
            [self subTaskLocateStreetcarVehicles:streetcarRoutesForVehicles taskState:taskState];
        }
        
        if (includeStops && !self.stopLocator.gotData) {
            [self subTaskLocateStops:taskState];
        }
        
        return (UIViewController *)self;
    }];
}

- (void)fetchNearestVehiclesAsync:(id<TaskController>)taskController {
    [self fetchNearestVehiclesAsync:taskController backgroundRefresh:NO];
}

- (void)fetchNearestVehiclesAsync:(id<TaskController>)taskController backgroundRefresh:(bool)backgroundRefresh {
    self.locator = [XMLLocateVehicles xml];
    
    CLLocation *here = nil;
    
    {
        CLLocationDegrees X0 = 45.255797;
        CLLocationDegrees X1 = 45.657207;
        CLLocationDegrees Y0 = -122.249926;
        CLLocationDegrees Y1 = -123.153522;
        
        
        CLLocationCoordinate2D triMetCenter = { (X0 + X1) / 2.0, (Y0 + Y1) / 2.0  };
        
        here = [CLLocation withLat:triMetCenter.latitude lng:triMetCenter.longitude];
    }
    
    self.locator.location = here;
    self.locator.dist = 0.0;
    
    if (Settings.useVehicleLocator || self.alwaysFetch) {
        [self fetchNearestVehicles:self.locator taskController:taskController backgroundRefresh:backgroundRefresh];
    } else {
        [taskController taskCompleted:self];
    }
}

- (void)removeAnnotations {
    NSArray *annotions = self.mapView.annotations;
    
    for (id<MapPinColor> annot in annotions) {
        if ([annot isKindOfClass:[Vehicle class]]) {
            [self.mapView removeAnnotation:annot];
        }
    }
}

- (void)refreshAction:(id)unused {
    if (!self.backgroundRefresh) {
        [self removeAnnotations];
        [self.annotations removeAllObjects];
        
        [self fetchNearestVehiclesAsync:self.backgroundTask backgroundRefresh:YES];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (Settings.useVehicleLocator || self.alwaysFetch) {
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

- (bool)hasXML {
    return YES;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    
    [[MapAnnotationImageFactory autoSingleton] clearCache];
    
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)fetchNearestVehiclesAndStopsAsync:(id<TaskController>)taskController location:(CLLocation *)here maxToFind:(int)max minDistance:(double)min mode:(TripMode)mode {
    self.stopLocator = [XMLLocateStops xml];
    
    self.locator = [XMLLocateVehicles xml];
    self.locator.location = here;
    self.locator.dist = min;
    
    self.stopLocator.maxToFind = max;
    self.stopLocator.location = here;
    self.stopLocator.mode = mode;
    self.stopLocator.minDistance = min;
    
    [self fetchNearestVehicles:self.locator taskController:taskController backgroundRefresh:NO];
}

@end
