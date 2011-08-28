//
//  RailStation.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/4/10.
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

#import "RailStation.h"
#import "XMLStops.h"
#import "debug.h"
#import "RailMapView.h"
#import "TriMetRouteColors.h"
#import "RouteColorBlobView.h"
#import "AllRailStationView.h"

#ifdef MAXCOLORS

#endif

@implementation RailStation

@synthesize  locList = _locList;
@synthesize  dirList = _dirList;
@synthesize  station = _station;
@synthesize  wikiLink = wikiLink;
@synthesize  index = _index;
@dynamic line;

- (void)dealloc
{	
	self.locList = nil;
	self.dirList = nil;
	self.station = nil;
	self.wikiLink = nil;
	[super dealloc];
}

- (RAILLINES) line
{	
	return [AllRailStationView railLines:self.index];
}

-(NSComparisonResult)compareUsingStation:(RailStation*)inStation
{
	return [self.station compare:inStation.station];
}


+ (void)scannerInc:(NSScanner *)scanner 
{	
	if (![scanner isAtEnd])
	{
		[scanner setScanLocation:[scanner scanLocation] + 1];
	}
}


+ (void)nextSlash:(NSScanner *)scanner intoString:(NSString **)substr;
{
	if (![scanner isAtEnd])
	{
		[scanner scanUpToString:@"/" intoString:substr];
		
		// NSLog(@"%@", *substr);
		[self scannerInc:scanner];
	}
	
}

typedef struct strmap {
	NSString *shortname;
	NSString *longname;
} strmap;

static strmap dirmap [] =
{
	{ @"N", @"Northbound" },
	{ @"S", @"Southbound" },
	{ @"E", @"Eastbound"  },
	{ @"W", @"Westbound"  },
	{ @"NE", @"Northeastbound" },
	{ @"SE", @"Southeastbound" },
	{ @"SW", @"Southwestbound" },
	{ @"NW", @"Sorthwestbound" },
	{ nil, nil },
	{ nil, nil } };

