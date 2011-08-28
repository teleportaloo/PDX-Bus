//
//  XMLStops.m
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

#import "XMLStops.h"

static NSString *stopsURLString = @"routeConfig/route/%@/dir/%@/stops/true";

@implementation XMLStops

@synthesize currentStopObject = _currentStopObject;
@synthesize routeId				= _routeId;
@synthesize direction			= _direction;
@synthesize routeDescription	= _routeDescription;
@synthesize afterStop			= _afterStop;

- (void)dealloc
{
	self.currentStopObject = nil;
	self.direction = nil;
	self.routeId = nil;
	self.routeDescription = nil;
	self.afterStop = nil;
	[super dealloc];
	
}

#pragma mark Data fetchers

- (BOOL)getStopsAfterLocation:(NSString *)locid route:(NSString *)route direction:(NSString *)dir 
				  description:(NSString *)desc parseError:(NSError **)error cacheAction:(CacheAction)cacheAction
{
	self.routeId = route;
	self.direction = dir;
	self.routeDescription = desc;
	self.afterStop = locid;
	
	return [self startParsing:[NSString stringWithFormat:stopsURLString, route, dir] parseError:error cacheAction:cacheAction];
	
}

- (BOOL)getStopsForRoute:(NSString *)route direction:(NSString *)dir 
			 description:(NSString *)desc parseError:(NSError **)error cacheAction:(CacheAction)cacheAction
{	
	self.routeId = route;
	self.direction = dir;
	self.routeDescription = desc;
	self.afterStop = nil;
	
	return [self startParsing:[NSString stringWithFormat:stopsURLString, route, dir] parseError:error cacheAction:cacheAction];
}

#pragma mark Parser callbacks

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    
}



- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (qName) {
        elementName = qName;
    }
	
	if ([elementName isEqualToString:@"resultSet"]) {
		[self initArray]; 
		hasData = YES;
	}
	
    if ([elementName isEqualToString:@"stop"]) {
		NSString *locid =	[self safeValueFromDict:attributeDict valueForKey:@"locid"];
        
		if (self.afterStop !=nil && [locid isEqualToString:self.afterStop])
		{
			self.afterStop = nil;
			self.currentStopObject = nil;
		}
		else if (self.afterStop == nil)
		{
			self.currentStopObject = [[[Stop alloc] init] autorelease];
			
			self.currentStopObject.locid =	[self safeValueFromDict:attributeDict valueForKey:@"locid"];
			self.currentStopObject.desc =	[self safeValueFromDict:attributeDict valueForKey:@"desc"];		
			self.currentStopObject.tp =		[[self safeValueFromDict:attributeDict valueForKey:@"tp"] isEqualToString:@"true"];
			self.currentStopObject.lat =	[self safeValueFromDict:attributeDict valueForKey:@"lat"];
			self.currentStopObject.lng =    [self safeValueFromDict:attributeDict valueForKey:@"lng"];
		}
        return;
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
    if (qName) {
        elementName = qName;
    }
	
	if ([elementName isEqualToString:@"stop"]) {
		if (self.currentStopObject !=nil)
		{
			[self addItem:self.currentStopObject ];
			self.currentStopObject.index = [self.itemArray count];
			self.currentStopObject = nil;
		}
	}
}




@end
