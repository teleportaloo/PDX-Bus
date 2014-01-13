//
//  TripLeg.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
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

#import "TripLeg.h"
#import "RouteColorBlobView.h"
#import "debug.h"

#define kTextViewFontSize		15.0
#define kTextViewLargeFontSize  20.0
#define kBoldFontName			@"Helvetica-Bold" //@"Arial-BoldMT"
#define kFontName				@"Helvetica"


@implementation TripLeg

@synthesize mode			= _mode;
@synthesize xdate			= _xdate;
@synthesize xstartTime		= _xstartTime;
@synthesize xendTime		= _xendTime;
@synthesize xduration		= _xduration;
@synthesize xdistance		= _xdistance;
@synthesize xnumber			= _xnumber;
@synthesize xinternalNumber = _xinternalNumber;
@synthesize xname			= _xname;
@synthesize xkey			= _xkey;
@synthesize xdirection		= _xdirection;
@synthesize xblock			= _xblock;
@synthesize from			= _from;
@synthesize to				= _to;
@synthesize legShape        = _legShape;

- (void)dealloc {
	self.mode		= nil;
	self.xdate		= nil;
	self.xstartTime	= nil;
	self.xendTime	= nil;
	self.xduration	= nil;
	self.xdistance	= nil;
	self.xnumber		= nil;
	self.xinternalNumber = nil;
	self.xname		= nil;
	self.xkey		= nil;
	self.xdirection	= nil;
	self.xblock		= nil;
	self.from		= nil;
	self.to			= nil;
	self.legShape   = nil;
	[super dealloc];
}


#define MODE_TAG 1
#define TIME_TAG  2
#define BODY_TAG  3
#define COLOR_STRIPE_TAG 4
#define ROW_HEIGHT kDepartureCellHeight

+ (UILabel*)label:(UITableViewCell*)cell tag:(NSInteger)tag
{
	return ((UILabel*)[cell.contentView viewWithTag:tag]);
}

+ (UIFont*) getBodyFont
{
	static UIFont *font = nil;
	
	if (font == nil)
	{
		CGRect bounds = [[UIScreen mainScreen] bounds];
		
		if (bounds.size.width <= kSmallestSmallScreenDimension)
		{
			font = [UIFont fontWithName:kFontName size:kTextViewFontSize];
		}
		else {
			font = [UIFont fontWithName:kFontName size:kTextViewLargeFontSize];
		}
	}
	
	return font;
}

+ (UIFont*) getBoldBodyFont
{
	static UIFont *font = nil;
	
	if (font == nil)
	{
		CGRect bounds = [[UIScreen mainScreen] bounds];
		
		if (bounds.size.width <= kSmallestSmallScreenDimension)
		{
			font = [UIFont fontWithName:kBoldFontName size:kTextViewFontSize];
		}
		else {
			font = [UIFont fontWithName:kBoldFontName size:kTextViewLargeFontSize];
		}
	}
	
	return font;
}

+ (CGFloat)bodyTextWidthForScreenWidth:(ScreenType)screenWidth
{
	CGFloat cellWidth = 0;
	
	switch(screenWidth)
	{
        default:
		case WidthiPhoneNarrow:
			cellWidth = 193;  // 212;
			break;
			//case WidthiPhoneWide:
			//	cellWidth = 370.0;
			//	break;
		case WidthiPadNarrow:
			cellWidth = 545;
			break;
		case WidthiPadWide:
			cellWidth = 805; // 800.0; //730.0;
			break;
	}
	
	return cellWidth;
}

+ (CGFloat)modeTextWidthForScreenWidth:(ScreenType)screenWidth
{
	CGFloat width = 0;
	
	switch(screenWidth)
	{
        default:
		case WidthiPhoneNarrow:
			width = 75;  // 212;
			break;
			//case WidthiPhoneWide:
			//	cellWidth = 370.0;
			//	break;
		case WidthiPadNarrow:
			width = 100; // 520.0; //480
			break;
		case WidthiPadWide:
			width = 100; // 800.0; //730.0;
			break;
	}
	
	return width;
}


