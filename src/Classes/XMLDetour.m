//
//  XMLDetours.m
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

#import "XMLDetour.h"
#import "Detour.h"

static NSString *detourURLString = @"detours/route/%@";
static NSString *allDetoursURLString = @"detours";

@implementation XMLDetour


@synthesize detour = _detour;
@synthesize route = _route;

- (void)dealloc {
	self.detour = nil;
	self.route = nil;
	[super dealloc];
}

#pragma mark Initialize parsing

- (BOOL)getDetourForRoute:(NSString *)route parseError:(NSError **)error
{	
	self.route = route;
	BOOL ret = [self startParsing:[NSString stringWithFormat:detourURLString, route] parseError:error];	
	self.route = nil;
	return ret;
}


- (BOOL)getDetourForRoutes:(NSArray *)routes parseError:(NSError **)error
{	
	NSMutableString *commaSeparated = [[[NSMutableString alloc] init] autorelease];
	
	for (NSString *route in routes)
	{
		if (commaSeparated.length > 0)
		{
			[commaSeparated appendString:@","];
		}
		[commaSeparated appendString:route];
	}
	
	BOOL ret = [self startParsing:[NSString stringWithFormat:detourURLString, commaSeparated] parseError:error];	
	self.route = nil;
	return ret;
}

- (BOOL)getDetours:(NSError **)error
{	
	return [self startParsing:allDetoursURLString parseError:error];	
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
	
    if ([elementName isEqualToString:@"detour"]) {
		self.detour = [self replaceXMLcodes:[self safeValueFromDict:attributeDict valueForKey:@"desc"]];
	}
	else if ([elementName isEqualToString:@"route"])
	{
		NSString *rt = [self safeValueFromDict:attributeDict valueForKey:@"route"];
		
		if (self.route == nil || [self.route isEqualToString:rt])
		{
			Detour *detour = [[Detour alloc] init];
			detour.detourDesc = self.detour;
			detour.routeDesc = [self safeValueFromDict:attributeDict valueForKey:@"desc"];
			detour.route = rt;
			[self addItem:detour];
			[detour release];
		}
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
	
}


@end
