//
//  StopLocations.m
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

#import "StopLocations.h"
#import "StopDistance.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "UserFaves.h"
#import "debug.h"

@implementation StopLocations

@synthesize path = _path;
@synthesize nearestStops = _nearestStops;
@dynamic isEmpty;

#pragma mark Singleton 

static StopLocations *singleton;

+ (StopLocations *)getDatabase
{
	if (singleton == nil)
	{
		singleton = [[StopLocations alloc] init];
	}
	return singleton;
	
}

+ (void)quit
{
	if (singleton != nil)
	{
		[singleton close];
		[singleton release];
		singleton = nil;
	}
}

#pragma mark Database initialization

- (void)close
{
	if (database !=nil)
	{
		if (insert_statement !=nil)
		{
			sqlite3_finalize(insert_statement);
			insert_statement = nil;
		}
		
		if (replace_statement !=nil)
		{
			sqlite3_finalize(replace_statement);
			replace_statement = nil;
		}
		
		if (select_statement !=nil)
		{
			sqlite3_finalize(select_statement);
			select_statement = nil;
		}
		sqlite3_close(database);
		database = nil;
	}
}

- (void)open
{	
//	SafeUserData *userData = [SafeUserData getSingleton]; 
	
	[self close];
	
	
	/* User no longer updates this so no need to check */
	/*
	if ([[userData getLocationDatabaseDateString] isEqualToString:kIncompleteDatabase])
	{
		[userData setLocationDatabaseDate:kUnknownDatabase];
		[self clear];
		return;
	}
	 */
	
	
	if (sqlite3_open_v2([self.path UTF8String], &database,SQLITE_OPEN_READONLY, NULL) != SQLITE_OK)
	{
		sqlite3_close(database);
		NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));
	}

}

- (id) init
{
	if ((self = [super init]))
	{
		// The database for rail stops is now part of the resources and isn't a document.
		
		self.path = [[NSBundle mainBundle] pathForResource:kRailOnlyDB ofType:kSqlFile];
		
		
		/*
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		NSError *error = nil;
		self.path = [documentsDirectory stringByAppendingPathComponent:kRailAwareStopDB];
		self.railAwarePath = self.path;
		NSString *oldPath = [documentsDirectory stringByAppendingPathComponent:kStopDB];
		*/
    
        
		database = nil;

		[self open];
	}
	
	return self;
}

- (BOOL)clear
{
	[self close];
	
	NSError *error = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *noStops = [[NSBundle mainBundle] pathForResource:@"blank" ofType:@"sql"];
	
	// In this case we are making a new database which is part of the document section.  The 
	// developer will need to copy this file into the project to make the "real" one to be
	// shipped.
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	self.path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", kRailOnlyDB, kSqlFile]];
	
	[fileManager removeItemAtPath:self.path error:&error];
	
	if ([fileManager copyItemAtPath:noStops toPath:self.path error:&error] == NO) {
		NSAssert1(0, @"Failed to copy data with error message '%@'.", [error localizedDescription]);
	}
	
	[self open];

	[[SafeUserData getSingleton] setLocationDatabaseDate:kUnknownDate];
	
	DEBUG_LOG(@"New location database path: %@\n", self.path);
	
	return YES;
}


- (bool) isEmpty
{
	bool res = YES;
	// Get the primary key for all books.
	
	if (database == nil)
	{
		return YES;
	}
	
	if (select_statement==nil)
	{
		static const char *sql = "SELECT locid FROM stops";
		// Preparing a statement compiles the SQL query into a byte-code program in the SQLite library.
		// The third parameter is either the length of the SQL string or -1 to read up to the first null terminator.        
		if (sqlite3_prepare_v2(database, sql, -1, &select_statement, NULL) != SQLITE_OK) {
			NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
		}
	}
	
	// We "step" through the results - once for each row.
	if (sqlite3_step(select_statement) == SQLITE_ROW)
	{
		res = FALSE;
	}

	sqlite3_reset(select_statement);
	return res;
}


- (void) dealloc
{
	self.path = nil;
	self.nearestStops = nil;
	
	[self close];
	[super dealloc];
}

#pragma mark Data accessors

-(unsigned long long)getFileSize
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSDictionary *fileAttributes = nil;
	
	// This allows this to run on a 3.0 iPhone but makes the warning go away
#ifdef __IPHONE_4_0
	if ([fileManager respondsToSelector:@selector(attributesOfItemAtPath:error:)])
	{
		fileAttributes = [fileManager attributesOfItemAtPath:self.path error:nil];
	}
	else
#endif
	{
		fileAttributes = [(id)fileManager fileAttributesAtPath:self.path traverseLink:NO];
	}
		
	if (fileAttributes != nil) {
		NSNumber *fileSize;
		if ((fileSize = [fileAttributes objectForKey:NSFileSize])) {
			return [fileSize unsignedLongLongValue];
		}
	}
	return 0;
}

