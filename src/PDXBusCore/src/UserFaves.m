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

- (void)dealloc
{
    self.appData = nil;
    self.sharedUserCopyOfPlist = nil;
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
    NSMutableArray *recentTrips = [self.appData objectForKey:kRecentTrips];
    
    if (recentTrips == nil)
    {
        recentTrips = [[[NSMutableArray alloc] init] autorelease];
        
        [self.appData setObject:recentTrips forKey:kRecentTrips];
        [self cacheAppData];
    }
    
    return recentTrips;
}

- (void)load
{
    if (self.appData == nil)
    {
        self.appData = [[[NSMutableDictionary alloc] initWithContentsOfURL:self.sharedUserCopyOfPlist.urlToSharedFile] autorelease];
        
        [self getOrInitRecentTrips];
        
    }
}

- (id)init {
	if ((self = [super init]))
	{
        self.sharedUserCopyOfPlist = [[[SharedFile alloc] initWithFileName:@"appData.plist" initFromBundle:YES] autorelease];
        self.readOnly = FALSE;
        [self load];
	}
	return self;
}

+ (SafeUserData *)getSingleton
{
	static SafeUserData *singleton = nil;
	
	if (singleton == nil)
	{
		singleton = [[SafeUserData alloc] init];
        [MemoryCaches addCache:singleton];
	}
	return [[singleton retain] autorelease];
}

- (void)cacheAppData
{
	@synchronized (self)
	{
        if (self.appData && ! self.readOnly)
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
		[self.appData setObject:@"" forKey:kLast];	
		[self.appData removeObjectForKey:kLastNames];
	}
}

- (void)setLastArrivals:(NSString *)locations
{
	@synchronized (self)
	{
        [self load];
		[self.appData setObject:locations forKey:kLast];
	
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
			[self.appData setObject:names forKey:kLastNames];
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
		NSMutableDictionary *takeMeHome   = [self.appData objectForKey:kTakeMeHome];
		
		return takeMeHome;
	}
}

- (void)saveTakeMeHomeUserRequest:(NSDictionary *)userRequest
{
    @synchronized (self)
	{
        [self load];
        [self.appData setObject:userRequest forKey:kTakeMeHome];
        
        [self cacheAppData];
    }
}

- (void)addToRecentTripsWithUserRequest:(NSDictionary*)userRequest description:(NSString *)desc blob:(NSData *)blob
{
	@synchronized (self)
	{
        [self load];
        
        NSMutableArray *recentTrips   =  [self getOrInitRecentTrips];
		NSMutableDictionary *newItem = [[NSMutableDictionary alloc] init];
		
		[newItem setObject:userRequest forKey:kUserFavesTrip];
		[newItem setObject:blob forKey:kUserFavesTripResults];
		[newItem setObject:desc forKey:kUserFavesChosenName];
		
		[recentTrips insertObject:newItem atIndex:0];
		
		[newItem release];
		
		
		int maxRecents = [UserPrefs getSingleton].maxRecentTrips;
		
		while (recentTrips.count > maxRecents)
		{
			[recentTrips removeObjectAtIndex:(recentTrips.count-1)];
		}
		
		_favesChanged = true;
		[self cacheAppData];
	}
}

- (void)addToRecentsWithLocation:(NSString *)locid description:(NSString *)desc
{
	@synchronized (self)
	{
        [self load];
        
		// NSMutableArray *userFaves = [self.favesAndRecents objectForKey:kFaves];
		NSMutableArray *recents   = [self.appData objectForKey:kRecents];
		
		
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
		
		
		for (j = 0; j < [recents count] ; j++)
		{
			if ([[[recents objectAtIndex:j] objectForKey:kUserFavesLocation] isEqualToString:locid])
			{
				[recents removeObjectAtIndex:j];
				j--;
			}	
		}
		
		NSMutableDictionary *newItem = [[NSMutableDictionary alloc] init];
		
		[newItem setObject:locid forKey:kUserFavesLocation];
		[newItem setObject:desc forKey:kUserFavesOriginalName];
		[newItem setObject:desc forKey:kUserFavesChosenName];
		
		
		[recents insertObject:newItem atIndex:0];
		[newItem release];
		
		int maxRecents = [UserPrefs getSingleton].maxRecentStops;
		
		while (recents.count > maxRecents)
		{
			[recents removeObjectAtIndex:(recents.count-1)];
		}
		
		_favesChanged = true;
        [self cacheAppData];
	}
}

