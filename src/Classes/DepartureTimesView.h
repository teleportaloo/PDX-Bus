//
//  DepartureTimes.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import "StopLocations.h"
#import "DepartureTimesDataProvider.h"
#import "BackgroundTaskContainer.h"
#import "XMLStreetcarLocations.h"
#import "TableViewControllerWithRefresh.h"
#import "DepartureDetailView.h"
#import "DepartureTimesDataProvider.h"
#import <IntentsUI/IntentsUI.h>


#define kSectionRowInit        -1

#define kCacheWarning NSLocalizedString(@"WARNING: No network - extrapolated times", @"error message")

@class XMLDepartures;
@class Departure;

typedef NSMutableArray<NSNumber *> SECTIONROWS;

@interface DepartureTimesView :  TableViewControllerWithRefresh <DepartureDetailDelegate, INUIAddVoiceShortcutViewControllerDelegate>
{
    bool  _blockFilter;
    bool  _reloadWhenAppears;
    bool  _updatedWatch;
}

@property (nonatomic, strong) NSMutableArray<SECTIONROWS *> *sectionRows;
@property (nonatomic, strong) NSMutableArray<NSNumber *> * sectionExpanded;
@property (nonatomic, strong) NSMutableArray<id<DepartureTimesDataProvider>>  *visibleDataArray;
@property (nonatomic, strong) NSMutableArray<XMLDepartures*> *originalDataArray;
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, Detour*> *allDetours;
@property (nonatomic, strong) NSMutableDictionary<NSString*, Route*> *allRoutes;
@property (nonatomic, copy)   NSString *displayName;
@property (nonatomic, strong) StopLocations *locationsDb;
@property (nonatomic, copy)   NSString *stops;
@property (nonatomic)         bool blockSort;
@property (nonatomic, copy)   NSString *bookmarkLoc;
@property (nonatomic, copy)   NSString *bookmarkDesc;
@property (nonatomic, copy)   NSString *savedBlock;
@property (nonatomic)         bool allowSort;
@property (nonatomic, strong) NSMutableArray *vehicleStops;
@property (nonatomic, strong) NSUserActivity *userActivity;

- (void)fetchTimesForVehicleAsync:(id<BackgroundTaskController>)task route:(NSString *)route direction:(NSString *)direction nextLoc:(NSString*)loc block:(NSString *)block targetDeparture:(Departure *)targetDep;
- (void)fetchTimesForVehicleAsync:(id<BackgroundTaskController>)task vehicleId:(NSString *)vehicleId;
- (void)fetchTimesForLocationAsync:(id<BackgroundTaskController>)task loc:(NSString*)loc block:(NSString *)block;
- (void)fetchTimesForLocationAsync:(id<BackgroundTaskController>)task loc:(NSString*)loc title:(NSString *)title;
- (void)fetchTimesForLocationAsync:(id<BackgroundTaskController>)task loc:(NSString*)loc;
- (void)fetchTimesForLocationAsync:(id<BackgroundTaskController>)task loc:(NSString*)loc names:(NSArray*)names;
- (void)fetchTimesForBlockAsync:(id<BackgroundTaskController>)task block:(NSString*)block start:(NSString*)start stop:(NSString*) stop;
- (void)fetchTimesForNearestStopsAsync:(id<BackgroundTaskController>)task location:(CLLocation *)here maxToFind:(int)max minDistance:(double)min mode:(TripMode)mode;
- (void)fetchTimesForNearestStopsAsync:(id<BackgroundTaskController>)task stops:(NSArray<StopDistance*>*)stops;
- (void)fetchTimesViaQrCodeRedirectAsync:(id<BackgroundTaskController>)task URL:(NSString*)url;
- (void)fetchTimesForStopInOtherDirectionAsync:(id<BackgroundTaskController>)task departure:(Departure*)dep;
- (void)fetchTimesForStopInOtherDirectionAsync:(id<BackgroundTaskController>)task departures:(XMLDepartures*)deps;

- (void)refreshAction:(id)sender;
- (void)sortByBus;
- (void)resort;
- (void)clearSections;
- (void)detailsChanged;

+ (BOOL)canGoDeeper;

@end
