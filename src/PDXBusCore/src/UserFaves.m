//
//  UserFaves.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/17/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "UserFaves.h"
#import "DebugLogging.h"
#import "StopLocations.h"
#import "NSMutableDictionary+MutableElements.h"


@implementation SafeUserData

@synthesize appData = _appData;
@dynamic faves;
@dynamic favesArrivalsOnly;
@dynamic recents;
@dynamic recentTrips;
@dynamic last;
@dynamic lastTrip;
@dynamic lastNames;
@dynamic lastLocate;
@dynamic lastRun;
@synthesize favesChanged = _favesChanged;
@synthesize sharedUserCopyOfPlist = _sharedUserCopyOfPlist;
@synthesize lastRunKey = _lastRunKey;

- (void)dealloc
{
    self.appData = nil;
    self.sharedUserCopyOfPlist = nil;
    self.lastRunKey = nil;
	[super dealloc];
}

- (void)memoryWarning
{
    DEBUG_LOG(@"Clearing app data %p\n", self.appData);
    [self cacheAppData];
    self.appData = nil;
}

- (NSMutableArray*)getOrInitRecentTrips
{
    NSMutableArray *recentTrips = self.appData[kRecentTrips];
    
    if (recentTrips == nil)
    {
        recentTrips = [NSMutableArray array];
        
        self.appData[kRecentTrips] = recentTrips;
        [self cacheAppData];
    }
    
    return recentTrips;
}

- (void)load
{
    if (self.appData == nil)
    {
        // We have to read the property list and make it mutable
        self.appData = [NSMutableDictionary mutableContainersWithContentsOfURL:self.sharedUserCopyOfPlist.urlToSharedFile];
        
        [self getOrInitRecentTrips];
        
    }
}

- (instancetype)init {
	if ((self = [super init]))
	{
        self.sharedUserCopyOfPlist = [[[SharedFile alloc] initWithFileName:@"appData.plist" initFromBundle:YES] autorelease];
        self.readOnly = FALSE;
        self.lastRunKey = kLastRunApp;
        [self load];
	}
	return self;
}

+ (SafeUserData *)sharedInstance
{
	static SafeUserData *singleton = nil;
	
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		singleton = [[SafeUserData alloc] init];
        [MemoryCaches addCache:singleton];
    });
	return singleton;
}

- (void)cacheAppData
{
	@synchronized (self)
	{
        if (self.appData && !self.readOnly)
        {
            [self.sharedUserCopyOfPlist writeDictionary:self.appData];
        }
	}
}

-(void)clearLastArrivals
{
	@synchronized (self)
	{
        [self load];
		self.appData[kLast] = @"";
		[self.appData removeObjectForKey:kLastNames];
	}
}

- (void)setLastArrivals:(NSString *)locations
{
	@synchronized (self)
	{
        [self load];
		self.appData[kLast] = locations;
	
		DEBUG_PRINTF("setLastArrivals %s\n", [locations cStringUsingEncoding:NSUTF8StringEncoding]);
		[self cacheAppData];
	}
}

- (void)setLastNames:(NSArray *)names
{
	@synchronized (self)
	{
        [self load];
		if (names != nil)
		{
			self.appData[kLastNames] = names;
		}
		else {
			[self.appData removeObjectForKey:kLastNames];
		}

		[self cacheAppData];
	}
}

- (NSDictionary *)getTakeMeHomeUserRequest
{
    @synchronized (self)
	{
        [self load];
		NSMutableDictionary *takeMeHome   = self.appData[kTakeMeHome];
		
		return takeMeHome;
	}
}

- (void)saveTakeMeHomeUserRequest:(NSDictionary *)userRequest
{
    @synchronized (self)
	{
        [self load];
        self.appData[kTakeMeHome] = userRequest;
        
        [self cacheAppData];
    }
}


- (NSDictionary *)tripArchive:(NSDictionary *)userRequest description:(NSString *)desc blob:(NSData *)blob
{
    NSMutableDictionary *newItem = [NSMutableDictionary dictionary];
    
    newItem[kUserFavesTrip] = userRequest;
    newItem[kUserFavesTripResults] = blob;
    newItem[kUserFavesChosenName] = desc;
    
    return newItem;

}

