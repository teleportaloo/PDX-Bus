//
//  Hotspots.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/4/10.
//  Copyright 2010 Intel. All rights reserved.
//

#import "Hotspots.h"

static HOTSPOT hotSpotRegions[MAXHOTSPOTS];
int nHotSpots = 0;

@implementation Hotspot

@property (nonatomic) (int)index;
@property (readonly) (char)type;
@property (readonly) (HOTSPOT*)hotspot;

@synthesize index = _index;
@dynamic type;
@dynamic hotspot;

- (HOTSPOT*)hotspot
{
	return hotSpotRegions + self.index;
}

- (char)type
{
	return [self hotspot].action[0];
}

+ (Hotspot*)createFromHotspot:(int)index
{
	NSScanner *scanner = [NSScanner scannerWithString:[NSString stringWithUTF8String:hotSpotRegions[index].action]];
	NSCharacterSet *colon = [NSCharacterSet characterSetWithCharactersInString:@":"];
	NSCharacterSet *comma = [NSCharacterSet characterSetWithCharactersInString:@","];
	NSCharacterSet *slash = [NSCharacterSet characterSetWithCharactersInString:@"/"];
	
	NSString *substr;
	NSString *stationName;
	NSString *wikiLink;
	
	[scanner scanUpToCharactersFromSet:colon intoString:&substr];
	
	if (substr == nil)
	{
		return nil;
	}
	
	switch (*[substr UTF8String])	
	{
		case kLinkTypeNorth:
		case kLinkType1:
		case kLinkType2:
		case kLinkType3:
		case kLinkTypeHttp:
			{
				Hotspot * hotspot = [[[Hotspot alloc] init] autorelease];
				hotspot.index = i;
				return hotspot;
			}
			break;
		case kLinkTypeWiki:
		{
			easterEgg = EasterEggStart;
			
			[self scannerInc:scanner];
			//[self.hotSpots selectItem:i];
			
			wikiLink = [url substringFromIndex:[scanner scanLocation]];
			
			WebViewController *webPage = [[WebViewController alloc] init];
			
			
			[webPage setURLmobile:[NSString stringWithFormat:@"http://en.m.wikipedia.org/wiki/%@", [wikiLink stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ] 
			 
							 full:[NSString stringWithFormat:@"http://en.wikipedia.org/wiki/%@", [wikiLink stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ] 
							title:@"Wikipedia"];
			
			if (self.callback)
			{
				webPage.whenDone = [self.callback getController];
			}
			[[self navigationController] pushViewController:webPage animated:YES];
			[webPage release];
			break;
		}
		case kLinkTypeDir:
		{
			easterEgg = EasterEggStart;
			//[self.hotSpots selectItem:i];
			
			[self scannerInc:scanner];
			[self nextSlash:scanner intoString:&substr];
			[self nextSlash:scanner intoString:&substr];
			// [self nextSlash:scanner intoString:&substr];
			[self nextSlash:scanner intoString:&stationName];
			
			
			DirectionView *dirView = [[DirectionView alloc] init];
			dirView.callback = self.callback;
			[dirView fetchDirectionsInBackground:self.backgroundTask route:stationName];
			[dirView release];
			break;
		}
		case kLinkTypeStop:
		{
			easterEgg = EasterEggStart;
			//[self.hotSpots selectItem:i];
			
			
			[self scannerInc:scanner];
			[self nextSlash:scanner intoString:&stationName];
			[self nextSlash:scanner intoString:&wikiLink];
			
			
			RailStationTableView *railView = [[RailStationTableView alloc] init];
			railView.station = [stationName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			railView.callback = self.callback;
			railView.from = self.from;
			railView.wikiLink = [wikiLink stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			railView.locList = [[[NSMutableArray alloc] init] autorelease];
			railView.dirList = [[[NSMutableArray alloc] init] autorelease];
			railView.locationsDb = self.locationsDb;
			
			if (!self.hotSpots.hidden)
			{
				railView.map = self;
			}
			
			
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
				
				[railView.dirList addObject:[self direction:dir]];
				[railView.locList addObject:locId];
				
				if (![scanner isAtEnd])
				{
					[scanner setScanLocation:[scanner scanLocation]+1];
				}
				
			}
			
			[[self navigationController] pushViewController:railView animated:YES];
			[railView release];
			break;
		}
			
	}
	return YES;
}
}


+ (Hotspot*)matchTapX:(CGFloat)x Y:(CGFloat)y;

@end
