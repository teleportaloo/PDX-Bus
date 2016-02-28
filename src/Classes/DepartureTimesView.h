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

#define kSectionsPerStop	15
#define kSectionRowInit		-1

#define kCacheWarning NSLocalizedString(@"WARNING: No network - extrapolated times", @"error message")

@class XMLDepartures;
@class DepartureData;


typedef struct {
	int row [kSectionsPerStop+1];
} SECTIONROWS;

@interface DepartureTimesView :  TableViewControllerWithRefresh <UIAlertViewDelegate,
        UIActionSheetDelegate, DepartureDetailDelegate> {
	NSString *			_displayName;
	NSMutableArray *	_visibleDataArray;
	NSMutableArray *	_originalDataArray;
	bool				_blockFilter;
	bool				_blockSort;
	NSString *			_savedBlock;
	StopLocations *		_locationsDb;
	SECTIONROWS *		_sectionRows;
	NSString *			_stops;
	
	bool *				_sectionExpanded;
	
	NSIndexPath *		_actionItem;
	
	bool				_fetchingLocations;
    XMLDepartures       *_singleMapItem; // weak
	int					_bookmarkItem;
	NSString *			_bookmarkDesc;
	NSString *			_bookmarkLoc;
    bool                _reloadWhenAppears;
    bool                _allowSort;
    NSUserActivity      *_userActivity;
            
	XMLStreetcarLocations *_streetcarLocations;
    NSMutableArray      *_vehiclesStops;
}



- (id<DepartureTimesDataProvider>)departureData:(NSInteger)i;



- (void)fetchTimesForVehicleInBackground:(id<BackgroundTaskProgress>)background route:(NSString *)route direction:(NSString *)direction nextLoc:(NSString*)loc block:(NSString *)block;
- (void)fetchTimesForLocationInBackground:(id<BackgroundTaskProgress>)background loc:(NSString*)loc block:(NSString *)block;
- (void)fetchTimesForLocationInBackground:(id<BackgroundTaskProgress>)background loc:(NSString*)loc title:(NSString *)title;
- (void)fetchTimesForLocationInBackground:(id<BackgroundTaskProgress>)background loc:(NSString*)loc;
- (void)fetchTimesForLocationInBackground:(id<BackgroundTaskProgress>)background loc:(NSString*)loc names:(NSArray*)names;
- (void)fetchTimesForLocationsInBackground:(id<BackgroundTaskProgress>)background stops:(NSArray *) stops;
- (void)fetchTimesForBlockInBackground:(id<BackgroundTaskProgress>)background block:(NSString*)block start:(NSString*)start stop:(NSString*) stop;
- (void)fetchTimesForNearestStopsInBackground:(id<BackgroundTaskProgress>)background location:(CLLocation *)here maxToFind:(int)max minDistance:(double)min mode:(TripMode)mode;
- (void)fetchTimesForNearestStopsInBackground:(id<BackgroundTaskProgress>)background stops:(NSArray *)stops;
- (void)fetchTimesViaQrCodeRedirectInBackground:(id<BackgroundTaskProgress>)background URL:(NSString*)url;
- (void)fetchTimesForStopInOtherDirectionInBackground:(id<BackgroundTaskProgress>)background departure:(DepartureData*)dep;
- (void)fetchTimesForStopInOtherDirectionInBackground:(id<BackgroundTaskProgress>)background departures:(XMLDepartures*)deps;


- (void)refreshAction:(id)sender;
- (void)sortByBus;
- (void)resort;
- (void)clearSections;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

+ (BOOL)canGoDeeper;
- (void)detailsChanged;


@property (nonatomic, retain) NSMutableArray *      visibleDataArray;
@property (nonatomic, retain) NSMutableArray *      originalDataArray;
@property (nonatomic, retain) NSString *            displayName;
@property (nonatomic, retain) StopLocations *       locationsDb;
@property (nonatomic, retain) NSString *            stops;
@property (nonatomic)         bool                  blockSort;
@property (nonatomic, retain) XMLStreetcarLocations *streetcarLocations;
@property (nonatomic, retain) NSString *            bookmarkLoc;
@property (nonatomic, retain) NSString *            bookmarkDesc;
@property (nonatomic, retain) NSIndexPath *         actionItem;
@property (nonatomic, retain) NSString *            savedBlock;
@property (nonatomic)         bool                  allowSort;
@property (nonatomic, retain) NSMutableArray *      vehicleStops;
@property (nonatomic, retain) NSUserActivity *      userActivity;
@end
