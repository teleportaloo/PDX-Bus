//
//  RailStation.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/4/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RailStation.h"
#import "XMLStops.h"
#import "DebugLogging.h"
#import "RailMapView.h"
#import "TriMetRouteColors.h"
#import "RouteColorBlobView.h"
#import "AllRailStationView.h"

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
	return [self.station caseInsensitiveCompare:inStation.station];
}


+ (void)scannerInc:(NSScanner *)scanner 
{	
	if (![scanner isAtEnd])
	{
		scanner.scanLocation++;
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

- (NSString *)longDirectionFromTableName:(NSString *)dir
{
    static NSDictionary *names = nil;
    
    if (names == nil)
    {
        names = [[[NSDictionary alloc] initWithObjectsAndKeys:
                  NSLocalizedString(@"Northbound",           @"Train direction"),  @"N",
                  NSLocalizedString(@"Southbound",           @"Train direction"),  @"S",
                  NSLocalizedString(@"Eastbound",            @"Train direction"),  @"E",
                  NSLocalizedString(@"Westbound",            @"Train direction"),  @"W",
                  NSLocalizedString(@"Northeastbound",       @"Train direction"),  @"NE",
                  NSLocalizedString(@"Southeastbound",       @"Train direction"),  @"SE",
                  NSLocalizedString(@"Southwestbound",       @"Train direction"),  @"SW",
                  NSLocalizedString(@"Northwestbound",       @"Train direction"),  @"NW",
                  NSLocalizedString(@"MAX Northbound",       @"Train direction"),  @"MAXN",
                  NSLocalizedString(@"MAX Southbound",       @"Train direction"),  @"MAXS",
                  NSLocalizedString(@"WES Southbound",       @"Train direction"),  @"WESS",
                  NSLocalizedString(@"WES Both Directions",  @"Train direction"),  @"WESA",
                  nil] retain];
    }

    
    NSString * obj = [names objectForKey:dir];
    
    if (obj == nil)
    {
        obj = [dir stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    }
	return obj;
}

+ (NSString *)nameFromHotspot:(HOTSPOT *)hotspot
{
	NSScanner *scanner = [NSScanner scannerWithString:[NSString stringWithUTF8String:hotspot->action]];
	NSCharacterSet *colon = [NSCharacterSet characterSetWithCharactersInString:@":"];
	
	NSString *substr;
	NSString *stationName = @"";
	
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
				scanner.scanLocation++;
			}
			
			[scanner scanUpToCharactersFromSet:slash intoString:&locId];
			
			[self.dirList addObject:[self longDirectionFromTableName:dir]];
			[self.locList addObject:locId];
			
			if (![scanner isAtEnd])
			{
				scanner.scanLocation++;
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
										  screenWidth:(ScreenWidth)screenWidth 
										  rightMargin:(BOOL)rightMargin
												 font:(UIFont*)font
{
	
	CGFloat cellWidth = 0;
    
    if (screenWidth == WidthBigVariable || screenWidth == WidthSmallVariable)
    {
        CGRect bounds = [[[[UIApplication sharedApplication] delegate] window] bounds];
        screenWidth = bounds.size.width;
    }
	
	if (rightMargin)
	{
        cellWidth = screenWidth - 35;
	}
	else 
	{
        cellWidth = screenWidth - 15;
	}
    
	CGRect rect;
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
	
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
	label.textAlignment = NSTextAlignmentLeft;
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
	
	
	tag = [RailStation addLine:cell tag:tag line:kBlueLine          lines:lines];
	tag = [RailStation addLine:cell tag:tag line:kRedLine           lines:lines];
	tag = [RailStation addLine:cell tag:tag line:kYellowLine        lines:lines];
	tag = [RailStation addLine:cell tag:tag line:kGreenLine         lines:lines];
	tag = [RailStation addLine:cell tag:tag line:kWesLine           lines:lines];
	tag = [RailStation addLine:cell tag:tag line:kStreetcarALoop    lines:lines];
    tag = [RailStation addLine:cell tag:tag line:kStreetcarBLoop    lines:lines];
    tag = [RailStation addLine:cell tag:tag line:kStreetcarNsLine   lines:lines];
    tag = [RailStation addLine:cell tag:tag line:kOrangeLine        lines:lines];
	
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
