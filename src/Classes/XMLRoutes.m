//
//  XMLRoutes.m
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

#import "XMLRoutes.h"

//static NSString *routesURLString = @"routeConfig/dir/true";
static NSString *routesURLString = @"routeConfig";
static NSString *oneRouteURLString = @"routeConfig/route/%@/dir/true";

@implementation XMLRoutes

@synthesize currentRouteObject = _currentRouteObject;

- (void)dealloc
{
	self.currentRouteObject = nil;	
	[super dealloc];
}

#pragma mark Data fetchers

- (BOOL)getRoutes:(NSError **)error cacheAction:(CacheAction)cacheAction;
{	
	return [self startParsing:routesURLString parseError:error cacheAction:cacheAction];	
}

- (BOOL)getDirections:(NSString *)route error:(NSError **)error cacheAction:(CacheAction)cacheAction
{	
	return [self startParsing:[NSString stringWithFormat:oneRouteURLString, route] parseError:error cacheAction:cacheAction];	
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
	
    if ([elementName isEqualToString:@"route"]) {
        self.currentRouteObject = [[[Route alloc] init] autorelease];
		
		self.currentRouteObject.route = [self safeValueFromDict:attributeDict valueForKey:@"route"];
		self.currentRouteObject.desc =  [self safeValueFromDict:attributeDict valueForKey:@"desc"];		
		
        return;
    }
	
	if ([elementName isEqualToString:@"dir"])
	{
		[self.currentRouteObject.directions 
			setObject:	[self safeValueFromDict:attributeDict valueForKey:@"desc"]  
			forKey:		[self safeValueFromDict:attributeDict valueForKey:@"dir"]];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    [super parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
    
    if (qName) {
        elementName = qName;
    }
	
	if ([elementName isEqualToString:@"route"]) {
		[self addItem:self.currentRouteObject];
		self.currentRouteObject = nil; 
	}
}

@end
