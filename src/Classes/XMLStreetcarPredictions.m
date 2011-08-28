//
//  XMLStreetcarPredictions.m
//  PDX Bus
//
//  Created by Andrew Wallace on 3/22/10.
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

#import "XMLStreetcarPredictions.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"

@implementation XMLStreetcarPredictions

@synthesize currentDepartureObject = _currentDepartureObject;
@synthesize directionTitle = _directionTitle;
@synthesize routeTitle = _routeTitle;
@synthesize blockFilter = _blockFilter;
@synthesize streetcarShortNames = _streetcarShortNames;
@synthesize streetcarDirections = _streetcarDirections;
@synthesize copyright = _copyright;
@synthesize dirFromQuery = _dirFromQuery;

- (void)dealloc
{
	self.currentDepartureObject = nil;
	self.directionTitle = nil;
	self.routeTitle = nil;
	self.blockFilter = nil;
	self.streetcarDirections = nil;
	self.streetcarShortNames = nil;
	self.copyright = nil;
	self.dirFromQuery = nil;
	
	[super dealloc];
}

#pragma mark Initiate Parsing

- (BOOL)getDeparturesForLocation:(NSString *)location parseError:(NSError **)error;

{
	TriMetTimesAppDelegate *appDelegate = (TriMetTimesAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	self.streetcarDirections = [appDelegate getStreetcarDirections];
	self.streetcarShortNames = [appDelegate getStreetcarShortNames];
	
	// We need to extract the direction from the query so we can filter on it,
	// as some Streetcar stops return predictions for two different directions.
	NSScanner *scanner = [NSScanner scannerWithString:location];
	
	NSString *tmp = nil;
	[scanner scanUpToString:@"d=" intoString:&tmp];
	
	if (![scanner isAtEnd])
	{
		[scanner setScanLocation:[scanner scanLocation] + 2]; // 2 is the size of "d=".
		NSString *dir;
		[scanner scanUpToString:@"&" intoString:&dir];
		self.dirFromQuery = dir;
	}

	[self startParsing:location parseError:error];
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
	
    if ([elementName isEqualToString:@"prediction"]
		&& [[self safeValueFromDict:attributeDict valueForKey:@"dirTag"] isEqualToString:self.dirFromQuery])
	{		
		NSString *block = [self safeValueFromDict:attributeDict valueForKey:@"vehicle"];
		if ((self.blockFilter==nil) || ([self.blockFilter isEqualToString:block]))
		{
			NSString *name = [NSString stringWithFormat:@"%@ %@", self.routeTitle, self.directionTitle];
			
			NSString *shortName = [self.streetcarShortNames objectForKey:name];
			
			if (shortName==nil) 
			{
				shortName = name;
			}
			
			self.currentDepartureObject = [[[Departure alloc] init] autorelease];
			self.currentDepartureObject.hasBlock = true;
			self.currentDepartureObject.route =			nil;
			self.currentDepartureObject.fullSign =		name;
			self.currentDepartureObject.routeName =		shortName;
			self.currentDepartureObject.block =         block;
			self.currentDepartureObject.status =		kStatusEstimated;
			self.currentDepartureObject.nextBus =		[self getTimeFromAttribute:attributeDict valueForKey:@"minutes"];
			self.currentDepartureObject.streetcar = true;
			self.currentDepartureObject.dir =			[self.streetcarDirections objectForKey:[self safeValueFromDict:attributeDict valueForKey:@"dirTag"]];
			self.currentDepartureObject.copyright = self.copyright;
			
			
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
			self.currentDepartureObject!=nil;
		}
    }
}


@end