- (int)getNumberOfStops
{
	sqlite3_stmt *count_statement = nil;
	static char *sql = "SELECT COUNT(*) FROM STOPS";
	if (sqlite3_prepare_v2(database, sql, -1, &count_statement, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
		return 0;
	}
	sqlite3_step(count_statement);
	
	int count = sqlite3_column_int(count_statement, 0);
	
	sqlite3_finalize(count_statement);
	
	return count;
}

- (BOOL)insert:(int) locid lat:(double)lat lng:(double)lng rail:(bool)rail
{
	if (insert_statement == nil) 
	{
        static char *sql = "INSERT INTO stops (locid,lat,lng,rail) VALUES(?,?,?,?)";
        if (sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
			return FALSE;
        }
	}
	
	if (replace_statement == nil) 
	{
        static char *sql = "REPLACE INTO stops (locid,lat,lng,rail) VALUES(?,?,?,?)";
        if (sqlite3_prepare_v2(database, sql, -1, &replace_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
			return FALSE;
        }
	}
	
	sqlite3_stmt * insert_or_replace;
	
	if (rail)
	{
		insert_or_replace = replace_statement;
	}
	else {
		insert_or_replace = insert_statement;
	}

	
	if (sqlite3_bind_int(insert_or_replace, 1, locid) != SQLITE_OK)
	{
		NSAssert1(0, @"Error: failed to bind locid into the database with message '%s'.", sqlite3_errmsg(database));
		return FALSE;	
	}
	
	
	if (sqlite3_bind_double(insert_or_replace, 2, lat) != SQLITE_OK)
	{
		NSAssert1(0, @"Error: failed to bind lat into the database with message '%s'.", sqlite3_errmsg(database));
		return FALSE;	
	}
	
	
	if (sqlite3_bind_double(insert_or_replace, 3, lng) != SQLITE_OK)
	{
		NSAssert1(0, @"Error: failed to bind lng into the database with message '%s'.", sqlite3_errmsg(database));
		return FALSE;
	}
	
	if (sqlite3_bind_int(insert_or_replace, 4, rail) != SQLITE_OK)
	{
		NSAssert1(0, @"Error: failed to bind lng into the database with message '%s'.", sqlite3_errmsg(database));
		return FALSE;
	}
	
	
	sqlite3_step(insert_or_replace);
	
    if (sqlite3_reset(insert_or_replace) != SQLITE_OK) {
      //  NSAssert1(0, @"Error: failed to insert into the database with message '%s'.", sqlite3_errmsg(database));
		return FALSE;
    }
	// printf("Inserted %d\n", locid);
	
	return TRUE;
}

- (CLLocation*) getLocaction:(NSString *)stopID
{
	CLLocation *stopLocation = nil;
	// int locid;
	double lat;
	double lng;
	
	const char *sql = 
		[[NSString stringWithFormat:@"SELECT locid,lat,lng FROM stops WHERE locid = %@", stopID] 
		 cStringUsingEncoding:NSUTF8StringEncoding];
	sqlite3_stmt *statement;
	// Preparing a statement compiles the SQL query into a byte-code program in the SQLite library.
	// The third parameter is either the length of the SQL string or -1 to read up to the first null terminator.        
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		// We "step" through the results - once for each row.
		while (sqlite3_step(statement) == SQLITE_ROW) {
			
			// The second parameter indicates the column index into the result set.
			// locid = sqlite3_column_int(statement, 0);
			lat = sqlite3_column_double(statement, 1);
			lng = sqlite3_column_double(statement, 2);
			
			stopLocation = [[[CLLocation alloc] initWithLatitude:lat longitude:lng] autorelease];
		}
	}
	
	sqlite3_finalize(statement);
	/*		
	 for (i=0; i< [self.nearestStops count]; i++)
	 {
	 StopDistance *dist = [self.nearestStops objectAtIndex:i];
	 // printf("%s %f\n",  [dist.locid cStringUsingEncoding:NSUTF8StringEncoding], dist.distance);
	 }
	 */	
	return stopLocation;
}

- (BOOL)findNearestStops:(CLLocation *)here maxToFind:(int)max minDistance:(double)min railOnly:(bool)railOnly;
{
	CLLocation *stopLocation = nil;
	int locid;
	double lat;
	double lng;
	self.nearestStops = [[[NSMutableArray alloc] init] autorelease];
	CLLocationDistance curDist;
	int i;
	StopDistance *stopDistance;
	StopDistance *newDistance;
	
	const char *sql;
	
	
	if (railOnly)
	{
		sql = "SELECT locid,lat,lng FROM stops WHERE rail = 1";
	}
	else
	{
		sql = "SELECT locid,lat,lng FROM stops";
	}
	sqlite3_stmt *statement;
	// Preparing a statement compiles the SQL query into a byte-code program in the SQLite library.
	// The third parameter is either the length of the SQL string or -1 to read up to the first null terminator.        
	if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
		// We "step" through the results - once for each row.
		while (sqlite3_step(statement) == SQLITE_ROW) {
			
			// The second parameter indicates the column index into the result set.
			locid = sqlite3_column_int(statement, 0);
			lat = sqlite3_column_double(statement, 1);
			lng = sqlite3_column_double(statement, 2);
			
			stopLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
#ifdef __IPHONE_3_2
			if ([here respondsToSelector:@selector(distanceFromLocation:)])
			{
				curDist = [here distanceFromLocation:stopLocation];
			}
			else
#endif
			{
				// Cast avoids pragma warning
				curDist = [(id)here getDistanceFrom:stopLocation];
			}
			[stopLocation release];
			
			if (min == 0.0  || curDist < min)
			{
			
				for (i=0; i < [self.nearestStops count]; i++)
				{
					stopDistance = [self.nearestStops objectAtIndex:i];
					if (stopDistance.distance > curDist )
					{
						break;
					}
				}
				
				if ( i < [self.nearestStops count])
				{
					newDistance = [[StopDistance alloc] initWithLocId:locid distance:curDist accuracy:here.horizontalAccuracy];
					[self.nearestStops insertObject:newDistance atIndex:i]; 
					[newDistance release];
					
					while ([self.nearestStops count] > max)
					{
						[self.nearestStops removeObjectAtIndex:[self.nearestStops count]-1];
					}
				}
				else if ([self.nearestStops count] < max)
				{
					newDistance = [[StopDistance alloc] initWithLocId:locid distance:curDist accuracy:here.horizontalAccuracy];
					[self.nearestStops addObject:newDistance]; 
					[newDistance release];
				}
			}
		}
	}
	
	sqlite3_finalize(statement);

	return YES;
	
}



@end