- (void)addToRecentTripsWithUserRequest:(NSDictionary*)userRequest description:(NSString *)desc blob:(NSData *)blob
{
	@synchronized (self)
	{
        [self load];
        
        NSMutableArray *recentTrips   =  [self getOrInitRecentTrips];
        NSDictionary *newItem = [self tripArchive:userRequest description:desc blob:blob];
    
		[recentTrips insertObject:newItem atIndex:0];
		
	
		
		int maxRecents = [UserPrefs sharedInstance].maxRecentTrips;
		
		while (recentTrips.count > maxRecents)
		{
			[recentTrips removeObjectAtIndex:(recentTrips.count-1)];
		}
		
		_favesChanged = true;
		[self cacheAppData];
	}
}

- (NSDictionary *)addToRecentsWithLocation:(NSString *)locid description:(NSString *)desc
{
	@synchronized (self)
	{
        [self load];
        
        NSMutableDictionary *newItem = nil;
        
		// NSMutableArray *userFaves = [self.favesAndRecents objectForKey:kFaves];
		NSMutableArray *recents   = self.appData[kRecents];
		
		
		/*
		 NSEnumerator *i = [userFaves objectEnumerator];
		 NSDictionary *d;
		 
		 for (d= i.nextObject; d!=nil; d=i.nextObject)
		 {
		 if ([[d objectForKey:kUserFavesLocation] isEqualToString:locid])
		 {
		 return;
		 }
		 }
		 */
		
		int j = 0;
		
		
		for (j = 0; j < recents.count ; j++)
		{
			if ([recents[j][kUserFavesLocation] isEqualToString:locid])
			{
				[recents removeObjectAtIndex:j];
				j--;
			}	
		}
		
        newItem = [NSMutableDictionary dictionary];
		
		newItem[kUserFavesLocation]     = locid;
		newItem[kUserFavesOriginalName] = desc;
		newItem[kUserFavesChosenName]   = desc;
		
		
		[recents insertObject:newItem atIndex:0];
		
		int maxRecents = [UserPrefs sharedInstance].maxRecentStops;
		
		while (recents.count > maxRecents)
		{
			[recents removeObjectAtIndex:(recents.count-1)];
		}
		
		_favesChanged = true;
        [self cacheAppData];
        
        return newItem;
	}
}

- (NSMutableArray *)faves
{
	@synchronized (self)
	{
        [self load];
		return self.appData[kFaves];
	}
}

- (NSArray*)favesArrivalsOnly
{
    @synchronized (self)
    {
        [self load];
        
        NSMutableArray *favesArrivalsOnly = [NSMutableArray array];
        NSMutableArray *faves = self.faves;
        
        NSDictionary *item;
        
        
        for (item in faves)
        {
            if (item[kUserFavesTrip] == nil)
            {
                [favesArrivalsOnly addObject:item];
            }
        }
        
        return favesArrivalsOnly;
    }
    
}

- (NSMutableArray *)recents
{
	@synchronized (self)
	{
        self.appData = nil;
        [self load];
		return self.appData[kRecents];
	}
}

- (NSMutableArray *)recentTrips
{
	@synchronized (self)
	{
        [self load];
		return self.appData[kRecentTrips];
	}
}

- (NSString *)last
{
	@synchronized (self)
	{
        [self load];
		return self.appData[kLast];
	}
}

- (NSArray *)lastNames
{
	@synchronized (self)
	{
        [self load];
		return self.appData[kLastNames];
	}
}

- (void)setLastRun:(NSDate *)last
{
	@synchronized (self)
	{
        [self load];
		if (last!=nil)
		{
			self.appData[self.lastRunKey] = last;
		}
		else
		{
			[self.appData removeObjectForKey:kLastRunWatch];
            [self.appData removeObjectForKey:kLastRunApp];
		}
	}
	[self cacheAppData];
}

- (NSDate *)lastRun
{
	@synchronized (self)
	{
        self.appData = nil;
        [self load];
		return self.appData[self.lastRunKey];
	}	
}

- (NSMutableDictionary *)lastTrip
{
	@synchronized (self)
	{
        [self load];
		return self.appData[kLastTrip];
	}
}

- (void)setLastTrip:(NSMutableDictionary *)dict
{
	@synchronized (self)
	{
        [self load];
		self.appData[kLastTrip] = dict;
	}
	
    self.favesChanged = YES;
	[self cacheAppData];
}