- (NSString *)direction:(NSString *)dir
{
	for (strmap *i = dirmap; i->shortname!=nil ; i++)
	{
		if ([i->shortname isEqualToString:dir])
		{
			return i->longname;
		}
	}
	return [dir stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)shortDirection:(NSString *)dir
{
	for (strmap *i = dirmap; i->shortname!=nil ; i++)
	{
		if ([i->longname isEqualToString:dir])
		{
			return i->shortname;
		}
	}
	return [dir stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)url
{
	NSMutableString *url = [[[NSMutableString alloc] init] autorelease];
	
	[url appendFormat:@"s:%@/%@", [self.station stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], 
	 self.wikiLink!=nil ? [self.wikiLink stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : @""];
	
	for (int i=0; i<self.locList.count; i++)
	{
		[url appendFormat:@"/%@,%@", 	[self shortDirection:[self.dirList objectAtIndex:i]],
		 [self.locList objectAtIndex:i]];
	}
	
	return url;
}

+ (NSString *)nameFromHotspot:(HOTSPOT *)hotspot
{
	NSScanner *scanner = [NSScanner scannerWithString:[NSString stringWithUTF8String:hotspot->action]];
	NSCharacterSet *colon = [NSCharacterSet characterSetWithCharactersInString:@":"];
	
	NSString *substr;
	NSString *stationName;
	
	[scanner scanUpToCharactersFromSet:colon intoString:&substr];
	
	if (substr == nil)
	{
		return nil;
	}
	
	[RailStation scannerInc:scanner];
	[RailStation nextSlash:scanner intoString:&stationName];
	
	return [stationName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
}

- (id)initFromHotSpot:(HOTSPOT *)hotspot index:(int)index
{
	if ((self = [super init]))
	{
		NSScanner *scanner = [NSScanner scannerWithString:[NSString stringWithUTF8String:hotspot->action]];
		NSCharacterSet *colon = [NSCharacterSet characterSetWithCharactersInString:@":"];
		NSCharacterSet *comma = [NSCharacterSet characterSetWithCharactersInString:@","];
		NSCharacterSet *slash = [NSCharacterSet characterSetWithCharactersInString:@"/"];
		
		NSString *substr=nil;
		NSString *stationName=nil;
		NSString *wiki=nil;
		
		[scanner scanUpToCharactersFromSet:colon intoString:&substr];
		
		if (substr == nil)
		{
			return nil;
		}
		
		[RailStation scannerInc:scanner];
		[RailStation nextSlash:scanner intoString:&stationName];
		[RailStation nextSlash:scanner intoString:&wiki];
		
		self.station = [stationName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		self.wikiLink =  (wiki !=nil ? [wiki stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : nil);
		self.locList = [[[NSMutableArray alloc] init] autorelease];
		self.dirList = [[[NSMutableArray alloc] init] autorelease];
		
		// NSString *stop = nil;
		NSString *dir = nil;
		NSString *locId = nil;
		
		
		while ([scanner scanUpToCharactersFromSet:comma intoString:&dir])
		{	
			if (![scanner isAtEnd])
			{
				[scanner setScanLocation:[scanner scanLocation]+1];
			}
			
			[scanner scanUpToCharactersFromSet:slash intoString:&locId];
			
			[self.dirList addObject:[self direction:dir]];
			[self.locList addObject:locId];
			
			if (![scanner isAtEnd])
			{
				[scanner setScanLocation:[scanner scanLocation]+1];
			}
			
		}
		
		self.index = index;
	}
	return self;
	
}

#define TEXT_TAG 1
#define MAX_TAG 2
#define MAX_LINES 4


+ (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier 
											rowHeight:(CGFloat)height 
										  screenWidth:(ScreenType)screenWidth 
										  rightMargin:(BOOL)rightMargin
												 font:(UIFont*)font
{
	
	CGFloat cellWidth = 0;
	
	if (rightMargin)
	{
		switch(screenWidth)
		{
			case WidthiPhoneNarrow:
				cellWidth = 285;  // 212;
				break;
			//case WidthiPhoneWide:
			//	cellWidth = 370.0;
			//	break;
			case WidthiPadNarrow:
				cellWidth = 720;
				break;
			case WidthiPadWide:
				cellWidth = 980; // 800.0; //730.0;
				break;
		}
	}
	else 
	{
		switch(screenWidth)
		{
		case WidthiPhoneNarrow:
			cellWidth = 305;  // 212;
			break;
			//case WidthiPhoneWide:
			//	cellWidth = 370.0;
			//	break;
		case WidthiPadNarrow:
			cellWidth = 750;
			break;
		case WidthiPadWide:
			cellWidth = 1010; // 800.0; //730.0;
			break;
		}
	}

	
	
	CGRect rect;
	
	rect = CGRectMake(0.0, 0.0, cellWidth, height);
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:rect reuseIdentifier:identifier] autorelease];
	
#define LEFT_COLUMN_OFFSET 10.0
	
#define MAX_LINE_SIDE COLOR_STRIPE_WIDTH
#define MAX_LINE_GAP  0
	

	int LEFT_COLUMN_WIDTH  = cellWidth - LEFT_COLUMN_OFFSET - MAX_LINE_SIDE * MAX_LINES - MAX_LINE_GAP * (MAX_LINES+1);
	// #define RIGHT_COLUMN_WIDTH 200.0 with disclosure
	int MAX_LINE_VOFFSET = (height - MAX_LINE_SIDE)/2;
	
	/*
	 Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
	 */
	UILabel *label;
	
	rect = CGRectMake(LEFT_COLUMN_OFFSET, 0 , LEFT_COLUMN_WIDTH, height);
	
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = TEXT_TAG;
	label.adjustsFontSizeToFitWidth = YES;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	label.textAlignment = UITextAlignmentLeft;
	// label.lineBreakMode = UILineBreakModeWordWrap; 
	// label.adjustsFontSizeToFitWidth = YES;
	label.numberOfLines = 1;
	label.font = font;
	label.backgroundColor = [UIColor clearColor];
	[label release];
	
	
	for (int i=0; i< MAX_LINES;i++)
	{
		rect = CGRectMake(LEFT_COLUMN_WIDTH + LEFT_COLUMN_OFFSET + MAX_LINE_GAP + (MAX_LINE_SIDE + MAX_LINE_GAP ) *i, MAX_LINE_VOFFSET , MAX_LINE_SIDE, MAX_LINE_SIDE);
		RouteColorBlobView *max = [[RouteColorBlobView alloc] initWithFrame:rect];
		max.tag = MAX_LINES+MAX_TAG-i-1;
		[cell.contentView addSubview:max];
		[max release];
	}
	
	return cell;	
}

+ (int)addLine:(UITableViewCell*)cell tag:(int)tag line:(RAILLINES)line lines:(RAILLINES)lines
{
	if (tag-MAX_TAG > MAX_LINES)
	{
		return tag;
	}
		
	RouteColorBlobView *view = (RouteColorBlobView *)[cell.contentView viewWithTag:tag];
	

	if (lines & line)
	{
		if ([view setRouteColorLine:line])
		{
			tag++;
		}
	}
	
	return tag;
}

+ (void)populateCell:(UITableViewCell*)cell station:(NSString *)station lines:(RAILLINES)lines
{
	// [self label:cell tag:TEXT_TAG].text = station;
	
	int tag = MAX_TAG;
	
	UILabel *label = (UILabel*)[cell.contentView viewWithTag:TEXT_TAG];
	label.text = station;
	
	
	tag = [RailStation addLine:cell tag:tag line:kBlueLine		lines:lines];
	tag = [RailStation addLine:cell tag:tag line:kRedLine		lines:lines];
	tag = [RailStation addLine:cell tag:tag line:kYellowLine	lines:lines];
	tag = [RailStation addLine:cell tag:tag line:kGreenLine		lines:lines];
	tag = [RailStation addLine:cell tag:tag line:kWesLine		lines:lines];
	tag = [RailStation addLine:cell tag:tag line:kStreetcarLine lines:lines];
	
	for (; tag < MAX_TAG + MAX_LINES; tag++)
	{
		RouteColorBlobView *view = (RouteColorBlobView *)[cell.contentView viewWithTag:tag];
		view.hidden = YES;
	}
	
}



- (NSString*)stringToFilter
{
	return self.station;
}


@end
