//
//  RssXML.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/4/10.

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

#import "RssXML.h"
#import "RssLink.h"



#define kNoItemsFound  @"No items were found"
#define kNoNetwork	   @"%@: touch here for info"

@implementation RssXML

@synthesize currentItem = _currentItem;
@synthesize title = _title;
@synthesize rssDateFormatter = _rssDateFormatter;

- (void) dealloc
{
	self.currentItem = nil;
	self.title = nil;
	self.rssDateFormatter = nil;
	[super dealloc];
}

- (id)init
{
	if ((self = [super init]))
	{
		self.rssDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		NSLocale *enUS = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
		[self.rssDateFormatter setLocale:enUS];
		NSArray *shortWeekSymbols = [NSArray arrayWithObjects:@"Sun,", @"Mon,", @"Tue,", @"Wed,", @"Thu,", @"Fri,", @"Sat,", nil]; 
		[self.rssDateFormatter setShortWeekdaySymbols:shortWeekSymbols];
		[enUS release];
		
		[self.rssDateFormatter setDateFormat:@"EEEdd MMM yyyy HH:mm:ss z"];
	}
	return self;
}

#pragma mark Data getters

- (NSString *)fullErrorMsg
{
	if ([self safeItemCount] > 0)
	{
		return nil;
	}
	else 
	{
		if ([self gotData])
		{
			return kNoItemsFound;
		}
		else {
			if (self.errorMsg)
			{
				return [NSString stringWithFormat:kNoNetwork, self.errorMsg];
			}
			return [NSString stringWithFormat:kNoNetwork, @"No Network"];
		}
	}
	return nil;
}

#pragma mark TriMetXML methods

- (NSString*)fullAddressForQuery:(NSString *)query
{
	return query;
}

#pragma mark Parser callbacks

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
	if ([elementName isEqualToString:@"channel"])
	{
		[self initArray];
		hasData = true;
	}
	
	if ([elementName isEqualToString:@"item"])
	{
		RssLink *newLink = [[RssLink alloc] init];
		self.currentItem = newLink;
		[newLink release];
	}
	
    if ([elementName isEqualToString:@"title"]
		|| [elementName isEqualToString:@"link"]
		|| [elementName isEqualToString:@"description"]
		|| [elementName isEqualToString:@"pubDate"])
	{
		NSMutableString *newProp = [[NSMutableString alloc] init];
		self.contentOfCurrentProperty = newProp ;
		[newProp release];
	}
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{ 
	if ([NSThread currentThread].isCancelled)
	{
		[parser abortParsing];
		return;
	}
	
    if (qName) {
        elementName = qName;
    }
	
	if (self.currentItem !=nil)
	{
		if ([elementName isEqualToString:@"title"]) {
			self.currentItem.title = [self replaceXMLcodes:self.contentOfCurrentProperty];
		}
		
		if ([elementName isEqualToString:@"link"]) {
			self.currentItem.link = self.contentOfCurrentProperty;
		}
		
		if ([elementName isEqualToString:@"description"]) {
			self.currentItem.description = self.contentOfCurrentProperty;
		}
		
		if ([elementName isEqualToString:@"pubDate"]) {
			self.currentItem.date = [self.rssDateFormatter dateFromString:self.contentOfCurrentProperty];
			
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			// [dateFormatter setDateFormat:@"MM-dd-yy"];
			
			[dateFormatter setDateStyle:kCFDateFormatterMediumStyle];
			[dateFormatter setTimeStyle:kCFDateFormatterMediumStyle];
			
			
			self.currentItem.dateString =  [NSString stringWithFormat:@"%@",
						   [dateFormatter stringFromDate:self.currentItem.date]];
			
			[dateFormatter release];
			
		}
		
		
		if ([elementName isEqualToString:@"item"]) {
			[self addItem:self.currentItem];
			self.currentItem = nil;
		}
	}
	else {
		if ([elementName isEqualToString:@"title"]  && self.title == nil) {
			self.title = [self replaceXMLcodes:self.contentOfCurrentProperty];
		}
	}
	self.contentOfCurrentProperty = nil;
}

@end
