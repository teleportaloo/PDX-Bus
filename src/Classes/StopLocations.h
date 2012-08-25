//
//  StopLocations.h
//  PDX Bus
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
#import <sqlite3.h>
#import <CoreLocation/CoreLocation.h>
#import "debug.h"


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
- (CLLocation*) getLocaction:(NSString *)stopID;

@end
