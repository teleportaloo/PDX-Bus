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
#import "TriMetInfo.h"
#import "RouteColorBlobView.h"
#import "TripUserRequest.h"
#import "TripEndPoint.h"


@implementation XMLTrips

static NSString *tripURLString = @"trips/tripplanner?%@&%@&Date=%@&Time=%@&Arr=%@&Walk=%f&Mode=%@&Min=%@&Format=XML&MaxItineraries=%d&";

#define IS_BLANK(STR) ((STR)==nil || (STR).length==0)


- (XMLTrips *) createReverse
{
    XMLTrips *reverse = [XMLTrips xml];
    
    reverse.userRequest.fromPoint = [[TripEndPoint alloc] init];
    reverse.userRequest.toPoint = [[TripEndPoint alloc] init];
    
    
    reverse.userRequest.fromPoint.locationDesc            = self.userRequest.toPoint.locationDesc;
    reverse.userRequest.fromPoint.coordinates           = self.userRequest.toPoint.coordinates;
    reverse.userRequest.fromPoint.useCurrentLocation    = self.userRequest.toPoint.useCurrentLocation;
    
    reverse.userRequest.toPoint.locationDesc            = self.userRequest.fromPoint.locationDesc;
    reverse.userRequest.toPoint.coordinates             = self.userRequest.fromPoint.coordinates;
    reverse.userRequest.toPoint.useCurrentLocation        = self.userRequest.fromPoint.useCurrentLocation;
    
    
    reverse.userRequest.dateAndTime            = self.userRequest.dateAndTime;
    reverse.userRequest.arrivalTime            = self.userRequest.arrivalTime;
    reverse.userRequest.tripMode            = self.userRequest.tripMode;
    reverse.userRequest.tripMin                = self.userRequest.tripMin;
    reverse.userRequest.maxItineraries        = self.userRequest.maxItineraries;
    reverse.userRequest.walk                = self.userRequest.walk;
    reverse.userFaves                        = self.userFaves;
    reverse.reversed                        = !self.reversed;
    reverse.userRequest.timeChoice          = TripAskForTime;
    
    return reverse;
}


- (XMLTrips *)createAuto
{
    XMLTrips *copy = [XMLTrips xml];
    copy.userRequest.fromPoint = [[TripEndPoint alloc] init];
    copy.userRequest.toPoint = [[TripEndPoint alloc] init];
    
    
    copy.userRequest.fromPoint.locationDesc            = self.userRequest.fromPoint.locationDesc;
    copy.userRequest.fromPoint.coordinates          = self.userRequest.fromPoint.coordinates;
    copy.userRequest.fromPoint.useCurrentLocation    = self.userRequest.fromPoint.useCurrentLocation;
    
    copy.userRequest.toPoint.locationDesc            = self.userRequest.toPoint.locationDesc;
    copy.userRequest.toPoint.coordinates            = self.userRequest.toPoint.coordinates;
    copy.userRequest.toPoint.useCurrentLocation        = self.userRequest.toPoint.useCurrentLocation;
    
    
    copy.userRequest.dateAndTime            = [self.userRequest.dateAndTime copyWithZone:NSDefaultMallocZone()];
    copy.userRequest.arrivalTime            = self.userRequest.arrivalTime;
    copy.userRequest.tripMode                = self.userRequest.tripMode;
    copy.userRequest.tripMin                = self.userRequest.tripMin;
    copy.userRequest.maxItineraries            = self.userRequest.maxItineraries;
    copy.userRequest.walk                    = self.userRequest.walk;
    copy.userRequest.timeChoice                = self.userRequest.timeChoice;
    copy.userFaves                            = self.userFaves;
    copy.reversed                            = false;
    copy.userRequest.timeChoice                = TripAskForTime;
    
    return copy;
}

- (void)resetCurrentLocation
{
    [self.userRequest.fromPoint resetCurrentLocation];
    [self.userRequest.toPoint   resetCurrentLocation];
}



