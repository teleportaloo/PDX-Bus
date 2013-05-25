//
//  XMLDepartures.m
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

#import "XMLDepartures.h"
#import "DepartureTimesView.h"
#import "Departure.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "trip.h"
#import "XMLDetour.h"

static NSString *departuresURLString = @"arrivals/locIDs/%@";


@implementation XMLDepartures

@synthesize distance = _distance;
@synthesize blockFilter = _blockFilter;
@synthesize queryTime = _queryTime;
@synthesize locDesc = _locDesc;
@synthesize locid = _locid;
@synthesize locLat = _locLat;
@synthesize locLng = _locLng;
@synthesize locDir = _locDir;
@synthesize currentDepartureObject = _currentDepartureObject;
@synthesize currentTrip = _currentTrip;
@synthesize streetcarPlatformMap = _streetcarPlatformMap;
@synthesize streetcarRoutes = _streetcarRoutes;
@synthesize sectionTitle = _sectionTitle;
@synthesize streetcarData = _streetcarData;
@synthesize streetcarException = _streetcarException;
@synthesize streetcarBlockMap = _streetcarBlockMap;

- (void)dealloc
{
	self.currentDepartureObject = nil;
	self.currentTrip = nil;
    
	
	self.locDesc = nil;
	self.locLat = nil;
	self.locLng = nil;
	self.locid = nil;
	self.blockFilter = nil;
	
	self.streetcarPlatformMap = nil;
	self.streetcarRoutes = nil;
    self.streetcarBlockMap = nil;
	self.distance = nil;
	self.locDir = nil;
	self.sectionTitle = nil;
    self.streetcarData = nil;
	
	[super dealloc];
}


#pragma mark Map Pin callbacks

- (NSString *)mapStopId
{
	return self.locid;
}

- (bool)showActionMenu
{
	return YES;
}

// MK Annotate
- (CLLocationCoordinate2D)coordinate
{
	CLLocationCoordinate2D pos;
	
	pos.latitude = [self.locLat doubleValue];
	pos.longitude = [self.locLng doubleValue];
	return pos;
}

- (NSString *)title
{
	return self.locDesc;
}

- (MKPinAnnotationColor) getPinColor
{
	return MKPinAnnotationColorGreen;
}


- (double)getDouble:(NSString *)str
{
	double d = 0.0;
	NSScanner *scanner = [NSScanner scannerWithString:str];	
	[scanner scanDouble:&d];
	return d;
}

- (double)getLat
{
	return [self getDouble:self.locLat];
}

- (double)getLng
{
	return [self getDouble:self.locLng];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	
}

#pragma mark Initiate parsing 

