//
//  XMLTrips.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/27/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLTrips.h"
#import "ScreenConstants.h"
#import "UserFaves.h"
#import "DebugLogging.h"
#import "TriMetRouteColors.h"
#import "RouteColorBlobView.h"
#import "TripUserRequest.h"
#import "TripEndPoint.h"


@implementation XMLTrips


@synthesize userRequest     = _userRequest;
@synthesize currentItinerary= _currentItinerary;
@synthesize currentLeg		= _currentLeg;
//@synthesize itineraries	= _itineraries;
@synthesize currentObject   = _currentObject;
@synthesize currentTagData  = _currentTagData;
@synthesize toList			= _toList;
@synthesize fromList		= _fromList;
@synthesize currentList     = _currentList;
@synthesize xdate			= _xdate;
@synthesize xtime			= _xtime;
@synthesize resultFrom		= _resultFrom;
@synthesize resultTo		= _resultTo;
@synthesize userFaves       = _userFaves;
@synthesize reversed        = _reversed;

static NSString *tripURLString = @"trips/tripplanner?%@&%@&Date=%@&Time=%@&Arr=%@&Walk=%f&Mode=%@&Min=%@&Format=XML&MaxItineraries=%d&";

- (void)dealloc {
	self.userRequest		= nil;
	self.currentItinerary	= nil;
	self.currentLeg			= nil;
	self.currentObject		= nil;
	self.currentTagData		= nil;
	self.toList				= nil;
	self.fromList			= nil;
	self.currentList		= nil;
	self.xdate				= nil;
	self.xtime				= nil;
	self.resultFrom			= nil;
	self.resultTo			= nil;
	self.userFaves			= nil;
	[super dealloc];
}

- (XMLTrips *) createReverse
{
	XMLTrips *reverse = [[[XMLTrips alloc] init] autorelease];
	
	reverse.userRequest.fromPoint = [[[TripEndPoint alloc] init] autorelease];
	reverse.userRequest.toPoint = [[[TripEndPoint alloc] init] autorelease];
	
	
	reverse.userRequest.fromPoint.locationDesc			= self.userRequest.toPoint.locationDesc;
	reverse.userRequest.fromPoint.coordinates           = self.userRequest.toPoint.coordinates;
	reverse.userRequest.fromPoint.useCurrentLocation	= self.userRequest.toPoint.useCurrentLocation;
	
	reverse.userRequest.toPoint.locationDesc			= self.userRequest.fromPoint.locationDesc;
	reverse.userRequest.toPoint.coordinates             = self.userRequest.fromPoint.coordinates;
	reverse.userRequest.toPoint.useCurrentLocation		= self.userRequest.fromPoint.useCurrentLocation;
	
	
	reverse.userRequest.dateAndTime			= self.userRequest.dateAndTime;
	reverse.userRequest.arrivalTime			= self.userRequest.arrivalTime;
	reverse.userRequest.tripMode			= self.userRequest.tripMode;
	reverse.userRequest.tripMin				= self.userRequest.tripMin;
	reverse.userRequest.maxItineraries		= self.userRequest.maxItineraries;
	reverse.userRequest.walk				= self.userRequest.walk;
	reverse.userFaves						= self.userFaves;
	reverse.reversed						= !self.reversed;
	reverse.userRequest.timeChoice          = TripAskForTime;
	
	return reverse;
}