- (NSMutableDictionary *)lastLocate
{
	@synchronized (self)
	{
        [self load];
		return self.appData[kLastLocate];
	}
}

- (void)setLastLocate:(NSMutableDictionary *)dict
{
	@synchronized (self)
	{
        [self load];
		self.appData[kLastLocate] = dict;
	}
	
    self.favesChanged = YES;
	[self cacheAppData];
}



- (void)setLocationDatabaseDate:(NSString *)date
{
	@synchronized (self)
	{
        [self load];
		self.appData[kLocateDate] = date;
	
		[self cacheAppData];
	}
	
}

- (NSString*)getLocationDatabaseDateString
{
	@synchronized (self)
	{
        [self load];
		return self.appData[kLocateDate];
	}
}

- (NSTimeInterval)getLocationDatabaseAge
{
    [self load];
	NSString *dateStr =  [self getLocationDatabaseDateString];
	
	if (dateStr == nil || [dateStr isEqualToString:kUnknownDate] || [dateStr isEqualToString:kIncompleteDatabase])
	{
		return 0;
	}
	
	NSScanner *s = [NSScanner scannerWithString:dateStr];
	
	NSInteger month = 0;
	NSInteger day = 0;
	NSInteger year = 0;
	
	[s scanInteger:&month];
	s.scanLocation++;
	
	[s scanInteger:&day];
	s.scanLocation++;
	
	[s scanInteger:&year];
	
	if (year < 100)
	{
		year += 2000;
	}
	
	
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	comps.year = year;
	comps.month = month;
	comps.day = day;
	
	NSDate *databaseDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
	[comps release];
	
	NSTimeInterval age = -databaseDate.timeIntervalSinceNow;
	
	return age; 
	
}

#define IS_MORNING(hour) (hour<12)

- (NSDictionary *)checkForCommuterBookmarkShowOnlyOnce:(bool)onlyOnce
{
    [self load];
    NSDate *lastRun					 = [self.lastRun retain];
    NSDate *now						 = [NSDate date];
    
// Text code forces the commuter bookmark every 5 seconds.
   if ([UserPrefs sharedInstance].debugCommuter && [lastRun timeIntervalSinceNow] < -5)
   {
       [lastRun release];
       lastRun = nil;
   }
    
    bool readOnly = self.readOnly;
    
    self.readOnly = FALSE;
    
    if (onlyOnce)
    {
        self.lastRun = now;
    }
    
    self.readOnly = readOnly;
    bool firstRunInPeriod			 = YES;

    unsigned unitFlags				 = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay | kCFCalendarUnitHour | kCFCalendarUnitWeekday;

    NSCalendar       *cal			 = [NSCalendar currentCalendar];
    NSDateComponents *nowComponents  = [cal components:(NSUInteger)unitFlags fromDate:now];
    
    if (lastRun != nil)
    {
        NSDateComponents *lastComponents = [cal components:(NSUInteger)unitFlags fromDate:lastRun];
        
        if (
            lastComponents.year  == nowComponents.year
            &&	lastComponents.month == nowComponents.month
            &&  lastComponents.day	 == nowComponents.day
            &&  IS_MORNING(lastComponents.hour) == IS_MORNING(nowComponents.hour) )
        {
            firstRunInPeriod = NO;
        }
        [lastRun release];
    }
    
    if (!onlyOnce || firstRunInPeriod)
    {
        int todayBit = (0x1 << nowComponents.weekday);
        
        NSArray *faves = self.faves;
        for (NSDictionary * fave in faves)
        {
            NSNumber *dow = fave[kUserFavesDayOfWeek];
            NSNumber *am  = fave[kUserFavesMorning];
            if (dow && fave[kUserFavesLocation]!=nil)
            {
                // does the day of week match our day of week?
                if ((dow.intValue & todayBit) !=0)
                {
                    // Does AM match or PM match?
                    if ((   (am == nil ||  am.boolValue) &&  IS_MORNING(nowComponents.hour))
                         || (am != nil && !am.boolValue  && !IS_MORNING(nowComponents.hour)))
                    {
                        return [[fave retain] autorelease];
                    }
                }
            }
        }
        
        // Didn't find anything - set this to nil just in case the user sets one up 
        self.lastRun = nil;
    }
    return nil;
}





@end
