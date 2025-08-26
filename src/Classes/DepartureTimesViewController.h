//
//  DepartureTimes.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BackgroundTaskContainer.h"
#import "DepartureDetailViewController.h"
#import "DepartureTimesDataProvider.h"
#import "TableViewControllerWithRefresh.h"
#import "TableViewControllerWithToolbar.h"
#import "XMLStreetcarLocations.h"
#import <IntentsUI/IntentsUI.h>
#import <UIKit/UIKit.h>

#define kSectionRowInit -1

#define kCacheWarning                                                          \
    NSLocalizedString(@"WARNING: No network - extrapolated times",             \
                      @"error message")

@class XMLDepartures;
@class Departure;

typedef NSMutableArray<NSNumber *> SectionRows;

@interface DepartureTimesViewController
    : TableViewControllerWithRefresh <DepartureDetailDelegate>

@property(nonatomic, copy) NSString *displayName;
@property(nonatomic) bool blockSort;

- (void)fetchTimesForVehicleAsync:(id<TaskController>)taskController
                            route:(NSString *)route
                        direction:(NSString *)direction
                       nextStopId:(NSString *)stopId
                            block:(NSString *)block
                  targetDeparture:(Departure *)targetDep;

- (void)fetchTimesForVehicleAsync:(id<TaskController>)taskController
                        vehicleId:(NSString *)vehicleId;

- (void)fetchTimesForLocationAsync:(id<TaskController>)taskController
                            stopId:(NSString *)stopId
                             block:(NSString *)block;

- (void)fetchTimesForLocationAsync:(id<TaskController>)taskController
                            stopId:(NSString *)stopId
                             title:(NSString *)title;

- (void)fetchTimesForLocationAsync:(id<TaskController>)taskController
                            stopId:(NSString *)stopId;

- (void)fetchTimesForLocationAsync:(id<TaskController>)taskController
                            stopId:(NSString *)stopId
                             names:(NSArray *)names;

- (void)fetchTimesForBlockAsync:(id<TaskController>)taskController
                          block:(NSString *)block
                          start:(NSString *)start
                         stopId:(NSString *)stopId;

- (void)fetchTimesForNearestStopsAsync:(id<TaskController>)taskController
                              location:(CLLocation *)here
                             maxToFind:(int)max
                           minDistance:(double)min
                                  mode:(TripMode)mode;

- (void)fetchTimesForNearestStopsAsync:(id<TaskController>)taskController
                                 stops:(NSArray<StopDistance *> *)stops;

- (void)fetchTimesViaQrCodeRedirectAsync:(id<TaskController>)taskController
                                     URL:(NSString *)url;

- (void)fetchTimesForStopInOtherDirectionAsync:
            (id<TaskController>)taskController
                                     departure:(Departure *)dep;

- (void)fetchTimesForStopInOtherDirectionAsync:
            (id<TaskController>)taskController
                                    departures:(XMLDepartures *)deps;

- (void)resort;

+ (BOOL)canGoDeeper;

@end
