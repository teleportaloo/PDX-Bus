//
//  StopLocations.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "StopLocations.h"
#import "StopDistance.h"
#import "UserFaves.h"
#import "DebugLogging.h"
#import "CLLocation+Helper.h"

@implementation StopLocations

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

+ (StopLocations*)getWritableDatabase
{
    [StopLocations quit];
    
    singleton = [[StopLocations alloc] initWritable];
    
    return singleton;
}


+ (void)quit
{
    if (singleton != nil)
    {
        [singleton close];
        singleton = nil;
    }
}

#pragma mark Database initialization

- (void)close
{
    if (_database !=nil)
    {
        if (_insert_statement !=nil)
        {
            sqlite3_finalize(_insert_statement);
            _insert_statement = nil;
        }
        
        if (_replace_statement !=nil)
        {
            sqlite3_finalize(_replace_statement);
            _replace_statement = nil;
        }
        
        if (_select_statement !=nil)
        {
            sqlite3_finalize(_select_statement);
            _select_statement = nil;
        }
        sqlite3_close(_database);
        _database = nil;
        
        DEBUG_LOG(@"Database path:%@\n",self.path);
    }
}

- (void)open
{    
//    SafeUserData *userData = [SafeUserData singleton]; 
    
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
    
    int options = 0;
    
    if (_writable)
    {
        options = SQLITE_OPEN_READWRITE;
    }
    else
    {
        options = SQLITE_OPEN_READONLY;
    }
    
    if (sqlite3_open_v2(self.path.UTF8String, &_database,options, NULL) != SQLITE_OK)
    {
        sqlite3_close(_database);
        NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(_database));
    }

}

- (void)setup
{
    if (_writable)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = paths.firstObject;
        NSError *error = nil;
        self.path = [documentsDirectory stringByAppendingPathComponent:kRailOnlyDB];
        
        [fileManager copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"blank" ofType:kSqlFile]
                             toPath:self.path error:&error];
    }
    else
    {
        self.path = [[NSBundle mainBundle] pathForResource:kRailOnlyDB ofType:kSqlFile];
    }
    
    CODE_LOG(@"\n--------\nLocation DB file path\n--------\n%@\n", self.path);
    
    _database = nil;
    
    [self open];
}

- (instancetype) init
{
    if ((self = [super init]))
    {
        // The database for rail stops is now part of the resources and isn't a document.
    
        [self setup];
    }
    
    return self;
}


- (instancetype) initWritable
{
    if ((self = [super init]))
    {
        // The database for rail stops is now part of the resources and isn't a document.
        _writable = YES;
        
        [self setup];
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
    NSString *documentsDirectory = paths.firstObject;
    self.path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", kRailOnlyDB, kSqlFile]];
    
    [fileManager removeItemAtPath:self.path error:&error];
    
    if ([fileManager copyItemAtPath:noStops toPath:self.path error:&error] == NO) {
        NSAssert1(0, @"Failed to copy data with error message '%@'.", [error localizedDescription]);
    }
    
    [self open];

    [[SafeUserData sharedInstance] setLocationDatabaseDate:kUnknownDate];
    
    DEBUG_LOG(@"New location database path: %@\n", self.path);
    
    return YES;
}


- (bool) isEmpty
{
    bool res = YES;
    // Get the primary key for all books.
    
    if (_database == nil)
    {
        return YES;
    }
    
    if (_select_statement==nil)
    {
        static const char *sql = "SELECT locid FROM stops";
        // Preparing a statement compiles the SQL query into a byte-code program in the SQLite library.
        // The third parameter is either the length of the SQL string or -1 to read up to the first null terminator.        
        if (sqlite3_prepare_v2(_database, sql, -1, &_select_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(_database));
        }
    }
    
    // We "step" through the results - once for each row.
    if (sqlite3_step(_select_statement) == SQLITE_ROW)
    {
        res = FALSE;
    }

    sqlite3_reset(_select_statement);
    return res;
}


- (void) dealloc
{
    
    [self close];
}

#pragma mark Data accessors

-(unsigned long long)fileSize
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = nil;
    
    // This allows this to run on a 3.0 iPhone but makes the warning go away

    fileAttributes = [fileManager attributesOfItemAtPath:self.path error:nil];
        
    if (fileAttributes != nil) {
        NSNumber *fileSize = fileAttributes[NSFileSize];
        if (fileSize != nil) {
            return fileSize.unsignedLongLongValue;
        }
    }
    return 0;
}

- (int)mumberOfStops
{
    sqlite3_stmt *count_statement = nil;
    static char *sql = "SELECT COUNT(*) FROM STOPS";
    if (sqlite3_prepare_v2(_database, sql, -1, &count_statement, NULL) != SQLITE_OK) {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(_database));
        return 0;
    }
    sqlite3_step(count_statement);
    
    int count = sqlite3_column_int(count_statement, 0);
    
    sqlite3_finalize(count_statement);
    
    return count;
}

- (BOOL)insert:(int) locid lat:(double)lat lng:(double)lng rail:(bool)rail
{
    if (_insert_statement == nil)
    {
        static char *sql = "INSERT INTO stops (locid,lat,lng,rail) VALUES(?,?,?,?)";
        if (sqlite3_prepare_v2(_database, sql, -1, &_insert_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(_database));
            return FALSE;
        }
    }
    
    if (_replace_statement == nil)
    {
        static char *sql = "REPLACE INTO stops (locid,lat,lng,rail) VALUES(?,?,?,?)";
        if (sqlite3_prepare_v2(_database, sql, -1, &_replace_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(_database));
            return FALSE;
        }
    }
    
    sqlite3_stmt * insert_or_replace;
    
    if (rail)
    {
        insert_or_replace = _replace_statement;
    }
    else {
        insert_or_replace = _insert_statement;
    }

    
    if (sqlite3_bind_int(insert_or_replace, 1, locid) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to bind locid into the database with message '%s'.", sqlite3_errmsg(_database));
        return FALSE;    
    }
    
    
    if (sqlite3_bind_double(insert_or_replace, 2, lat) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to bind lat into the database with message '%s'.", sqlite3_errmsg(_database));
        return FALSE;    
    }
    
    
    if (sqlite3_bind_double(insert_or_replace, 3, lng) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to bind lng into the database with message '%s'.", sqlite3_errmsg(_database));
        return FALSE;
    }
    
    if (sqlite3_bind_int(insert_or_replace, 4, rail) != SQLITE_OK)
    {
        NSAssert1(0, @"Error: failed to bind lng into the database with message '%s'.", sqlite3_errmsg(_database));
        return FALSE;
    }
    
    
    sqlite3_step(insert_or_replace);
    
    if (sqlite3_reset(insert_or_replace) != SQLITE_OK) {
     printf("Error: failed to insert into the database with message '%s'.", sqlite3_errmsg(_database));
      NSAssert1(0, @"Error: failed to insert into the database with message '%s'.", sqlite3_errmsg(_database));
        return FALSE;
    }
    // printf("Inserted %d\n", locid);
    
    return TRUE;
}

- (CLLocation*) getLocation:(NSString *)stopID
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
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        // We "step" through the results - once for each row.
        while (sqlite3_step(statement) == SQLITE_ROW) {
            
            // The second parameter indicates the column index into the result set.
            // locid = sqlite3_column_int(statement, 0);
            lat = sqlite3_column_double(statement, 1);
            lng = sqlite3_column_double(statement, 2);
            
            stopLocation =[CLLocation withLat:lat lng:lng];
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




@end
