//
//  XMLDepartures.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLDepartures.h"
#import "DepartureData.h"
#import "DepartureTrip.h"
#import "XMLDetours.h"
#import "DebugLogging.h"
#import "DepartureData.h"
#import "StringHelper.h"

static NSString *departuresURLString = @"arrivals/locIDs/%@/streetcar/true";


@implementation XMLDepartures

@synthesize distance = _distance;
@synthesize blockFilter = _blockFilter;
@synthesize queryTime = _queryTime;
@synthesize locDesc = _locDesc;
@synthesize locid = _locid;
@synthesize loc = _loc;
@synthesize locDir = _locDir;
@synthesize currentDepartureObject = _currentDepartureObject;
@synthesize currentTrip = _currentTrip;
@synthesize sectionTitle = _sectionTitle;
@synthesize streetcarData = _streetcarData;
@synthesize firstOnly = _firstOnly;

- (void)dealloc
{
	self.currentDepartureObject = nil;
	self.currentTrip = nil;
    
	
	self.locDesc = nil;
	self.loc = nil;
	self.locid = nil;
	self.blockFilter = nil;
	
	self.distance = nil;
	self.locDir = nil;
	self.sectionTitle = nil;
    self.streetcarData = nil;
	
	[super dealloc];
}


- (double)getDouble:(NSString *)str
{
	double d = 0.0;
	NSScanner *scanner = [NSScanner scannerWithString:str];	
	[scanner scanDouble:&d];
	return d;
}


- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	
}

- (DepartureData*)departureForBlock:(NSString *)block
{
    for (DepartureData *dep in self) {
        if ([dep.block isEqualToString:block])
        {
            return dep;
        }
    }
    return nil;
}

#pragma mark Initiate parsing

- (void)reload
{
	[self startParsing:[NSString stringWithFormat:departuresURLString, self.locid]
        cacheAction:TriMetXMLUseShortTermCache];
		
    NSMutableArray *locs = self.locid.arrayFromCommaSeparatedString;
	
    int nStops = (int)locs.count;
	
	if (nStops > 1)
	{
		self.locDesc = [ NSString stringWithFormat:@"Stop Ids:%@", self.locid];
		self.loc = nil;
	}
    
    NSArray *sorted = [self.itemArray sortedArrayUsingSelector:@selector(compareUsingTime:)];
    
    [self.itemArray removeAllObjects];
    [self.itemArray addObjectsFromArray:sorted];
	
}

- (BOOL)getDeparturesForLocation:(NSString *)location
{	
	self.distance = nil;
	self.locid = location;
	[self reload];
	return YES;
}

- (BOOL)getDeparturesForLocation:(NSString *)location block:(NSString*)block
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
#ifdef DEBUGLOGGING
    for (NSString *key in dict)
    {
        DEBUG_LOG(@"Key %@ value %@\n", key, dict[key]);
    }
