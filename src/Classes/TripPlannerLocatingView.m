//
//  TripPlannerLocatingView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/4/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TripPlannerLocatingView.h"
#import "TripPlannerLocationListView.h"
#import "TripPlannerResultsView.h"
#import "DebugLogging.h"
#import "ReverseGeoLocator.h"
#import "GeoLocator.h"
#import "MainQueueSync.h"
#import "TaskState.h"
#import "RunParallelBlocks.h"

@interface TripPlannerLocatingView () {
    UIInterfaceOrientation _cachedOrientation;
    bool _useCachedOrientation;
    bool _appeared;
}

@property (nonatomic, strong) UINavigationController *backgroundTaskController;
@property (nonatomic) bool backgroundTaskForceResults;
@property (atomic) bool waitingForGeocoder;



@end

@implementation TripPlannerLocatingView


#pragma mark UI helpers

- (void)refreshAction:(id)sender {
    if (!self.backgroundTask.running) {
        self.currentEndPoint.locationDesc = nil;
        [super refreshAction:sender];
    }
}

#pragma mark Data fetchers

- (void)nextScreen:(UINavigationController *)controller
      forceResults:(bool)forceResults postQuery:(bool)postQuery
       orientation:(UIInterfaceOrientation)orientation
     taskContainer:(BackgroundTaskContainer *)taskContainer {
    bool findLocation = false;
    
    if (self.tripQuery.userRequest.fromPoint.useCurrentLocation == false
        && self.tripQuery.userRequest.toPoint.useCurrentLocation == false) {
        findLocation = false;
    } else if (self.tripQuery.userRequest.fromPoint.useCurrentLocation == true && !postQuery) {
        findLocation = true; // (self.tripQuery.fromPoint.lat==nil);
        self.currentEndPoint = self.tripQuery.userRequest.fromPoint;
    } else if (self.tripQuery.userRequest.toPoint.useCurrentLocation == true && !postQuery) {
        findLocation = true; // (self.tripQuery.toPoint.lat==nil);
        self.currentEndPoint = self.tripQuery.userRequest.toPoint;
    }
    
    if (findLocation && !forceResults) {
        [controller pushViewController:self animated:YES];
    } else {
        _cachedOrientation = orientation;
        _useCachedOrientation = true;
        [self fetchAndDisplay:controller forceResults:forceResults taskContainer:taskContainer];
    }
}

- (void)subTaskFetchNames:(NSMutableArray *)geoNamesRequired taskState:(TaskState *)taskState {
    for (TripEndPoint *point in geoNamesRequired) {
        ReverseGeoLocator *geocoder = [[ReverseGeoLocator alloc] init];
        
        if ([geocoder fetchAddress:point.coordinates]) {
            point.locationDesc = geocoder.result;
        }
        
        [taskState incrementItemsDoneAndDisplay];
    }
}

- (void)subTaskFetchCoordsFrom:(NSMutableArray<TripLegEndPoint *> **)fromList
                            to:(NSMutableArray<TripLegEndPoint *> **)toList
             geoCoordsRequired:(NSMutableArray *)geoCoordsRequired
                     taskState:(TaskState *)taskState  {
    for (TripEndPoint *point in geoCoordsRequired) {
        GeoLocator *geoLocator = [[GeoLocator alloc] init];
        
        NSMutableArray<TripLegEndPoint *> *results = [geoLocator fetchCoordinates:point.locationDesc];
        
        if (results.count == 1) {
            point.coordinates = results.lastObject.loc;
            point.locationDesc = results.lastObject.displayText;
        } else if (results.count != 0) {
            if (point == self.tripQuery.userRequest.toPoint) {
                *toList = results;
                self.tripQuery.toList = results;
            } else {
                self.tripQuery.fromList = results;
                *fromList = results;
            }
        } else {
            if (point == self.tripQuery.userRequest.toPoint) {
                self.tripQuery.toList = nil;
                self.tripQuery.toAppleFailed = YES;
            } else {
                self.tripQuery.fromList = nil;
                self.tripQuery.fromAppleFailed = YES;
            }
        }
        
        [taskState incrementItemsDoneAndDisplay];
    }
}

- (void)subTaskFetchGeosAndTrip:(NSMutableArray *)geoCoordsRequired geoNamesRequired:(NSMutableArray *)geoNamesRequired taskState:(TaskState *)taskState {
    [taskState taskStartWithTotal:1 + (int)geoNamesRequired.count + (int)geoCoordsRequired.count title:NSLocalizedString(@"getting trip", @"progress message")];
    [taskState taskSubtext:NSLocalizedString(@"geolocating", @"progress message")];
    
    taskState.itemsDone = 0;
    
    RunParallelBlocks *parallelBlocks =  [RunParallelBlocks instance];
    
    [parallelBlocks startBlock:^{
        [self subTaskFetchNames:geoNamesRequired taskState:taskState];
    }];
    
    __block NSMutableArray<TripLegEndPoint *> *toList = nil;
    __block NSMutableArray<TripLegEndPoint *> *fromList = nil;
    
    [parallelBlocks startBlock:^{
        [self subTaskFetchCoordsFrom:&fromList to:&toList geoCoordsRequired:geoCoordsRequired taskState:taskState ];
    }];
    
    [parallelBlocks waitForBlocks];
    
    if (self.tripQuery.toList == nil || self.tripQuery.fromList == nil) {
        [taskState taskSubtext:NSLocalizedString(@"planning trip", @"progress message")];
        self.tripQuery.oneTimeDelegate = taskState;
        [self.tripQuery fetchItineraries:nil];
        
        if (toList) {
            self.tripQuery.toList = toList;
        }
        
        if (fromList) {
            self.tripQuery.fromList = fromList;
        }
    }
    
    [taskState incrementItemsDoneAndDisplay];
}

