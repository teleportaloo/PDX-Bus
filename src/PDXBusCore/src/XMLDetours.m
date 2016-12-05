//
//  XMLDetours.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLDetours.h"
#import "Detour.h"
#import "StringHelper.h"

static NSString *detourURLString = @"detours/route/%@";
static NSString *allDetoursURLString = @"detours";

@implementation XMLDetours


@synthesize detour = _detour;
@synthesize route = _route;

- (void)dealloc {
	self.detour = nil;
	self.route = nil;
	[super dealloc];
}

#pragma mark Initialize parsing

- (BOOL)getDetoursForRoute:(NSString *)route
{	
	self.route = route;
	BOOL ret = [self startParsing:[NSString stringWithFormat:detourURLString, route]];
	self.route = nil;
	return ret;
}


- (BOOL)getDetoursForRoutes:(NSArray *)routes
{	
    NSMutableString *commaSeparated = [NSString commaSeparatedStringFromEnumerator:routes selector:@selector(self)];
	
	BOOL ret = [self startParsing:[NSString stringWithFormat:detourURLString, commaSeparated]];
	self.route = nil;
	return ret;
}

- (BOOL)getDetours
{	
	return [self startParsing:allDetoursURLString];
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
	
	if (ELTYPE(resultSet)) {
		
		[self initArray];
		_hasData = YES;
	}
	
    if (ELTYPE(detour)) {
		self.detour = [self replaceXMLcodes:ATRVAL(desc)];
	}
	else if (ELTYPE(route))
	{
		NSString *rt = ATRVAL(route);
		
		if (self.route == nil || [self.route isEqualToString:rt])
		{
			Detour *detour = [[Detour alloc] init];
			detour.detourDesc = self.detour;
			detour.routeDesc = ATRVAL(desc);
			detour.route = rt;
			[self addItem:detour];
			[detour release];
		}
	}
}


@end