- (NSMutableArray *)faves
{
	@synchronized (self)
	{
        [self load];
		return [self.appData objectForKey:kFaves];
	}
}

- (NSArray*)favesArrivalsOnly
{
    @synchronized (self)
    {
        [self load];
        
        NSMutableArray *favesArrivalsOnly = [[[NSMutableArray alloc] init] autorelease];
        NSMutableArray *faves = self.faves;
        
        NSDictionary *item;
        
        
        for (item in faves)
        {
            if ([item valueForKey:kUserFavesTrip] == nil)
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
		return [self.appData objectForKey:kRecents];
	}
}

- (NSMutableArray *)recentTrips
{
	@synchronized (self)
	{
        [self load];
		return [self.appData objectForKey:kRecentTrips];
	}
}

- (NSString *)last
{
	@synchronized (self)
	{
        [self load];
		return [self.appData objectForKey:kLast];
	}
}

- (NSArray *)lastNames
{
	@synchronized (self)
	{
        [self load];
		return [self.appData objectForKey:kLastNames];
	}
}

- (void)setLastRun:(NSDate *)last
{
	@synchronized (self)
	{
        [self load];
		if (last!=nil)
		{
			[self.appData setObject:last forKey:kLastRun];
		}
		else
		{
			[self.appData removeObjectForKey:kLastRun];
		}
	}
	[self cacheAppData];
}

- (NSDate *)lastRun
{
	@synchronized (self)
	{
        [self load];
		return [self.appData objectForKey:kLastRun];
	}	
}

- (NSMutableDictionary *)lastTrip
{
	@synchronized (self)
	{
        [self load];
		return [self.appData objectForKey:kLastTrip];
	}
}

- (void)setLastTrip:(NSMutableDictionary *)dict
{
	@synchronized (self)
	{
        [self load];
		[self.appData setObject:dict forKey:kLastTrip];
	}
	
	[self favesChanged];
	[self cacheAppData];
}


- (NSMutableDictionary *)lastLocate
{
	@synchronized (self)
	{
        [self load];
		return [self.appData objectForKey:kLastLocate];
	}
}

- (void)setLastLocate:(NSMutableDictionary *)dict
{
	@synchronized (self)
	{
        [self load];
		[self.appData setObject:dict forKey:kLastLocate];
	}
	
	[self favesChanged];
	[self cacheAppData];
}



- (void)setLocationDatabaseDate:(NSString *)date
{
	@synchronized (self)
	{
        [self load];
		[self.appData setObject:date  forKey:@"LocationDatabaseDate"]; 
	
		[self cacheAppData];
	}
	
}

- (NSString*)getLocationDatabaseDateString
{
	@synchronized (self)
	{
        [self load];
		return [self.appData objectForKey:@"LocationDatabaseDate"];
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
	[comps setYear:year];
	[comps setMonth:month];
	[comps setDay:day];
	
	NSDate *databaseDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
	[comps release];
	
	NSTimeInterval age = -[databaseDate timeIntervalSinceNow];
	
	return age; 
	
}


- (NSArray *)arrayFromCommaSeparatedString:(NSString *)string
{
    NSMutableArray *result = [[[NSMutableArray alloc] init] autorelease];
    
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    NSCharacterSet *comma = [NSCharacterSet characterSetWithCharactersInString:@","];
    NSString *item = nil;
    
    while ([scanner scanUpToCharactersFromSet:comma intoString:&item])
    {
        [result addObject:item];
        
        if (![scanner isAtEnd])
        {
            scanner.scanLocation++;
        }
    }
    
    return result;
}






@end