- (XMLTrips *) createAuto
{
	XMLTrips *copy = [[[XMLTrips alloc] init] autorelease];
	
	copy.userRequest.fromPoint = [[[TripEndPoint alloc] init] autorelease];
	copy.userRequest.toPoint = [[[TripEndPoint alloc] init] autorelease];
	
	
	copy.userRequest.fromPoint.locationDesc			= self.userRequest.fromPoint.locationDesc;
	copy.userRequest.fromPoint.coordinates          = self.userRequest.fromPoint.coordinates;
	copy.userRequest.fromPoint.useCurrentLocation	= self.userRequest.fromPoint.useCurrentLocation;
	
	copy.userRequest.toPoint.locationDesc			= self.userRequest.toPoint.locationDesc;
	copy.userRequest.toPoint.coordinates            = self.userRequest.toPoint.coordinates;
	copy.userRequest.toPoint.useCurrentLocation		= self.userRequest.toPoint.useCurrentLocation;
	
	
	copy.userRequest.dateAndTime			= [[self.userRequest.dateAndTime copyWithZone:NSDefaultMallocZone()] autorelease];
	copy.userRequest.arrivalTime			= self.userRequest.arrivalTime;
	copy.userRequest.tripMode				= self.userRequest.tripMode;
	copy.userRequest.tripMin				= self.userRequest.tripMin;
	copy.userRequest.maxItineraries			= self.userRequest.maxItineraries;
	copy.userRequest.walk					= self.userRequest.walk;
	copy.userRequest.timeChoice				= self.userRequest.timeChoice;
	copy.userFaves							= self.userFaves;
	copy.reversed							= false;
	copy.userRequest.timeChoice				= TripAskForTime;
	
	return copy;
}

- (bool)isProp:(NSString *)elementName
{
	return ([elementName isEqualToString:@"date"]
			|| [elementName isEqualToString:@"time"]
			|| [elementName isEqualToString:@"message"]
			|| [elementName isEqualToString:@"startTime"]
			|| [elementName isEqualToString:@"endTime"]
			|| [elementName isEqualToString:@"duration"]
			|| [elementName isEqualToString:@"distance"] 
			|| [elementName isEqualToString:@"numberOfTransfers"] 
			|| [elementName isEqualToString:@"numberOfTripLegs"] 
			|| [elementName isEqualToString:@"walkingTime"]
			|| [elementName isEqualToString:@"transitTime"]
			|| [elementName isEqualToString:@"waitingTime"]	
			|| [elementName isEqualToString:@"number"]
			|| [elementName isEqualToString:@"internalNumber"]
			|| [elementName isEqualToString:@"name"]
			|| [elementName isEqualToString:@"direction"]
			|| [elementName isEqualToString:@"block"]
			|| [elementName isEqualToString:@"lat"]
			|| [elementName isEqualToString:@"lon"]
			|| [elementName isEqualToString:@"stopId"]
			|| [elementName isEqualToString:@"description"]
			);
}






#pragma mark Initiate parsing

- (void)addGeocodedDescriptionToLeg:(TripLeg *)leg
{
    // Add in reverse geocoded name
    if (leg && self.resultFrom  && self.userRequest.fromPoint.locationDesc && [leg.from.xdescription isEqualToString:kAcquiredLocation])
    {
        leg.from.xdescription = self.userRequest.fromPoint.locationDesc;
    }
    
    // Add in reverse geocoded name
    if (self.resultTo && self.userRequest.toPoint.locationDesc && [leg.to.xdescription isEqualToString:kAcquiredLocation])
    {
        leg.to.xdescription = self.userRequest.toPoint.locationDesc;
    }
}

