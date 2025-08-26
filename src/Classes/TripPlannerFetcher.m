//
//  TripPlannerLocatingView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/4/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripPlannerFetcher.h"
#import "DebugLogging.h"
#import "GeoLocator.h"
#import "MainQueueSync.h"
#import "ReverseGeoLocator.h"
#import "RunParallelBlocks.h"
#import "TaskLocator.h"
#import "TaskState.h"
#import "TripPlannerLocationListViewController.h"
#import "TripPlannerResultsViewController.h"
#import <Foundation/Foundation.h>

@interface TripPlannerFetcher () {
}

@property(nonatomic, strong) UINavigationController *backgroundTaskController;
@property(nonatomic) bool backgroundTaskForceResults;

@end

@implementation TripPlannerFetcher

#pragma mark Data fetchers

- (void)nextScreen:(UINavigationController *)controller
      forceResults:(bool)forceResults
         postQuery:(bool)postQuery
     taskContainer:(BackgroundTaskContainer *)taskContainer {
    bool findLocation = false;

    if (self.tripQuery.userRequest.fromPoint.useCurrentLocation == false &&
        self.tripQuery.userRequest.toPoint.useCurrentLocation == false) {
        findLocation = false;
    } else if (self.tripQuery.userRequest.fromPoint.useCurrentLocation ==
                   true &&
               !postQuery) {
        findLocation = true; // (self.tripQuery.fromPoint.lat==nil);
        self.currentEndPoint = self.tripQuery.userRequest.fromPoint;
    } else if (self.tripQuery.userRequest.toPoint.useCurrentLocation == true &&
               !postQuery) {
        findLocation = true; // (self.tripQuery.toPoint.lat==nil);
        self.currentEndPoint = self.tripQuery.userRequest.toPoint;
    }

    [self fetchAndDisplay:controller
             forceResults:forceResults
             findLocation:findLocation
            taskContainer:taskContainer];
}