#endif
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if ([NSThread currentThread].isCancelled)
	{
		[parser abortParsing];
		return;
	}
    
    [super parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
	
    if (qName) {
        elementName = qName;
    }
	
	if (ELTYPE(resultSet)) {
		self.queryTime = ATRTIM(queryTime);
		[self initArray];
		_hasData = YES;
	}
	
	if (ELTYPE(location) && self.locDesc == nil) {
		self.locDesc = ATRVAL(desc);
        
        NSString *lat = ATRVAL(lat);
        NSString *lng = ATRVAL(lng);
        
        if (lat!=nil && lng!=nil)
        {
            self.loc = [[[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lng.doubleValue] autorelease];
        }
		self.locDir  = ATRVAL(dir);
	}
	
	if (ELTYPE(errorMessage)) {
        self.currentDepartureObject   = [DepartureData data];
		self.contentOfCurrentProperty = [NSMutableString string];
	}	
		
    if (ELTYPE(arrival)) {
		
		NSString *block = ATRVAL(block);
		if (((self.blockFilter==nil) || ([self.blockFilter isEqualToString:block])) &&
                ((!self.firstOnly || self.count < 1)))
		{
        
            self.currentDepartureObject = [DepartureData data];
            
            // Streetcar arrivals have an implicit block
            self.currentDepartureObject.hasBlock = ATRBOOL(streetCar);
			
            self.currentDepartureObject.cacheTime = self.cacheTime;
            
            // Adjust the query time based on the cache time
            
           
            
            self.currentDepartureObject.queryTime = self.queryTime;
            
            
			
			self.currentDepartureObject.route =			ATRVAL(route);
			self.currentDepartureObject.fullSign =		ATRVAL(fullSign);
			self.currentDepartureObject.routeName =		ATRVAL(shortSign);
			self.currentDepartureObject.block =         block;
			self.currentDepartureObject.dir =			ATRVAL(dir);
			
			self.currentDepartureObject.locationDesc =	self.locDesc;
			self.currentDepartureObject.locid		 =  self.locid;
			self.currentDepartureObject.locationDir  =  self.locDir;
			self.currentDepartureObject.stopLocation =  self.loc;
			
			NSString *status = ATRVAL(status);
			
			if (ATREQ(status, @"estimated"))
			{
				self.currentDepartureObject.departureTime = ATRTIM(estimated);
				self.currentDepartureObject.status = kStatusEstimated;
			}
			else 
			{
				self.currentDepartureObject.departureTime = ATRTIM(scheduled);
		
				if (ATREQ(status,@"scheduled"))
				{
					self.currentDepartureObject.status = kStatusScheduled;
				} 
				else if (ATREQ(status, @"delayed"))
				{
					self.currentDepartureObject.status = kStatusDelayed;
				} 
				else if (ATREQ(status, @"canceled"))
				{
					self.currentDepartureObject.status = kStatusCancelled;
				}
			}
            
            [self.currentDepartureObject extrapolateFromNow];
            
			self.currentDepartureObject.scheduledTime           = ATRTIM(scheduled);
            self.currentDepartureObject.detour                  = ATRBOOL(detour);
            self.currentDepartureObject.nextBusFeedInTriMetData = ATRBOOL(nextBusFeed);
            self.currentDepartureObject.streetcar               = ATRBOOL(streetCar);
            
            
            // DEBUG_LOG(@"Nextbusfeed:%d %@\n", self.currentDepartureObject.nextBusFeedInTriMetData, ATRVAL(nextbusfeed)	;
            // [self dumpDict:attributeDict];
        }
		else
		{
			self.currentDepartureObject=nil;
		}
    }
	
	if (ELTYPE(blockPosition) && self.currentDepartureObject!=nil) {
		self.currentDepartureObject.blockPositionAt = ATRTIM(at);

        NSString *lat = ATRVAL(lat);
        NSString *lng = ATRVAL(lng);
        
        if (lat !=nil && lng!=nil)
        {
            self.currentDepartureObject.blockPosition = [[[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lng.doubleValue] autorelease];
        }
        
		self.currentDepartureObject.blockPositionFeet   = ATRDIST(feet);
        self.currentDepartureObject.blockPositionHeading= ATRVAL(heading);
        
		self.currentDepartureObject.hasBlock = true;
	}
	
	if (ELTYPE(trip) && self.currentDepartureObject!=nil)
	{
		self.currentTrip = [[[DepartureTrip alloc] init] autorelease];
		self.currentTrip.name     = ATRVAL(desc);
		self.currentTrip.distance = (unsigned long)ATRDIST(destDist);
		self.currentTrip.progress = (unsigned long)ATRDIST(progress);
		
		if (self.currentTrip.distance > 0)
		{
			[self.currentDepartureObject.trips addObject:self.currentTrip];
		}
	}
	
	if (ELTYPE(layover) && self.currentDepartureObject!=nil)
	{
		self.currentTrip = [[[DepartureTrip alloc] init] autorelease];
		self.currentTrip.startTime = ATRTIM(start);
		self.currentTrip.endTime   = ATRTIM(end);
		[self.currentDepartureObject.trips addObject:self.currentTrip];
	}
	
	if (ELTYPE(location) && self.currentDepartureObject!=nil && self.locDesc != nil)
	{
		self.currentTrip.name = ATRVAL(desc);
	}
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{   
	if ([NSThread currentThread].isCancelled)
	{
		[parser abortParsing];
		return;
	}
    
    [super parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
	
    if (qName) {
        elementName = qName;
    }
		
	if (ELTYPE(errorMessage) && self.currentDepartureObject!=nil) {
		self.currentDepartureObject.errorMessage = self.contentOfCurrentProperty;	
		_contentOfCurrentProperty = nil;
		
		[self addItem:self.currentDepartureObject];
		self.currentDepartureObject = nil;
	}
	
	if (ELTYPE(arrival) && self.currentDepartureObject!=nil) {
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
	
	XMLDetours *detours = cachedDetours[route];
	
	if (detours == nil)
	{
		detours = [[XMLDetours alloc] init];
		[detours getDetoursForRoute:route];
		cachedDetours[route] = detours;
		[detours release];
	}
	
	hasDetour = (detours.count > 0);
	return hasDetour;
}




@end