- (void)fetchAndDisplay:(UINavigationController *)controller
           forceResults:(bool)forceResults
          taskContainer:(BackgroundTaskContainer *)taskController {
    [taskController taskRunAsync:^(TaskState *taskState) {
        NSMutableArray *geoNamesRequired  = [NSMutableArray array];
        NSMutableArray *geoCoordsRequired = [NSMutableArray array];
        
        self.backgroundTaskController = controller;
        self.backgroundTaskForceResults = forceResults;
        
        
        bool canReverseGeocode = [ReverseGeoLocator supported];
        bool canGeocode        = [GeoLocator supported];
        
        if (canReverseGeocode && (self.tripQuery.userRequest.toPoint.useCurrentLocation || self.tripQuery.userRequest.toPoint.coordinates != nil) && self.tripQuery.userRequest.toPoint.locationDesc == nil) {
            [geoNamesRequired addObject:self.tripQuery.userRequest.toPoint];
        }
        
        if (canReverseGeocode && (self.tripQuery.userRequest.fromPoint.useCurrentLocation || self.tripQuery.userRequest.fromPoint.coordinates != nil) && self.tripQuery.userRequest.fromPoint.locationDesc == nil) {
            [geoNamesRequired addObject:self.tripQuery.userRequest.fromPoint];
        }
        
        if (canGeocode && [GeoLocator addressNeedsCoords:self.tripQuery.userRequest.toPoint.locationDesc] && self.tripQuery.userRequest.toPoint.coordinates == nil) {
            [geoCoordsRequired addObject:self.tripQuery.userRequest.toPoint];
        }
        
        if (canGeocode && [GeoLocator addressNeedsCoords:self.tripQuery.userRequest.fromPoint.locationDesc] && self.tripQuery.userRequest.fromPoint.coordinates == nil) {
            [geoCoordsRequired addObject:self.tripQuery.userRequest.fromPoint];
        }
        
        self.tripQuery.toAppleFailed = NO;
        self.tripQuery.fromAppleFailed = NO;
        
        if (geoNamesRequired.count > 0 || geoCoordsRequired.count > 0) {
            [self subTaskFetchGeosAndTrip:geoCoordsRequired
                          geoNamesRequired:geoNamesRequired
                                 taskState:taskState];
        } else {
            [taskState startAtomicTask:@"getting trip"];
            self.tripQuery.oneTimeDelegate = taskState;
            [self.tripQuery fetchItineraries:nil];
            [taskState atomicTaskItemDone];
        }
        
        
        if (self.tripQuery.fromList != nil && !self.backgroundTaskForceResults
            && !self.tripQuery.userRequest.fromPoint.useCurrentLocation) {
            __block TripPlannerLocationListView *locView = nil;
            
            [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
                locView = [TripPlannerLocationListView viewController];
                locView.tripQuery = self.tripQuery;
                locView.from = true;
            }];
            // Push the detail view controller
            return (UIViewController *)locView;
        } else if (self.tripQuery.toList != nil && !self.backgroundTaskForceResults
                   && !self.tripQuery.userRequest.toPoint.useCurrentLocation) {
            __block TripPlannerLocationListView *locView = nil;
            
            [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
                locView = [TripPlannerLocationListView viewController];
                locView.tripQuery = self.tripQuery;
                locView.from = false;
            }];
            // Push the detail view controller
            return (UIViewController *)locView;
        } else {
            __block TripPlannerResultsView *tripResults = nil;
            
            [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
                tripResults = [TripPlannerResultsView viewController];
                tripResults.tripQuery = self.tripQuery;
                [tripResults.tripQuery saveTrip];
            }];
            
            // Push the detail view controller
            return (UIViewController *)tripResults;
        }
    }];
}

#pragma mark Background task callbacks


- (UIInterfaceOrientation)backgroundTaskOrientation {
    if (_useCachedOrientation) {
        return _cachedOrientation;
    }
    
    return [super backgroundTaskOrientation];
}

#pragma mark View callbacks


- (void)viewDidAppear:(BOOL)animated {
    self.delegate = self;
    self.accuracy = 200.0;
    
    if (self.currentEndPoint.coordinates == nil || !_appeared) {
        [self startLocating];
        _appeared = YES;
    } else {
        self.lastLocation = self.currentEndPoint.coordinates;
        [self stopLocating];
        [self reloadData];
    }
    
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    self.delegate = nil;
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark LocatingTableView callbacks


- (void)locatingViewFinished:(LocatingView *)locatingView {
    if (!locatingView.failed && !locatingView.cancelled) {
        TripEndPoint *point = nil;
        
        if (self.tripQuery.userRequest.fromPoint.useCurrentLocation) {
            point = self.tripQuery.userRequest.fromPoint;
        } else {
            point = self.tripQuery.userRequest.toPoint;
        }
        
        point.coordinates = self.lastLocation;
        
        
        [self fetchAndDisplay:locatingView.navigationController forceResults:NO taskContainer:locatingView.backgroundTask];
    } else if (locatingView.cancelled) {
        [locatingView.navigationController popViewControllerAnimated:YES];
    }
}

@end
