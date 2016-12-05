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
#import "AlertViewCancelsTask.h"
#import "DepartureDetailView.h"
#import "DepartureTimesDataProvider.h"


#define kSectionRowInit		-1

#define kCacheWarning NSLocalizedString(@"WARNING: No network - extrapolated times", @"error message")

@class XMLDepartures;
@class DepartureData;

typedef NSMutableArray<NSNumber *> SECTIONROWS;

@interface DepartureTimesView :  TableViewControllerWithRefresh <UIAlertViewDelegate,
        UIActionSheetDelegate, DepartureDetailDelegate> {
	NSString *                                          _displayName;
	NSMutableArray<id<DepartureTimesDataProvider>> *	_visibleDataArray;
	NSMutableArray<XMLDepartures*> *                    _originalDataArray;
	bool                                                _blockFilter;
	bool                                                _blockSort;
	NSString *                                          _savedBlock;
	StopLocations *                                     _locationsDb;
	NSString *                                          _stops;
    NSMutableArray<SECTIONROWS *> *                     _sectionRows;
	NSMutableArray<NSNumber *> *                        _sectionExpanded;
	NSIndexPath *                                       _actionItem;
	bool                                                _fetchingLocations;
    XMLDepartures *                                     _singleMapItem; // weak
	int                                                 _bookmarkItem;
	NSString *                                          _bookmarkDesc;
	NSString *                                          _bookmarkLoc;
    bool                                                _reloadWhenAppears;
    bool                                                _allowSort;
    NSUserActivity *                                    _userActivity;
    dispatch_once_t                                     _updatedWatch;
	XMLStreetcarLocations *                             _streetcarLocations;
    NSMutableArray      *                               _vehiclesStops;
}

- (void)fetchTimesForVehicleAsync:(id<BackgroundTaskProgress>)background route:(NSString *)route direction:(NSString *)direction nextLoc:(NSString*)loc block:(NSString *)block;
- (void)fetchTimesForLocationAsync:(id<BackgroundTaskProgress>)background loc:(NSString*)loc block:(NSString *)block;
- (void)fetchTimesForLocationAsync:(id<BackgroundTaskProgress>)background loc:(NSString*)loc title:(NSString *)title;
- (void)fetchTimesForLocationAsync:(id<BackgroundTaskProgress>)background loc:(NSString*)loc;
- (void)fetchTimesForLocationAsync:(id<BackgroundTaskProgress>)background loc:(NSString*)loc names:(NSArray*)names;
- (void)fetchTimesForLocationsAsync:(id<BackgroundTaskProgress>)background stops:(NSArray *) stops;
- (void)fetchTimesForBlockAsync:(id<BackgroundTaskProgress>)background block:(NSString*)block start:(NSString*)start stop:(NSString*) stop;
- (void)fetchTimesForNearestStopsAsync:(id<BackgroundTaskProgress>)background location:(CLLocation *)here maxToFind:(int)max minDistance:(double)min mode:(TripMode)mode;
- (void)fetchTimesForNearestStopsAsync:(id<BackgroundTaskProgress>)background stops:(NSArray *)stops;
- (void)fetchTimesViaQrCodeRedirectAsync:(id<BackgroundTaskProgress>)background URL:(NSString*)url;
- (void)fetchTimesForStopInOtherDirectionAsync:(id<BackgroundTaskProgress>)background departure:(DepartureData*)dep;
- (void)fetchTimesForStopInOtherDirectionAsync:(id<BackgroundTaskProgress>)background departures:(XMLDepartures*)deps;


- (void)refreshAction:(id)sender;
- (void)sortByBus;
- (void)resort;
- (void)clearSections;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

+ (BOOL)canGoDeeper;
- (void)detailsChanged;

@property (nonatomic, retain) NSMutableArray<SECTIONROWS *> *sectionRows;
@property (nonatomic, retain) NSMutableArray<NSNumber *> * sectionExpanded;
@property (nonatomic, retain) NSMutableArray<id<DepartureTimesDataProvider>>  *      visibleDataArray;
@property (nonatomic, retain) NSMutableArray<XMLDepartures*> *                       originalDataArray;
@property (nonatomic, copy)   NSString *            displayName;
@property (nonatomic, retain) StopLocations *       locationsDb;
@property (nonatomic, copy)   NSString *            stops;
@property (nonatomic)         bool                  blockSort;
@property (nonatomic, retain) XMLStreetcarLocations *streetcarLocations;
@property (nonatomic, copy)   NSString *            bookmarkLoc;
@property (nonatomic, copy)   NSString *            bookmarkDesc;
@property (nonatomic, retain) NSIndexPath *         actionItem;
@property (nonatomic, copy)   NSString *            savedBlock;
@property (nonatomic)         bool                  allowSort;
@property (nonatomic, retain) NSMutableArray *      vehicleStops;
@property (nonatomic, retain) NSUserActivity *      userActivity;
@end