- (void)reload
{
	TriMetTimesAppDelegate *appDelegate = (TriMetTimesAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSError *error = nil;
    
	[self startParsing:[NSString stringWithFormat:departuresURLString, self.locid] parseError:&error
        cacheAction:TriMetXMLUseShortCache];
	
	self.streetcarPlatformMap = [appDelegate getStreetcarPlatforms];
    self.streetcarRoutes = [appDelegate getStreetcarRoutes];
    self.streetcarBlockMap = [appDelegate getStreetcarBlockMap];
	
	NSScanner *idScanner =  [NSScanner scannerWithString:self.locid];
	NSString *nextStop;
	NSThread *thread = [NSThread currentThread];
	
	int nStops = 0;
	while ([idScanner scanUpToString:@"," intoString:&nextStop] && ![thread isCancelled])
	{
		[self addStreetcarArrivalsForLocation:nextStop];
		nStops++;
		
		if (![idScanner isAtEnd])
		{
			idScanner.scanLocation++;
		}
	}
	
	if (nStops > 1)
	{
		self.locDesc = [ NSString stringWithFormat:@"Stop Ids:%@", self.locid];
		self.locLat = nil;
		self.locLng = nil;
	}
	
}

- (BOOL)getDeparturesForLocation:(NSString *)location parseError:(NSError **)error
{	
	self.distance = nil;
	self.locid = location;
	[self reload];
	return YES;
}

- (BOOL)getDeparturesForLocation:(NSString *)location block:(NSString*)block parseError:(NSError **)error
{	
	self.distance = nil;
	self.locid = location;
	self.blockFilter = block;
	[self reload];
	return YES;
}

#pragma mark Parser callbacks

- (void)dumpDict:(NSDictionary *)dict
{
    for (NSString *key in dict)
    {
        DEBUG_LOG(@"Key %@ value %@\n", key, [dict valueForKey:key]);
    }
    
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if ([NSThread currentThread].isCancelled)
	{
		[parser abortParsing];
		return;
	}
	
    if (qName) {
        elementName = qName;
    }
	
	if ([elementName isEqualToString:@"resultSet"]) {
		self.queryTime = [self getTimeFromAttribute:attributeDict valueForKey:@"queryTime"];	
		[self initArray];
		hasData = YES;
	}
	
	if ([elementName isEqualToString:@"location"] && self.locDesc == nil) {
		self.locDesc = [self safeValueFromDict:attributeDict valueForKey:@"desc"];	
		self.locLat  = [self safeValueFromDict:attributeDict valueForKey:@"lat"];
		self.locLng  = [self safeValueFromDict:attributeDict valueForKey:@"lng"];
		self.locDir  = [self safeValueFromDict:attributeDict valueForKey:@"dir"];
	}
	
	if ([elementName isEqualToString:@"errorMessage"]) {
		self.currentDepartureObject = [[[Departure alloc] init] autorelease];
		self.contentOfCurrentProperty = [NSMutableString string];
	}	
		
    if ([elementName isEqualToString:@"arrival"]) {
		
		NSString *block = [self safeValueFromDict:attributeDict valueForKey:@"block"];
		if ((self.blockFilter==nil) || ([self.blockFilter isEqualToString:block]))
		{
        
			self.currentDepartureObject = [[[Departure alloc] init] autorelease];
			self.currentDepartureObject.hasBlock = false;
			
            self.currentDepartureObject.cacheTime = self.cacheTime;
            
            // Adjust the query time based on the cache time
            
            NSTimeInterval i = -[self.cacheTime timeIntervalSinceNow];
            
            self.currentDepartureObject.queryTime = self.queryTime + i * 1000;
			
			self.currentDepartureObject.route =			[self safeValueFromDict:attributeDict valueForKey:@"route"];
			self.currentDepartureObject.fullSign =		[self safeValueFromDict:attributeDict valueForKey:@"fullSign"];
			self.currentDepartureObject.routeName =		[self safeValueFromDict:attributeDict valueForKey:@"shortSign"];
			self.currentDepartureObject.block =         block;
			self.currentDepartureObject.dir =			[self safeValueFromDict:attributeDict valueForKey:@"dir"];
			
			self.currentDepartureObject.locationDesc =	self.locDesc;
			self.currentDepartureObject.locid		 =  self.locid;
			self.currentDepartureObject.locationDir  =  self.locDir;
			self.currentDepartureObject.stopLat		 =  self.locLat;
			self.currentDepartureObject.stopLng		 =  self.locLng;
			
			NSString *status = [self safeValueFromDict:attributeDict valueForKey:@"status"];
			
			if ([status isEqualToString:@"estimated"])
			{
				self.currentDepartureObject.departureTime = [self getTimeFromAttribute:attributeDict valueForKey:@"estimated"];
				self.currentDepartureObject.status = kStatusEstimated;
			}
			else 
			{
				self.currentDepartureObject.departureTime = [self getTimeFromAttribute:attributeDict valueForKey:@"scheduled"];	
		
				if ([status isEqualToString:@"scheduled"])
				{
					[self.currentDepartureObject setStatus:kStatusScheduled];
				} 
				else if ([status isEqualToString:@"delayed"])
				{
					[self.currentDepartureObject setStatus:kStatusDelayed];
				} 
				else if ([status isEqualToString:@"canceled"])
				{
					[self.currentDepartureObject setStatus:kStatusCancelled];
				}
			}
			self.currentDepartureObject.scheduledTime = [self getTimeFromAttribute:attributeDict valueForKey:@"scheduled"];	
			self.currentDepartureObject.detour = [[self safeValueFromDict:attributeDict valueForKey:@"detour"] isEqualToString:@"true"];
			self.currentDepartureObject.nextBusFeedInTriMetData = [[self safeValueFromDict:attributeDict valueForKey:@"nextBusFeed"] isEqualToString:@"true"];
            DEBUG_LOG(@"Nextbusfeed:%d %@\n", self.currentDepartureObject.nextBusFeedInTriMetData, [self safeValueFromDict:attributeDict valueForKey:@"nextbusfeed"])	;
            // [self dumpDict:attributeDict];
        }
		else
		{
			self.currentDepartureObject=nil;
		}
    }
	
	if ([elementName isEqualToString:@"blockPosition"] && self.currentDepartureObject!=nil) {
		self.currentDepartureObject.blockPositionAt =  [self getTimeFromAttribute:attributeDict valueForKey:@"at"];	
		self.currentDepartureObject.blockPositionLat = [self safeValueFromDict:attributeDict valueForKey:@"lat"];
		self.currentDepartureObject.blockPositionLng = [self safeValueFromDict:attributeDict valueForKey:@"lng"];
		self.currentDepartureObject.blockPositionFeet = [self getDistanceFromAttribute:attributeDict valueForKey:@"feet"];
		self.currentDepartureObject.hasBlock = true;
	}
	
	if ([elementName isEqualToString:@"trip"] && self.currentDepartureObject!=nil)
	{
		self.currentTrip = [[[Trip alloc] init] autorelease];
		self.currentTrip.name = [self safeValueFromDict:attributeDict valueForKey:@"desc"];
		self.currentTrip.distance = [self getDistanceFromAttribute:attributeDict valueForKey:@"destDist"];
		self.currentTrip.progress  = [self getDistanceFromAttribute:attributeDict valueForKey:@"progress"];
		
		if (self.currentTrip.distance > 0)
		{
			[self.currentDepartureObject.trips addObject:self.currentTrip];
		}
	}
	
	if ([elementName isEqualToString:@"layover"] && self.currentDepartureObject!=nil)
	{
		self.currentTrip = [[[Trip alloc] init] autorelease];
		self.currentTrip.startTime = [self getTimeFromAttribute:attributeDict valueForKey:@"start"];
		self.currentTrip.endTime =   [self getTimeFromAttribute:attributeDict valueForKey:@"end"];
		[self.currentDepartureObject.trips addObject:self.currentTrip];
	}
	
	if ([elementName isEqualToString:@"location"] && self.currentDepartureObject!=nil && self.locDesc != nil)
	{
		self.currentTrip.name = [self safeValueFromDict:attributeDict valueForKey:@"desc"];	
	}
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{   
	if ([NSThread currentThread].isCancelled)
	{
		[parser abortParsing];
		return;
	}
	
    if (qName) {
        elementName = qName;
    }
		
	if ([elementName isEqualToString:@"errorMessage"] && self.currentDepartureObject!=nil) {
		self.currentDepartureObject.errorMessage = [self contentOfCurrentProperty];	
		_contentOfCurrentProperty = nil;
		
		[self addItem:self.currentDepartureObject];
		self.currentDepartureObject = nil;
	}
	
	if ([elementName isEqualToString:@"arrival"] && self.currentDepartureObject!=nil) {
		[self addItem:self.currentDepartureObject];
		self.currentDepartureObject = nil;
	}
}

#pragma mark  Cached detours 

static NSMutableDictionary *cachedDetours = nil;

+ (void)clearCache
{
	if (cachedDetours !=nil)
	{
		[cachedDetours release];
		cachedDetours = nil;
	}
}

-(bool)checkForDetour:(NSString *)route
{
	bool hasDetour = false;

	if (cachedDetours == nil)
	{
		cachedDetours = [[NSMutableDictionary alloc] init];
	}
	
	XMLDetour *detour = [cachedDetours objectForKey:route];
	
	if (detour == nil)
	{
		detour = [[XMLDetour alloc] init];
		NSError *parseError = nil;
		[detour getDetourForRoute:route parseError:&parseError];
		[cachedDetours setObject:detour forKey:route];
		[detour release];
	}
	
	hasDetour = ([detour safeItemCount] > 0);
	return hasDetour;
}

#pragma mark Streetcar data 

- (void)mergeStreetcarArrivals:(NSString *)platform departures:(XMLStreetcarPredictions*)streetcars
{
	bool detour = NO;
    NSString *triMetRoute = nil;
    
    DEBUG_LOG(@"###############################################\n");
    DEBUG_LOG(@"ID       :%@\n", self.locid);
    DEBUG_LOG(@"Streetcar:%@\n", streetcars.stopTitle);
    DEBUG_LOG(@"TriMet   :%@\n", self.locDesc);
    
    if (streetcars.nextBusRouteId!=nil && self.streetcarRoutes!=nil)
    {
        triMetRoute = [self.streetcarRoutes objectForKey:streetcars.nextBusRouteId];
        
        if (triMetRoute)
        {
              detour = [self checkForDetour:triMetRoute];
        }
    }
	
	int i;
	for (i=0; i < [streetcars safeItemCount]; i++)
	{
        Departure *dep = [streetcars itemAtIndex:i];
        
		self.currentDepartureObject = dep;
		
		// self.currentDepartureObject.fullSign = routeName;
		// self.currentDepartureObject.routeName = routeName;
		self.currentDepartureObject.departureTime = self.currentDepartureObject.nextBus * 60 * 1000 + self.queryTime;
		// self.currentDepartureObject.status = kStatusEstimated;
		self.currentDepartureObject.detour = detour;
		self.currentDepartureObject.queryTime = self.queryTime;
		// self.currentDepartureObject.hasBlock = false;
		self.currentDepartureObject.route = triMetRoute;
		self.currentDepartureObject.locid = self.locid;
		self.currentDepartureObject.locationDesc = self.locDesc;
		self.currentDepartureObject.stopLat = self.locLat;
		self.currentDepartureObject.stopLng = self.locLng;
			

		int i;
		Departure *item;
        
        // Look for any blocks that appear as scheduled that matches this one and merge
        // As the TriMet data can contain scheduled times for the same block.
        NSString *blockFormat = [self.streetcarBlockMap objectForKey:streetcars.nextBusRouteId];
        
        if (blockFormat !=nil && triMetRoute !=nil)
        {
            NSString *triMetBlock;
            
            if (dep.streecarBlock.length < 4)
            {
                triMetBlock = [NSString stringWithFormat:blockFormat, dep.streecarBlock];
            }
            else
            {
                triMetBlock = dep.streecarBlock;
            }
            
            for (i=0; i< [self.itemArray count];)
            {
                item = [self.itemArray objectAtIndex:i];
                
                
                if (item.block && [item.block isEqualToString:triMetBlock] && item.status == kStatusScheduled && [item.route isEqualToString:triMetRoute])
                {
                    if (dep.scheduledTime == 0)
                    {
                        dep.scheduledTime = item.scheduledTime;
                    }
                    [self.itemArray removeObjectAtIndex:i];
                    
                }
                else if (item.block && [item.block isEqualToString:triMetBlock] && [item.route isEqualToString:triMetRoute])
                {
                    [self.itemArray removeObjectAtIndex:i];
                }
                else if (item.nextBusFeedInTriMetData)
                {
                     [self.itemArray removeObjectAtIndex:i];
                }
                else
                {
                    i++;
                }
            }
        }
        
		
		for (i=0; i< [self.itemArray count] && self.currentDepartureObject!=nil; i++)
		{
			item = [self.itemArray objectAtIndex:i];
			
			if ( [self.currentDepartureObject secondsToArrival] < [item secondsToArrival])
			{
				[self.itemArray insertObject:self.currentDepartureObject atIndex:i];
				self.currentDepartureObject = nil;
			}
		}
        
		
		if ( self.currentDepartureObject != nil)
		{
			[self.itemArray addObject:self.currentDepartureObject];
			self.currentDepartureObject = nil;
		}
	}
    
    // Remove orphaned scheduled times
    /*
    for (i=0; i< [self.itemArray count] && triMetRoute!=nil;)
    {
		Departure *item;
        
        item = [self.itemArray objectAtIndex:i];
        
        if (item.status == kStatusScheduled && [item.route isEqualToString:triMetRoute])
        {
            [self.itemArray removeObjectAtIndex:i];
        }
        else
        {
            i++;
        }
    }
    */
}

- (void)addStreetcarArrivalsForLocation:(NSString *)location
{
    NSString *route = nil;
    self.streetcarData = [[[NSMutableData alloc] init] autorelease];
    
    for (route in self.streetcarPlatformMap)
    {
        NSDictionary *platforms = [self.streetcarPlatformMap objectForKey:route];
        
        NSObject *streetcarPlatformObj = [platforms objectForKey:location];
        
        if (streetcarPlatformObj != nil)
        {
            NSArray *streetcarItems = nil;
            
            if (streetcarPlatformObj !=nil && [streetcarPlatformObj isKindOfClass:[NSArray class]])
            {
                streetcarItems = (NSArray*)streetcarPlatformObj;
            }
            else if (streetcarPlatformObj !=nil && [streetcarPlatformObj isKindOfClass:[NSString class]])
            {
                streetcarItems = [NSArray arrayWithObject:streetcarPlatformObj];
            }
            
            for (NSString *streetcarPlatform in streetcarItems)
            {
                DEBUG_LOG(@"Streetcar query: %@\n", streetcarPlatform);
                XMLStreetcarPredictions *streetcar = [[XMLStreetcarPredictions alloc] init];
            
                streetcar.blockFilter = self.blockFilter;
                streetcar.nextBusRouteId = route;
            
                NSError *error = nil;
            
                [streetcar getDeparturesForLocation:[NSString stringWithFormat:@"predictions&a=portland-sc&r=%@&%@", route, streetcarPlatform]
                                         parseError:&error];
            
                if ([streetcar gotData])
                {
                    [self mergeStreetcarArrivals:streetcarPlatform departures:streetcar];
                }
                
                // Temporary street car warning
                if ([route isEqualToString:@"cl"])
                {
                    self.streetcarException = YES;
                }
            
                if ([UserPrefs getSingleton].debugXML)
                {
                    [streetcar appendQueryAndData:self.streetcarData];
                }
                [streetcar release];
            }
        }
    }
    
	
	/*
    NSString *exception = [self.streetcarExceptions objectForKey:location];
    
    if (exception!=nil)
    {
        self.streetcarException = YES;
    }
     */
}

#pragma mark Data accessors

- (id)DTDataXML
{
	return self;
}

- (Departure *)DTDataGetDeparture:(int)i
{
	return [self itemAtIndex:i];
}
- (int)DTDataGetSafeItemCount
{
	return [self safeItemCount];
}
- (NSString *)DTDataGetSectionHeader
{
	return self.locDesc;
}
- (NSString *)DTDataGetSectionTitle
{
	return self.sectionTitle;
}

- (void)DTDataPopulateCell:(Departure *)dd cell:(UITableViewCell *)cell decorate:(BOOL)decorate big:(BOOL)big wide:(BOOL)wide
{
	[dd populateCell:cell decorate:decorate big:big busName:YES wide:wide];
}
- (NSString *)DTDataStaticText
{
	return [NSString stringWithFormat:@"(ID %@) %@.", 
			self.locid,
			self.locDir];
}

- (StopDistance*)DTDataDistance
{
	return self.distance;
}

- (TriMetTime) DTDataQueryTime
{
	return self.queryTime;
}

- (NSString *)DTDataLocLat
{
	return self.locLat;
}
- (NSString *)DTDataLocLng
{
	return self.locLng;
}
- (NSString *)DTDataLocDesc
{
	return self.locDesc;
}

- (id<MapPinColor>)DTDatagetPin
{
	return self;
}

- (NSString *)DTDataLocID
{
	return self.locid;
}

- (BOOL) DTDataHasDetails
{
	return TRUE;
}

- (BOOL) DTDataNetworkError
{
	return !hasData;
}

- (NSString *) DTDataNetworkErrorMsg
{
	return self.errorMsg;
}

- (NSString *) DTDataDir
{
	return self.locDir;
}


- (BOOL) DTDataStreetcarException
{
    return self.streetcarException;
}

- (NSData *) DTDataHtmlError
{
	return self.htmlError;
}


@end