- (void)fetchItineraries:(NSMutableData*)oldRawData
{
	
	NSError *parseError = nil;
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"MM-dd-yy"];
	NSDateFormatter *timeFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[timeFormatter setDateFormat:@"hh:mm'%20'aa"];
	
	// Trip planner takes a long time so never time out!
	self.giveUp = 0.0;
	
	// NSString *temp = [dateFormatter stringFromDate:self.dateAndTime];


	if (self.userRequest.dateAndTime == nil)
	{
		self.userRequest.dateAndTime = [NSDate date];
	}
		
	NSString * finalTripURLString = [NSString stringWithFormat: tripURLString,
									 [self.userRequest.fromPoint toQuery:@"from"], 
									 [self.userRequest.toPoint toQuery:@"to"], 
									 [dateFormatter stringFromDate:self.userRequest.dateAndTime],
									 [timeFormatter stringFromDate:self.userRequest.dateAndTime],
									 (self.userRequest.arrivalTime ? @"A" : @"D"),
									 self.userRequest.walk,
									 [self.userRequest modeToString],
									 [self.userRequest minToString],
									 self.userRequest.maxItineraries];
									 
	// self.itineraries = nil;
	self.currentLeg = nil;
	self.currentItinerary = nil;
	self.currentObject = nil;
	self.currentList = nil;
	self.toList = nil;
	self.fromList = nil;
	self.resultTo = nil;
	self.resultFrom = nil;
	
	if (oldRawData == nil)
	{
		[self startParsing:finalTripURLString parseError:&parseError];
	}
	else {
		self.rawData = oldRawData;
		
		[self parseRawData:&parseError];
	}

	
	int i;
	int l;
	TripItinerary *it;
	TripLeg		  *leg;
	
		
	for (i=0; i< [self safeItemCount]; i++)
	{
		it = [self itemAtIndex:i];
		it.displayEndPoints = [[[NSMutableArray alloc] init] autorelease];
        
        leg = [it.legs firstObject];
        
        [self addGeocodedDescriptionToLeg:leg];
        
		[it startPointText:TripTextTypeUI];
		
		if (it.startPoint !=nil && it.startPoint.displayText != nil)
		{
			[it.displayEndPoints addObject:it.startPoint];
		}
		
		if (it.legs != nil)
		{
			for (l = 0; l < it.legs.count; l++)
			{
				leg = [it.legs objectAtIndex:l];
                
                [self addGeocodedDescriptionToLeg:leg];
                    

				[leg createFromText:(l==0) textType:TripTextTypeUI];
				leg.to.xnumber = leg.xinternalNumber;
                
				[leg createToText:  (l==it.legs.count-1) textType:TripTextTypeUI];
				leg.from.xnumber = leg.xinternalNumber;
				
				if (leg.from && leg.from.displayText !=nil)
				{
					[it.displayEndPoints addObject:leg.from];
				}
				
				if (leg.to && leg.to.displayText != nil)
				{
					[it.displayEndPoints addObject:leg.to];
				}
			}
		}
	}
    
    // Fix up the reverse geocoded names
    if (self.resultFrom)
    {
        if (self.userRequest.fromPoint.coordinates!=nil)
        {
            self.resultFrom.xdescription = self.userRequest.fromPoint.locationDesc;
        }
    }
    
    if (self.resultTo)
    {
        if (self.userRequest.toPoint.coordinates!=nil)
        {
            self.resultTo.xdescription = self.userRequest.toPoint.locationDesc;
        }
    }
	
	if ([self safeItemCount] ==0 || !hasData)
	{
		[self initArray];
		
		TripItinerary *it = [[[TripItinerary alloc] init] autorelease];
		
		it.xmessage = @"Network error, touch here to check network.";
		
		[self addItem:it];
		
	}
}

