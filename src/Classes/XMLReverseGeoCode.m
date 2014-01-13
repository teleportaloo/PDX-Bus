//
//  XMLReverseGeoCode.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/29/10.
//  Copyright 2010. All rights reserved.
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

#import "XMLReverseGeoCode.h"
#import "XMLTrips.h"


@implementation XMLReverseGeoCode

@synthesize results = _results;
@synthesize elements = _elements;
@synthesize dividers= _dividers;
@synthesize takeFirst = _takeFirst;

- (void)dealloc
{
	self.results = nil;
	self.elements = nil;
	[super dealloc];
}

- (NSMutableString*)prefixedAddress
{
	NSMutableString *address = [[[NSMutableString alloc] init] autorelease];
	[address appendFormat:kNearTo];
	return address;
	
}
- (NSString *)fetchAddress:(CLLocation *)loc;
{
	NSError *parseError = nil;
	NSString *query = [self fullAddressForLocation:loc];
	// NSString *query = [NSString stringWithFormat:@"lat=0&lng=0", loc.coordinate.latitude, loc.coordinate.longitude];
	
	self.results  = [[[NSMutableDictionary alloc] init] autorelease];
	
	self.giveUp = 10.0;
	
	if ([self startParsing:query parseError:&parseError] && hasData)
	{
		
		NSMutableString *address = [self prefixedAddress];
		NSString *item;
		
		for (int i=0; i< self.elements.count; i++)
		{
			item = [self.results objectForKey:[self.elements objectAtIndex:i]];
			if (item !=nil && item.length !=0)
			{
				[address appendFormat:@"%@%@", item, [self.dividers objectAtIndex:i]];
			}
		}
		
		return address;
		
	}
	return nil;
}

- (NSString *)getServiceName
{
	return @"None";
}

#pragma mark TriMetXML methods

- (NSString*)fullAddressForLocation:(CLLocation *)loc
{
	return [NSString stringWithFormat:@"http://ws.geonames.org/findNearestAddress?lat=%f&lng=%f", 
			loc.coordinate.latitude, 
			loc.coordinate.longitude];
}


- (NSString*)fullAddressForQuery:(NSString *)query
{
	return query;
}



#pragma mark Parser callbacks

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    hasData = NO;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    
    [super parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
    
    if (qName) {
        elementName = qName;
    }
	
	for (int i=0; i< self.elements.count; i++)
	{
		if ([elementName isEqualToString:[self.elements objectAtIndex:i]])
		{
			hasData = YES;
			self.contentOfCurrentProperty = [[[NSMutableString alloc] init] autorelease];
			break;
		}
	}
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    [super parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
    
    if (qName) {
        elementName = qName;
    }
	
	if (self.contentOfCurrentProperty !=nil)
	{
		if ([self.results objectForKey:elementName]==nil || !self.takeFirst)
		{
			[self.results setObject:self.contentOfCurrentProperty forKey:elementName];
		}
	}
	
	self.contentOfCurrentProperty = nil;
}


@end
