//
//  DepartureTimes.h
//  TriMetTimes
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import "StopLocations.h"
#import "DepartureTimesDataProvider.h"
#import "BackgroundTaskContainer.h"
#import "XMLStreetcarLocations.h"
#import "PullRefreshTableViewController.h"
#import "AlertViewCancelsTask.h"

#define kSectionsPerStop	13
#define kSectionRowInit		-1

#define kCacheWarning @"WARNING: No network - extrapolated times"

@class XMLDepartures;
@class Departure;


typedef struct {
	int row [kSectionsPerStop+1];
} SECTIONROWS;

@interface DepartureTimesView :  PullRefreshTableViewController <UIAlertViewDelegate, 
        UIActionSheetDelegate> {
	NSString *			_displayName;
	NSMutableArray *	_visibleDataArray;
	NSMutableArray *	_originalDataArray;
	bool				_blockFilter;
	bool				_blockSort;
	NSString *			_savedBlock;
	StopLocations *		_locationsDb;
	SECTIONROWS *		_sectionRows;
	NSString *			_stops;
	NSTimer *			_refreshTimer;
	bool *				_sectionExpanded;
	
	UIBarButtonItem *	_refreshButton;
	
	NSIndexPath *		_actionItem;
	
	NSDate *			_lastRefresh;
    bool                _timerPaused;
	bool				_fetchingLocations;
	int					_bookmarkItem;
	NSString *			_bookmarkDesc;
	NSString *			_bookmarkLoc;
            
	XMLStreetcarLocations *_streetcarLocations;
}



- (id<DepartureTimesDataProvider>)departureData:(int)i;


- (void)fetchTimesForLocationInBackground:(id<BackgroundTaskProgress>)background loc:(NSString*)loc block:(NSString *)block;
- (void)fetchTimesForLocationInBackground:(id<BackgroundTaskProgress>)background loc:(NSString*)loc title:(NSString *)title;
- (void)fetchTimesForLocationInBackground:(id<BackgroundTaskProgress>)background loc:(NSString*)loc;
- (void)fetchTimesForLocationInBackground:(id<BackgroundTaskProgress>)background loc:(NSString*)loc names:(NSArray*)names;
- (void)fetchTimesForLocationsInBackground:(id<BackgroundTaskProgress>)background stops:(NSArray *) stops;
- (void)fetchTimesForBlockInBackground:(id<BackgroundTaskProgress>)background block:(NSString*)block start:(NSString*)start stop:(NSString*) stop;
- (void)fetchTimesForNearestStopsInBackground:(id<BackgroundTaskProgress>)background location:(CLLocation *)here maxToFind:(int)max minDistance:(double)min mode:(TripMode)mode;
- (void)fetchTimesForNearestStopsInBackground:(id<BackgroundTaskProgress>)background stops:(NSArray *)stops;
- (void)fetchTimesViaQrCodeRedirectInBackground:(id<BackgroundTaskProgress>)background URL:(NSString*)url;


- (void)refreshAction:(id)sender;
- (void)sortByBus;
- (void)resort;
- (void)clearSections;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)stopTimer;
+ (BOOL)canGoDeeper;

@property (nonatomic, retain) NSTimer *refreshTimer;
@property (nonatomic, retain) NSMutableArray *visibleDataArray;
@property (nonatomic, retain) NSMutableArray *originalDataArray;
@property (nonatomic, retain) NSString *displayName;
@property (nonatomic, retain) StopLocations *locationsDb;
@property (nonatomic, retain) NSString *stops;
@property (nonatomic) bool blockSort;
@property (nonatomic, retain) UIBarButtonItem *refreshButton;
@property (nonatomic, retain) NSDate *lastRefresh;
@property (nonatomic, retain) XMLStreetcarLocations *streetcarLocations;
@property (nonatomic, retain) NSString *bookmarkLoc;
@property (nonatomic, retain) NSString *bookmarkDesc;
@property (nonatomic, retain) NSIndexPath *actionItem;
@property (nonatomic, retain) NSString *savedBlock;
@end