#pragma mark Parser callbacks

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    [super parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
    
    if (qName) {
        elementName = qName;
    }
	
	if ([elementName isEqualToString:@"request"])
	{
		self.currentObject = nil;
	}
	
	if ([elementName isEqualToString:@"response"]) {
		[self initArray]; 
		hasData = YES;
		self.currentObject = self;
	}
	else if ([elementName isEqualToString:@"itinerary"]
		|| [elementName isEqualToString:@"error"]) {
		self.currentItinerary =  [[[TripItinerary alloc] init] autorelease];
		self.currentLeg = nil;
		[self addItem:self.currentItinerary];
		self.currentObject = self.currentItinerary;
	}
	else if ([elementName isEqualToString:@"leg"])
	{
		self.currentLeg = [[[TripLeg alloc] init] autorelease];
		[self.currentItinerary.legs addObject:self.currentLeg];
		self.currentObject = self.currentLeg;
		self.currentLeg.mode = [self safeValueFromDict:attributeDict valueForKey:@"mode"];
	} 
	else if ([elementName isEqualToString:@"from"] && self.currentLeg !=nil)
	{
		self.currentLeg.from = [[[TripLegEndPoint alloc] init] autorelease];
		self.currentObject = self.currentLeg.from;
	}
	else if ([elementName isEqualToString:@"to"] && self.currentLeg !=nil)
	{
		self.currentLeg.to = [[[TripLegEndPoint alloc] init] autorelease];
		self.currentObject = self.currentLeg.to;
	}
	else if ([elementName isEqualToString:@"from"] && self.resultFrom == nil)
	{
		self.resultFrom = [[[TripLegEndPoint alloc] init] autorelease];
		self.currentObject = self.resultFrom;
	}
	else if ([elementName isEqualToString:@"to"] && self.resultTo == nil)
	{
		self.resultTo = [[[TripLegEndPoint alloc] init] autorelease];
		self.currentObject = self.resultTo;
	}
	else if ([elementName isEqualToString:@"special"])
	{
		NSString *tag = [self safeValueFromDict:attributeDict valueForKey:@"id"];
		if ([tag isEqualToString:@"honored"])
		{
			self.currentTagData = @"Honored Citizen: $%@\n";
		}
		else if ([tag isEqualToString:@"youth"])
		{
			self.currentTagData = @"Youth/Student: $%@\n";
		}
		else 
		{
			self.currentTagData = [NSString stringWithFormat:@"%@ ($%@)", tag, @"%@"];
		}
	}
	else if ([elementName isEqualToString:@"fare"])
	{
		self.currentItinerary.fare = [NSMutableString string];
		// [self.currentItinerary.fare appendFormat:@"Fare: "];	
	}
	else if ([elementName isEqualToString:@"toList"])
	{
		self.toList = [[[NSMutableArray alloc] init] autorelease];
		self.currentList = self.toList;
	}
	else if ([elementName isEqualToString:@"location"])
	{
		if (self.currentList != nil)
		{
			TripLegEndPoint *loc = [[[TripLegEndPoint alloc] init] autorelease];
			[self.currentList addObject:loc];
			self.currentObject = loc;
		}
	}
	else if ([elementName isEqualToString:@"fromList"])
	{
		self.fromList = [[[NSMutableArray alloc] init] autorelease];
		self.currentList = self.fromList;
	}
	
	if ([self isProp:elementName] || [elementName isEqualToString:@"regular"] || [elementName isEqualToString:@"special"]
			|| [elementName isEqualToString:@"url"])		
	{
		self.contentOfCurrentProperty = [[[NSMutableString alloc] init] autorelease];
	}
	
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    [super parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
    
    if (qName) {
        elementName = qName;
    }
	
	if (self.currentObject != nil && [self isProp:elementName])
		
	{
		NSString *selName = [NSString stringWithFormat:@"setX%@:", elementName];
		SEL prop = NSSelectorFromString(selName);
		if ([self.currentObject respondsToSelector:prop])
		{
			[self.currentObject performSelector:prop withObject:self.contentOfCurrentProperty];
		}
	}
	
	if ([elementName isEqualToString:@"regular"])
	{
		[self.currentItinerary.fare appendFormat:@"Adult: $%@\n", self.contentOfCurrentProperty];
	} 
	else if ([elementName isEqualToString:@"special"])
	{
		[self.currentItinerary.fare appendFormat:self.currentTagData, self.contentOfCurrentProperty];
	}
	else if ([elementName isEqualToString:@"leg"])
	{
		self.currentLeg = nil;
		self.currentObject = nil;
	}
	else if ([elementName isEqualToString:@"from"]
		|| [elementName isEqualToString:@"to"])
	{
		self.currentObject = self.currentLeg;
	}
	else if ([elementName isEqualToString:@"itinerary"]
			 || [elementName isEqualToString:@"error"])
	{
		self.currentItinerary = nil;
		self.currentObject = nil;
	}
	else if ([elementName isEqualToString:@"toList"]
		||	 [elementName isEqualToString:@"fromList"])
	{
		self.currentList = nil;
	}
	else if ([elementName isEqualToString:@"url"] && self.currentLeg !=nil)
	{
		self.currentLeg.legShape = [[[LegShapeParser alloc] init] autorelease];
		self.currentLeg.legShape.lineURL = self.contentOfCurrentProperty;
		// [self.currentLeg.legShape fetchCoords];
	}
	
	self.contentOfCurrentProperty = nil;
}

#pragma mark Data Helpers

-(void)clearRawData
{
	// we need this data to be cached, so do nothing
}

- (void)saveTrip
{
	SafeUserData *userData = [SafeUserData getSingleton];
	
	if (self.rawData !=nil)
	{
		[userData addToRecentTripsWithUserRequest:[self.userRequest toDictionary] 
										 description:[self longName] 
												blob:self.rawData];
	}
}

- (NSString*)shortName
{
	NSString *title = nil;
	
	if (self.userRequest.toPoint.locationDesc !=nil && !self.userRequest.toPoint.useCurrentLocation)
	{
		if (self.resultTo !=nil && self.resultTo.xdescription != nil)
		{
			title = [NSString stringWithFormat:@"To %@", self.resultTo.xdescription ];
		}
		else
		{
			title = [NSString stringWithFormat:@"To %@", self.userRequest.toPoint.locationDesc];
		}
	}
	else if (self.userRequest.fromPoint.locationDesc !=nil)
	{
		
		if (self.resultFrom !=nil && self.resultFrom.xdescription != nil)
		{
			title = [NSString stringWithFormat:@"From %@", self.resultFrom.xdescription ];
		}
		else
		{
			title = [NSString stringWithFormat:@"From %@", self.userRequest.fromPoint.locationDesc];
		}
	}
	
	return title;
	
}

- (NSString*)longName
{
	return [NSString stringWithFormat:
			@"%@%@ %@",
			[self mediumName], 
			[self.userRequest getTimeType],
			[self.userRequest getDateAndTime]];
}

- (NSString*)mediumName
{
	NSMutableString *title = [[[NSMutableString alloc] init] autorelease];
	
	
	if (self.userRequest.fromPoint.locationDesc !=nil)
	{
		
		if (self.resultFrom !=nil && self.resultFrom.xdescription != nil)
		{
			[title appendFormat:@"From: %@\n", self.resultFrom.xdescription ];
		}
		else
		{
			[title appendFormat:@"From: %@\n", self.userRequest.fromPoint.locationDesc];
		}
	}
	else {
		[title appendFormat:@"From: Acquired Location\n"];
	}
	
	
	if (self.userRequest.toPoint.locationDesc !=nil)
	{
		if (self.resultTo !=nil && self.resultTo.xdescription != nil)
		{
			[title appendFormat:@"To: %@\n", self.resultTo.xdescription ];
		}
		else
		{
			[title appendFormat:@"To: %@\n", self.userRequest.toPoint.locationDesc];
		}
	}
	else {
		[title appendFormat:@"To: %@\n", kAcquiredLocation];
	}
	

	return title;
	
}


- (void)addStopsFromUserFaves:(NSArray *)userFaves
{
	NSMutableArray * justStops = [[[NSMutableArray alloc] init] autorelease];
	
	int i;
	
	for (i=0; i< [userFaves count]; i++)
	{
		NSDictionary *dict = [userFaves objectAtIndex:i];
		
		if ([dict valueForKey:kUserFavesLocation] != nil)
		{
			[justStops insertObject:dict atIndex:[justStops count]];
		}
		
	}
	self.userFaves = justStops;
	
}

- (id)init
{
	if ((self = [super init]))
	{
		self.userRequest = [[[TripUserRequest alloc] init] autorelease];
	}
	return self;
	
}

+(NSArray *)distanceMapSingleton
{
    static NSArray *distanceMap = nil;
    
    if (distanceMap==nil)
    {
        distanceMap = [[NSArray arrayWithObjects:
                        @"1/10",
                        @"1/4",
                        @"1/2",
                        @"3/4",
                        @"1",
                        @"2",
                        nil] retain];
    }
    
    return [[distanceMap retain] autorelease];
}

static float distances[] = {0.1, 0.25, 0.5, 0.75, 1.0, 2.0};

+(int)distanceToIndex:(float)distance
{
    int max = sizeof(distances)/sizeof(distances[0]);
    
    for (int i=1; i<max; i++)
    {
        if (distance < distances[i])
        {
            return i-1;
        }
    }
    
    return max-1;
}

+(float)indexToDistance:(int)index
{
    int max = sizeof(distances)/sizeof(distances[0]);
    if (index < max)
    {
        return distances[index];
    }
    
    return distances[max-1];
}


@end
