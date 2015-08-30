//
//  XMLStreetcarPredictions.m
//  PDX Bus
//
//  Created by Andrew Wallace on 3/22/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLStreetcarPredictions.h"

@implementation XMLStreetcarPredictions

@synthesize currentDepartureObject = _currentDepartureObject;
@synthesize directionTitle = _directionTitle;
@synthesize routeTitle = _routeTitle;
@synthesize blockFilter = _blockFilter;
@synthesize copyright = _copyright;
@synthesize nextBusRouteId = _nextBusRouteId;

- (void)dealloc
{
	self.currentDepartureObject = nil;
	self.directionTitle = nil;
	self.routeTitle = nil;
	self.blockFilter = nil;
	self.copyright = nil;
    self.nextBusRouteId = nil;
    self.stopTitle = nil;
	
	[super dealloc];
}

#pragma mark Initiate Parsing

- (BOOL)getDeparturesForLocation:(NSString *)location parseError:(NSError **)error;

{	
   
	[self startParsing:location parseError:error cacheAction:TriMetXMLUseShortCache];
	return true;
}

#pragma mark Parser Callbacks

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
	
	if ([elementName isEqualToString:@"body"])
	{
		self.copyright = [self safeValueFromDict:attributeDict valueForKey:@"copyright"];
	}
	
	if ([elementName isEqualToString:@"predictions"]) {
		self.routeTitle = [self safeValueFromDict:attributeDict valueForKey:@"routeTitle"];
		
		self.directionTitle = [attributeDict valueForKey:@"dirTitleBecauseNoPredictions"];
#ifdef DEBUGLOGGING
        self.stopTitle = [attributeDict valueForKey:@"stopTitle"];
#endif
        
		if (self.directionTitle!=nil)
		{
			[self initArray];
			hasData = YES;
		}
	}
	
	if ([elementName isEqualToString:@"direction"]) {
		self.directionTitle = [self safeValueFromDict:attributeDict valueForKey:@"title"];
		
		if (!hasData)
		{
			[self initArray];
			hasData = YES;
		}
	}
	
    if ([elementName isEqualToString:@"prediction"])
	{
        // Note - the vehicle is the block - I put the block into the streetcar block!
		NSString *block = [self safeValueFromDict:attributeDict valueForKey:@"block"];
		if ((self.blockFilter==nil) || ([self.blockFilter isEqualToString:block]))
		{
			NSString *name = [NSString stringWithFormat:@"%@ %@", self.routeTitle, self.directionTitle];
            
            // There are some bugs in the streetcar feed (e.g. Cl instead of CL)
			
			self.currentDepartureObject = [[[DepartureData alloc] init] autorelease];
			self.currentDepartureObject.hasBlock       = true;
			self.currentDepartureObject.route          = nil;
			self.currentDepartureObject.fullSign       = name;
			self.currentDepartureObject.routeName      = name;
			self.currentDepartureObject.block          = block;
			self.currentDepartureObject.status         = kStatusEstimated;
			self.currentDepartureObject.nextBus        = [self getTimeFromAttribute:attributeDict valueForKey:@"minutes"];
			self.currentDepartureObject.streetcar      = true;
            self.currentDepartureObject.dir            = nil;
			self.currentDepartureObject.copyright      = self.copyright;
            self.currentDepartureObject.streetcarId    = [self safeValueFromDict:attributeDict valueForKey:@"vehicle"];
			
			/*
			[[self safeValueFromDict:attributeDict valueForKey:@"dirTag"] isEqualToString:@"t5"]
														? @"1" : @"0";
			*/
			
			/*
			self.currentDepartureObject.locationDesc =	self.locDesc;
			self.currentDepartureObject.locid		 =  self.locid;
			self.currentDepartureObject.locationDir  =  self.locDir;
			*/
			
			[self addItem:self.currentDepartureObject];
		}
		else
		{
			self.currentDepartureObject=nil;
		}
    }
}

@end