+ (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier rowHeight:(CGFloat)height screenWidth:(ScreenType)screenWidth
{
    
	CGFloat width = [TripLeg bodyTextWidthForScreenWidth:screenWidth];
	CGRect rect;
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
	
#define LEFT_COLUMN_OFFSET 10.0
	
	int LEFT_COLUMN_WIDTH  = [TripLeg modeTextWidthForScreenWidth:screenWidth];
    // #define RIGHT_COLUMN_WIDTH 200.0 with disclosure
#define RIGHT_COLUMN_WIDTH (width)
    
    
#define MODE_HEIGHT		24.0
#define MIN_LEFT_V_GAP  5.0
#define MIN_LEFT_V_MID	5.0
	
#define LEFT_V_GAP ((height - MODE_HEIGHT - TIME_HEIGHT) / 3.0)
#define COLUMN_GAP	3.0
    
#define MODE_FONT_SIZE 16.0
	
#define RIGHT_COLUMN_OFFSET 5.0
	
    
	
	/*
	 Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
	 */
	UILabel *label;
	
	rect = CGRectMake(LEFT_COLUMN_OFFSET, MIN_LEFT_V_MID   , LEFT_COLUMN_WIDTH, height- RIGHT_COLUMN_OFFSET * 2);
    
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = MODE_TAG;
	label.font = [TripLeg getBoldBodyFont];
	label.adjustsFontSizeToFitWidth = YES;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	label.textAlignment = UITextAlignmentCenter;
	label.lineBreakMode = UILineBreakModeWordWrap;
	label.numberOfLines = 0;
	label.backgroundColor = [UIColor clearColor];
	[label release];
	
	rect = CGRectMake(LEFT_COLUMN_WIDTH+LEFT_COLUMN_OFFSET + COLUMN_GAP, RIGHT_COLUMN_OFFSET, RIGHT_COLUMN_WIDTH, height - RIGHT_COLUMN_OFFSET * 2);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = BODY_TAG;
	label.font = [TripLeg getBodyFont];
	label.adjustsFontSizeToFitWidth = NO;
	label.lineBreakMode = UILineBreakModeWordWrap;
	label.textAlignment = UITextAlignmentLeft;
	label.numberOfLines = 0;
	label.backgroundColor = [UIColor clearColor];
	
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	[label release];
    
	rect = CGRectMake(3.0, 0, COLOR_STRIPE_WIDTH, height);
	RouteColorBlobView *colorStripe = [[RouteColorBlobView alloc] initWithFrame:rect];
	colorStripe.tag = COLOR_STRIPE_TAG;
	[cell.contentView addSubview:colorStripe];
	[colorStripe release];
    
	return cell;
}

+ (CGFloat)getTextHeight:(NSString *)text width:(CGFloat)width
{
	CGSize rect = CGSizeMake(width, MAXFLOAT);
	CGSize sz = [text sizeWithFont:[TripLeg getBodyFont] constrainedToSize:rect lineBreakMode:UILineBreakModeWordWrap];
	
	//CGSize sz = [text sizeWithFont:[TripLeg getBodyFont] forWidth:width lineBreakMode:UILineBreakModeWordWrap];
	
	DEBUG_LOG(@"Text: %@ height: %f width %f return %f\n", text, sz.height, width, MAX( sz.height +RIGHT_COLUMN_OFFSET * 2,  24.0 * 2 + 10));
	return MAX( sz.height +RIGHT_COLUMN_OFFSET * 2,  24.0 * 2 + 10);
}

+ (void)populateCell:(UITableViewCell*)cell
				body:(NSString *)body
				mode:(NSString *)mode
				time:(NSString *)time
		   leftColor:(UIColor *)col
			   route:(NSString *)route
{
	if (col == nil)
	{
		col = [UIColor grayColor];
	}
	
	if (time == nil)
	{
		[self label:cell tag:MODE_TAG].text = mode;
	}
	else
	{
		[self label:cell tag:MODE_TAG].text = [NSString stringWithFormat:@"%@\n%@", mode, time];
	}
	[self label:cell tag:BODY_TAG].text = body;
    [self label:cell tag:MODE_TAG].textColor = col;
	DEBUG_LOG(@"Width: %f\n", [self label:cell tag:BODY_TAG].bounds.size.width);
	DEBUG_LOG(@"Text: %@\n", body);
	
	[cell setAccessibilityLabel:[NSString stringWithFormat:@"%@, %@", [self label:cell tag:MODE_TAG].text, body]];
    
	RouteColorBlobView *colorStripe = (RouteColorBlobView*)[cell.contentView viewWithTag:COLOR_STRIPE_TAG];
	[colorStripe setRouteColor:route];
	
    //	DEBUG_LOG(@"Route: %@  body %@ r %f g %f b %f\n", route, body, colorStripe.red, colorStripe.green, colorStripe.blue);
	
}



typedef struct strmap {
	NSString *shortname;
	NSString *longname;
} strmap;

static strmap dirmap [] =
{
    { @"n", @"north" },
    { @"s", @"south" },
    { @"e", @"east"  },
    { @"w", @"west"  },
    { @"ne", @"northeast" },
    { @"se", @"southeast" },
    { @"sw", @"southwest" },
    { @"nw", @"northwest" },
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
	return dir;
}

- (NSString*)mapLink:(NSString *)desc lat:(NSString *)lat lng:(NSString *)lng textType:(TripTextType)type
{
	if (lat == nil || type != TripTextTypeHTML)
	{
		return desc;
	}
	return [NSString stringWithFormat:@"<a href=\"http://map.google.com/?q=location@%@,%@\">%@</a>",
			lat, lng, desc];
}

- (NSString *)miles:(NSString *)miles
{
	float dist = [miles floatValue];
	NSString *english = nil;
	
	
	if (dist > 0.5)
	{
		english = [NSString stringWithFormat:@"%@ miles", miles];
	}
	else {
		english = [NSString stringWithFormat:@"%d yards", (int)((dist * (float)1760.0)+0.5)];
	}
    
    
	NSString *metric = nil;
	
	dist = dist * 1609.344;
	
	if (dist >= 1000.0)
	{
		metric = [NSString stringWithFormat:@"%.2f km", dist/1000];
	}
	else
	{
		metric = [NSString stringWithFormat:@"%.0f meters", dist+0.5];
	}
	
	return [NSString stringWithFormat:@"%@ (%@)", english, metric];
}

- (NSString*)createFromText:(bool)first textType:(TripTextType)type;
{
	NSMutableString * text  = [[[ NSMutableString alloc] init] autorelease];
	
	if (self.from !=nil)
	{
		if (![self.mode isEqualToString:kModeWalk])
		{
			if (type == TripTextTypeUI)
			{
                
				self.from.displayTimeText = self.xstartTime;
				self.from.leftColor = [UIColor blueColor];
                
                // Bug in response can give streetcar data as MAX Mode.
				
				if ([self.mode isEqualToString:kModeBus])
				{
					self.from.displayModeText = [NSString stringWithFormat:@"Bus %@", self.xnumber];
				}
				else if ([self.mode isEqualToString:kModeMax])
				{
					self.from.displayModeText = @"MAX";
				}
				else if ([self.mode isEqualToString:kModeSc])
                {
                    self.from.displayModeText = @"Streetcar";
                }
                else
				{
					self.from.displayModeText = self.xnumber;
				}
				[text appendFormat:				@"Board %@",self.xname];
				
				
			}
			else
			{
				[text appendFormat:				@"%@ Board %@",			self.xstartTime, self.xname];
			}
		}
		else if (type == TripTextTypeMap)
		{
			int mins = [self.xduration intValue];
			
			if (mins > 0)
			{
				[text appendFormat:@"Walk %@ %@ ", [self miles:self.xdistance], [self direction:self.xdirection]];
			}
			else
			{
				[text appendFormat:@"Walk %@ ",  [self direction:self.xdirection]];
			}
			
			if (mins == 1)
			{
				[text appendString:@"for 1 min "];
			}
			else if (mins > 1)
			{
				[text appendFormat:@"for %d mins", mins];
			}
		}
	}
	
	while ([text replaceOccurrencesOfString:@"  "
								 withString:@" "
									options:NSLiteralSearch
									  range:NSMakeRange(0, [text length])] > 0)
	{
		;
	}
	
	if ([text length] !=0)
	{
		if (type == TripTextTypeHTML)
		{
			[text appendString:@"<br><br>"];
		}
		else
		{
			[text appendString:@"\n"];
		}
	}
	
	switch (type)
	{
		case TripTextTypeClip:
		case TripTextTypeHTML:
			break;
		case TripTextTypeMap:
			if ([text length] != 0)
			{
				self.from.mapText = text;
			}
			break;
		case TripTextTypeUI:
			if ([text length] != 0)
			{
				self.from.displayText = text;
			}
			break;
	}
	return text;
}



- (NSString *)createToText:(bool)last textType:(TripTextType)type;
{
	NSMutableString * text  = [[[ NSMutableString alloc] init] autorelease];
	if (self.to!=nil)
	{
		if ([self.mode isEqualToString:kModeWalk])
		{
			if (type == TripTextTypeMap)
			{
				if (last)
				{
					[text appendFormat:	@"Destination"];
				}
			}
			else  // type is not map
			{
				if (type == TripTextTypeUI)
				{
					self.to.displayModeText = self.mode;
					self.to.leftColor = [UIColor purpleColor];
				}
				int mins = [self.xduration intValue];
                
				if (mins > 0)
				{
					[text appendFormat:@"Walk %@ %@ ", [self miles:self.xdistance], [self direction:self.xdirection]];
				}
				else // multiple mins
				{
					[text appendFormat:@"Walk %@ ",  [self direction:self.xdirection]];
					self.to.displayModeText = @"Short\nWalk";
				}
				
                
				if (mins == 1)
				{
					if (type == TripTextTypeUI)
					{
						self.to.displayTimeText = @"1 min";
					}
					else
					{
						[text appendFormat:@"for 1 minute "];
					}
				}
				else if (mins > 1)
				{
					if (type == TripTextTypeUI)
					{
						self.to.displayTimeText = [NSString stringWithFormat:@"%d mins", mins];
					}
					else
					{
						[text appendFormat:@"for %d minutes ", mins];
					}
				}
				
				
				[text appendFormat:@"%@%@",
                 @"to ",
                 [self mapLink:self.to.xdescription lat:self.to.xlat lng:self.to.xlon textType:type]];
			}
			
		}
		else // mode is not to walk
		{
			switch (type)
			{
				case TripTextTypeMap:
					if (last)
					{
						[text appendFormat:	@"%@ get off at %@", self.xendTime, self.to.xdescription];
					}
					break;
				case TripTextTypeHTML:
				case TripTextTypeClip:
					[text appendFormat:	@"%@ get off at %@", self.xendTime, [self mapLink:self.to.xdescription lat:self.to.xlat lng:self.to.xlon textType:type]];
					break;
				case TripTextTypeUI:
					self.to.displayTimeText = self.xendTime;
					self.to.displayModeText = @"Deboard";
					self.to.leftColor = [UIColor redColor];
					[text appendFormat:	@"Get off at %@", self.to.xdescription];
					break;
			}
		}
        
		
		if (self.to.xstopId != nil)
		{
			switch (type)
			{
				case TripTextTypeMap:
					break;
				case TripTextTypeUI:
				case TripTextTypeClip:
					[text appendFormat:@" (ID %@)", [self.to stopId]];
					break;
				case TripTextTypeHTML:
					[text appendFormat:@" (ID <a href=\"pdxbus://%@?%@/\">%@</a>)",
                     [self.to.xdescription stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                     [self.to stopId], [self.to stopId]];
					break;
			}
		}
	}
	
    
	switch (type)
	{
        case TripTextTypeHTML:
            [text appendFormat:				@"<br><br>"];
            break;
        case TripTextTypeMap:
            if ([text length] != 0)
            {
                self.to.mapText = text;
            }
            break;
        case TripTextTypeUI:
        case TripTextTypeClip:
            [text appendFormat:				@"\n"];
            self.to.displayText = text;
            break;
	}
	return text;
}

@end