- (void)subTaskFetchNames:(NSMutableArray *)geoNamesRequired
                taskState:(TaskState *)taskState {
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
                     taskState:(TaskState *)taskState {
    for (TripEndPoint *point in geoCoordsRequired) {
        GeoLocator *geoLocator = [[GeoLocator alloc] init];

        NSMutableArray<TripLegEndPoint *> *results =
            [geoLocator fetchCoordinates:point.locationDesc];

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

- (void)subTaskFetchGeosAndTrip:(NSMutableArray *)geoCoordsRequired
               geoNamesRequired:(NSMutableArray *)geoNamesRequired
                      taskState:(TaskState *)taskState {
    taskState.total +=
        (int)geoNamesRequired.count + (int)geoCoordsRequired.count;

    [taskState
        taskSubtext:NSLocalizedString(@"geolocating", @"progress message")];

    RunParallelBlocks *parallelBlocks = [RunParallelBlocks instance];

    [parallelBlocks startBlock:^{
      [self subTaskFetchNames:geoNamesRequired taskState:taskState];
    }];

    __block NSMutableArray<TripLegEndPoint *> *toList = nil;
    __block NSMutableArray<TripLegEndPoint *> *fromList = nil;

    [parallelBlocks startBlock:^{
      [self subTaskFetchCoordsFrom:&fromList
                                to:&toList
                 geoCoordsRequired:geoCoordsRequired
                         taskState:taskState];
    }];

    [parallelBlocks waitForBlocksWithState:taskState];

    if (self.tripQuery.toList == nil || self.tripQuery.fromList == nil) {
        [taskState taskSubtext:NSLocalizedString(@"planning trip",
                                                 @"progress message")];
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
           findLocation:(bool)findLocation
          taskContainer:(BackgroundTaskContainer *)taskController {
    [taskController taskRunAsync:^(TaskState *taskState) {
      NSMutableArray *geoNamesRequired = [NSMutableArray array];
      NSMutableArray *geoCoordsRequired = [NSMutableArray array];

      self.backgroundTaskController = controller;
      self.backgroundTaskForceResults = forceResults;

      bool canReverseGeocode = [ReverseGeoLocator supported];
      bool canGeocode = [GeoLocator supported];

      [taskState startAtomicTask:@"getting trip"];

      if (findLocation) {
          taskState.total++;
          
          CLLocation *location = [TaskLocator locateWithAccuracy:200.0
                                                       taskState:taskState];

          if (location) {
              TripEndPoint *point = nil;

              if (self.tripQuery.userRequest.fromPoint.useCurrentLocation) {
                  point = self.tripQuery.userRequest.fromPoint;
              } else {
                  point = self.tripQuery.userRequest.toPoint;
              }

              point.coordinates = location;
          } else {
              return (UIViewController *)nil;
          }
      }

      if (canReverseGeocode &&
          (self.tripQuery.userRequest.toPoint.useCurrentLocation ||
           self.tripQuery.userRequest.toPoint.coordinates != nil) &&
          self.tripQuery.userRequest.toPoint.locationDesc == nil) {
          [geoNamesRequired addObject:self.tripQuery.userRequest.toPoint];
      }

      if (canReverseGeocode &&
          (self.tripQuery.userRequest.fromPoint.useCurrentLocation ||
           self.tripQuery.userRequest.fromPoint.coordinates != nil) &&
          self.tripQuery.userRequest.fromPoint.locationDesc == nil) {
          [geoNamesRequired addObject:self.tripQuery.userRequest.fromPoint];
      }

      if (canGeocode &&
          [GeoLocator addressNeedsCoords:self.tripQuery.userRequest.toPoint
                                             .locationDesc] &&
          self.tripQuery.userRequest.toPoint.coordinates == nil) {
          [geoCoordsRequired addObject:self.tripQuery.userRequest.toPoint];
      }

      if (canGeocode &&
          [GeoLocator addressNeedsCoords:self.tripQuery.userRequest.fromPoint
                                             .locationDesc] &&
          self.tripQuery.userRequest.fromPoint.coordinates == nil) {
          [geoCoordsRequired addObject:self.tripQuery.userRequest.fromPoint];
      }

      self.tripQuery.toAppleFailed = NO;
      self.tripQuery.fromAppleFailed = NO;

      if (geoNamesRequired.count > 0 || geoCoordsRequired.count > 0) {
          [self subTaskFetchGeosAndTrip:geoCoordsRequired
                       geoNamesRequired:geoNamesRequired
                              taskState:taskState];
      } else {
          self.tripQuery.oneTimeDelegate = taskState;
          [taskState taskSubtext:@"planning trip"];
          [self.tripQuery fetchItineraries:nil];
          [taskState incrementItemsDoneAndDisplay];
      }

      if (self.tripQuery.fromList != nil && !self.backgroundTaskForceResults &&
          !self.tripQuery.userRequest.fromPoint.useCurrentLocation) {
          __block TripPlannerLocationListViewController *locView = nil;

          [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
            locView = [TripPlannerLocationListViewController viewController];
            locView.tripQuery = self.tripQuery;
            locView.from = true;
          }];
          // Push the detail view controller
          return (UIViewController *)locView;
      } else if (self.tripQuery.toList != nil &&
                 !self.backgroundTaskForceResults &&
                 !self.tripQuery.userRequest.toPoint.useCurrentLocation) {
          __block TripPlannerLocationListViewController *locView = nil;

          [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
            locView = [TripPlannerLocationListViewController viewController];
            locView.tripQuery = self.tripQuery;
            locView.from = false;
          }];
          // Push the detail view controller
          return (UIViewController *)locView;
      } else {
          __block TripPlannerResultsViewController *tripResults = nil;

          [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
            tripResults = [TripPlannerResultsViewController viewController];
            tripResults.tripQuery = self.tripQuery;
            [tripResults.tripQuery saveTrip];
          }];

          // Push the detail view controller
          return (UIViewController *)tripResults;
      }
    }];
}

@end
