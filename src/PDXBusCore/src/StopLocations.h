//
//  StopLocations.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import <CoreLocation/CoreLocation.h>
#import "DebugLogging.h"


#define kIncompleteDatabase @"incomplete"
#define kUnknownDatabase @"unknown"
#define kOldDatabase2    @"stopLocations2.sql"
#define kOldDatabase1    @"stopLocations.sql"
#define kRailOnlyDB      @"railLocations"
#define kSqlFile		 @"sql"
#define kSqlTrue	1
#define kSqlFalse	0

#define kDistNextToMe (kDistMile / 10)
#define kDistHalfMile 804.67200
#define kDistMile	  1609.344
#define kMaxStops	  12
#define kAccNextToMe  150
#define kAccHalfMile  150
#define kAccClosest	  250
#define kAccMile	  300
#define kAcc3Miles	  800
#define kDistMax	  16093.44  // 10 miles in meters
// #define kAnyDist	  0.0

@interface StopLocations : NSObject {
	sqlite3 *database;
	NSString *_path;
	NSMutableArray *_nearestStops;
	sqlite3_stmt *insert_statement;
	sqlite3_stmt *select_statement;
	sqlite3_stmt *replace_statement;
}


@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSMutableArray *nearestStops;
@property (nonatomic, readonly) bool isEmpty;

+ (StopLocations*)getDatabase;
+ (void)quit;

- (BOOL)insert:(int) locid lat:(double)lat lng:(double)lng rail:(bool)rail;
- (BOOL)clear;
- (void)close;
- (int)getNumberOfStops;
- (unsigned long long)getFileSize;


// This function is deprecated for now as there is a TriMet call for this.
// - (BOOL)findNearestStops:(CLLocation *)here maxToFind:(int)max minDistance:(double)min railOnly:(bool)railOnly;
- (CLLocation*) getLocation:(NSString *)stopID;

@end