- (SEL)selForProp:(NSString *)elementName
{
    if (self.selsForProps == nil)
    {
#define SEL_FOR_PROP(X) [@#X lowercaseString] : [NSValue valueWithPointer: NSSelectorFromString(@"setX" @#X @":") ]
        self.selsForProps = @{
                            SEL_FOR_PROP(date),
                            SEL_FOR_PROP(time),
                            SEL_FOR_PROP(message),
                            SEL_FOR_PROP(startTime),
                            SEL_FOR_PROP(endTime),
                            SEL_FOR_PROP(duration),
                            SEL_FOR_PROP(distance),
                            SEL_FOR_PROP(numberOfTransfers),
                            SEL_FOR_PROP(numberOfTripLegs),
                            SEL_FOR_PROP(walkingTime),
                            SEL_FOR_PROP(transitTime),
                            SEL_FOR_PROP(waitingTime),
                            SEL_FOR_PROP(number),
                            SEL_FOR_PROP(internalNumber),
                            SEL_FOR_PROP(name),
                            SEL_FOR_PROP(direction),
                            SEL_FOR_PROP(block),
                            SEL_FOR_PROP(lat),
                            SEL_FOR_PROP(lon),
                            SEL_FOR_PROP(stopId),
                            SEL_FOR_PROP(description)
                            };
    }
    
    
    NSValue *selVal = _selsForProps[[elementName lowercaseString]];
    
    if (selVal == nil)
    {
        return nil;
    }
    
    return selVal.pointerValue;
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
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MM-dd-yy";
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.dateFormat = @"hh:mm'%20'aa";
    
    // The AM or PM text may turn up in a different language if the locale is not USA.  While this is perfect
    // for the GUI, the TriMet query needs to be in English.
    
    NSLocale *usa = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    
    timeFormatter.locale = usa;
    dateFormatter.locale = usa;
    
    
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
        [self startParsing:finalTripURLString];
    }
    else {
        self.rawData = oldRawData;
        
        [self parseRawData:&parseError];
        LOG_PARSE_ERROR(parseError);
    }

    
    int l;
    TripLeg          *leg;
    TripLeg          *previous;

    for (TripItinerary *it in self)
    {
        it.displayEndPoints = [NSMutableArray array];
        
        leg = it.legs.firstObject;
        
        [self addGeocodedDescriptionToLeg:leg];
        
        [it startPointText:TripTextTypeUI];
        
        if (it.startPoint !=nil && it.startPoint.displayText != nil)
        {
            [it.displayEndPoints addObject:it.startPoint];
        }
        
        // Fix the thru-routes
        if (it.legs != nil)
        {
            for (l = 1; l < it.legs.count; l++)
            {
                leg = it.legs[l];
                
                if (leg.from.thruRoute)
                {
                    previous = it.legs[l-1];
                    previous.to.thruRoute = YES;
                }
            }
        }
        
        if (it.legs != nil)
        {
            for (l = 0; l < it.legs.count; l++)
            {
                leg = it.legs[l];
                
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
                    if (![leg.mode isEqualToString:kModeWalk])
                    {
                        leg.to.deboard = YES;
                    }
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
    
    if (self.count ==0 || !_hasData)
    {
        [self initItems];
        
        TripItinerary *it = [[TripItinerary alloc] init];
        
        it.xmessage = @"Network error, touch here to check network.";
        
        [self addItem:it];
        
    }
}

#pragma mark Parser callbacks

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    
}

XML_START_ELEMENT(request)
{
    self.currentObject = nil;
}

XML_START_ELEMENT(response)
{
    [self initItems];
    _hasData = YES;
    self.currentObject = self;
}

XML_START_ELEMENT(itinerary)
{
    self.currentItinerary =  [[TripItinerary alloc] init];
    self.currentLeg = nil;
    [self addItem:self.currentItinerary];
    self.currentObject = self.currentItinerary;
}

XML_START_ELEMENT(error)
{
    CALL_XML_START_ELEMENT(itinerary);
}

XML_START_ELEMENT(leg)
{
    self.currentLeg = [TripLeg data];
    [self.currentItinerary.legs addObject:self.currentLeg];
    self.currentObject = self.currentLeg;
    self.currentLeg.mode = ATRSTR(mode);
    self.currentLeg.order = ATRSTR(order);
}

XML_START_ELEMENT(from)
{
    if (self.currentLeg!=nil)
    {
        self.currentLeg.from = [TripLegEndPoint data];
        self.currentObject = self.currentLeg.from;
    
        if (ATREQ(self.currentLeg.order, @"thru-route"))
        {
            self.currentLeg.from.thruRoute = YES;
        }
    }
    else if (self.resultFrom == nil)
    {
        self.resultFrom = [TripLegEndPoint data];
        self.currentObject = self.resultFrom;
    }
}

XML_START_ELEMENT(to)
{
    if (self.currentLeg!=nil)
    {
        self.currentLeg.to = [TripLegEndPoint data];
        self.currentObject = self.currentLeg.to;
    }
    else if (self.resultTo == nil)
    {
        self.resultTo = [TripLegEndPoint data];
        self.currentObject = self.resultTo;
    }
}

XML_START_ELEMENT(special)
{
    NSString *tag = ATRSTR(id);
    if (ATREQ(tag, @"honored"))
    {
        self.currentTagData = NSLocalizedString(@"Honored Citizen: $%@\n", @"fare type");
    }
    else if (ATREQ(tag, @"youth"))
    {
        self.currentTagData = NSLocalizedString(@"Youth/Student: $%@\n", @"fare type");
    }
    else
    {
        self.currentTagData = [NSString stringWithFormat:@"%@ ($%@)", tag, @"%@"];
    }
}

XML_START_ELEMENT(fare)
{
    self.currentItinerary.fare = [NSMutableString string];
    // [self.currentItinerary.fare appendFormat:@"Fare: "];
}

XML_START_ELEMENT(tolist)
{
    self.toList = [NSMutableArray array];
    self.currentList = self.toList;
}

XML_START_ELEMENT(location)
{
    if (self.currentList != nil)
    {
        TripLegEndPoint *loc = [TripLegEndPoint data];
        [self.currentList addObject:loc];
        self.currentObject = loc;
    }
}

XML_START_ELEMENT(fromlist)
{
    self.fromList = [NSMutableArray array];
    self.currentList = self.fromList;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    [super parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
    
    if (qName) {
        elementName = qName;
    }
    
    if ([self selForProp:elementName]!=nil || ELTYPE(regular) || ELTYPE(special)
            || ELTYPE(url))
    {
        self.contentOfCurrentProperty = [NSMutableString string];
    }
    
}

XML_END_ELEMENT(regular)
{
    [self.currentItinerary.fare appendFormat:@"Adult: $%@\n", self.contentOfCurrentProperty];
}

XML_END_ELEMENT(special)
{
    [self.currentItinerary.fare appendFormat:self.currentTagData, self.contentOfCurrentProperty];
}

XML_END_ELEMENT(leg)
{
    self.currentLeg = nil;
    self.currentObject = nil;
}

XML_END_ELEMENT(from)
{
    self.currentObject = self.currentLeg;
}

XML_END_ELEMENT(to)
{
    self.currentObject = self.currentLeg;
}

XML_END_ELEMENT(itinerary)
{
    if (IS_BLANK(self.currentItinerary.xdate))
    {
        self.currentItinerary.xdate = self.xdate;
    }
    
    if (IS_BLANK(self.currentItinerary.xstartTime))
    {
        self.currentItinerary.xstartTime = self.xtime;
    }
    
    self.currentItinerary = nil;
    self.currentObject = nil;
}

XML_END_ELEMENT(error)
{
    self.currentItinerary = nil;
    self.currentObject = nil;
}

XML_END_ELEMENT(tolist)
{
    self.currentList = nil;
}

XML_END_ELEMENT(fromlist)
{
    self.currentList = nil;
}

XML_END_ELEMENT(url)
{
    if (self.currentLeg !=nil)
    {
        self.currentLeg.legShape = [[LegShapeParser alloc] init];
        self.currentLeg.legShape.lineURL = self.contentOfCurrentProperty;
        // [self.currentLeg.legShape fetchCoords];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    [super parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
    
    if (qName) {
        elementName = qName;
    }
    
    SEL sel = [self selForProp:elementName];
    
    if (self.currentObject != nil && sel!=nil && [self.currentObject respondsToSelector:sel])
    {
        DEBUG_LOG(@"XML==:%@=%@", elementName, self.contentOfCurrentProperty);
        
        IMP imp = [self.currentObject methodForSelector:sel];
        void (*func)(id, SEL, NSString *) = (void *)imp;
        func(self.currentObject, sel, self.contentOfCurrentProperty);
        
        // [self.currentObject performSelector:sel withObject:self.contentOfCurrentProperty];
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
    SafeUserData *userData = [SafeUserData sharedInstance];
    
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
            [self.userRequest timeType],
            [self.userRequest getDateAndTime]];
}

- (NSString*)mediumName
{
    NSMutableString *title = [NSMutableString string];
    
    
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


- (NSUserActivity*)userActivity
{
    return [self.userRequest userActivityWithTitle:self.shortName];
}

- (void)addStopsFromUserFaves:(NSArray *)userFaves
{
    NSMutableArray * justStops = [NSMutableArray array];

    for (NSDictionary *dict in userFaves)
    {
        if (dict[kUserFavesLocation] != nil)
        {
            [justStops insertObject:dict atIndex:justStops.count];
        }
    }
    self.userFaves = justStops;    
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        self.userRequest = [[TripUserRequest alloc] init];
    }
    return self;
    
}

+(NSArray *)distanceMapSingleton
{
    static NSArray *distanceMap = nil;
    
    if (distanceMap==nil)
    {
        distanceMap = @[
                        @"⅒",
                        @"¼",
                        @"½",
                        @"¾",
                        @"1",
                        @"2"];
    }
    
    return distanceMap;
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
