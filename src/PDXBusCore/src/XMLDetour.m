//
//  XMLDetours.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


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
    [super parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
    
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


@end
