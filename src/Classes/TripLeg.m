//
//  TripLeg.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripLeg.h"
#import "RouteColorBlobView.h"
#import "DebugLogging.h"
#import "FormatDistance.h"

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
    self.order      = nil;
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
    UIFont *font = nil;
    
    CGRect bounds = [[[[UIApplication sharedApplication] delegate] window] bounds];
    
    if (bounds.size.width <= MaxiPhoneWidth)
    {
        font = [UIFont fontWithName:kFontName size:kTextViewFontSize];
    }
    else {
        font = [UIFont fontWithName:kFontName size:kTextViewLargeFontSize];
    }
    
    
    return font;
}

+ (UIFont*) getBoldBodyFont
{
    UIFont *font = nil;
    
    
    CGRect bounds = [[[[UIApplication sharedApplication] delegate] window] bounds];
    
    if (bounds.size.width <= MaxiPhoneWidth)
    {
        font = [UIFont fontWithName:kBoldFontName size:kTextViewFontSize];
    }
    else {
        font = [UIFont fontWithName:kBoldFontName size:kTextViewLargeFontSize];
    }
    
    
    return font;
}

#define LEFT_COLUMN_OFFSET  10.0
#define MODE_HEIGHT         24.0
#define MIN_LEFT_V_GAP      5.0
#define MIN_LEFT_V_MID      5.0
#define LEFT_V_GAP ((height - MODE_HEIGHT - TIME_HEIGHT) / 3.0)
#define COLUMN_GAP          3.0
#define MODE_FONT_SIZE      16.0
#define RIGHT_COLUMN_OFFSET 5.0
#define RIGHT_MARGIN        20.0

+ (CGFloat)bodyTextWidth:(ScreenInfo)screen
{
	return screen.appWinWidth - ([TripLeg modeTextWidthForScreenWidth:screen.screenWidth]+LEFT_COLUMN_OFFSET + COLUMN_GAP + RIGHT_MARGIN);
}

+ (CGFloat)modeTextWidthForScreenWidth:(ScreenWidth)screenWidth
{
	CGFloat width = 0;
	
    if (LargeScreenStyle(screenWidth))
    {
        width = 100;
    }
    else
    {
        width = 75;
    }
	return width;
}


+ (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier rowHeight:(CGFloat)height screenInfo:(ScreenInfo)screen
{
    
	CGFloat rightColumnWidth = [TripLeg bodyTextWidth:screen];
	CGRect rect;
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
	
	
	int leftColumnWidth  = [TripLeg modeTextWidthForScreenWidth:screen.screenWidth];
    
	
	/*
	 Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
	 */
	UILabel *label;
	
	rect = CGRectMake(LEFT_COLUMN_OFFSET, MIN_LEFT_V_MID   , leftColumnWidth, height- RIGHT_COLUMN_OFFSET * 2);
    
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = MODE_TAG;
	label.font = [TripLeg getBoldBodyFont];
	label.adjustsFontSizeToFitWidth = YES;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	label.textAlignment = NSTextAlignmentCenter;
	label.lineBreakMode = NSLineBreakByWordWrapping;
	label.numberOfLines = 0;
	label.backgroundColor = [UIColor clearColor];
	[label release];
	
	rect = CGRectMake(leftColumnWidth+LEFT_COLUMN_OFFSET + COLUMN_GAP, RIGHT_COLUMN_OFFSET, rightColumnWidth, height - RIGHT_COLUMN_OFFSET * 2);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = BODY_TAG;
	label.font = [TripLeg getBodyFont];
	label.adjustsFontSizeToFitWidth = NO;
	label.lineBreakMode = NSLineBreakByWordWrapping;
	label.textAlignment = NSTextAlignmentLeft;
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
	CGSize sz = [text sizeWithFont:[TripLeg getBodyFont] constrainedToSize:rect lineBreakMode:NSLineBreakByWordWrapping];
	
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
                
                if (self.from.thruRoute)
                {
                    self.from.displayModeText = @"Stay on board";
                    self.from.leftColor = [UIColor blackColor];
                    [text appendFormat:	@"Stay on board at %@, route changes to '%@'", self.from.xdescription, self.xname];
                }
                else
                {
                    [text appendFormat:				@"Board %@",self.xname];
                }
			}
			else
			{
                if (self.from.thruRoute)
                {
                    [text appendFormat:				@"%@ Stay on board %@,  route changes to '%@'", self.xstartTime,	self.from.xdescription, self.xname];
                }
                else
                {
                    [text appendFormat:				@"%@ Board %@",			self.xstartTime, self.xname];
                }
			}
		}
		else if (type == TripTextTypeMap)
		{
			int mins = [self.xduration intValue];
			
			if (mins > 0)
			{
				[text appendFormat:@"Walk %@ %@ ", [FormatDistance formatMiles:[self.xdistance doubleValue]], [self direction:self.xdirection]];
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
		else if (type == TripTextTypeClip)
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
                    [text appendFormat:@"Walk %@ %@ ", [FormatDistance formatMiles:[self.xdistance doubleValue]], [self direction:self.xdirection]];
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
                    if (self.to.thruRoute)
                    {
                        [text appendFormat:	@"%@ stay on board at %@", self.xendTime, [self mapLink:self.to.xdescription lat:self.to.xlat lng:self.to.xlon textType:type]];
                    }
                    else
                    {
                        [text appendFormat:	@"%@ get off at %@", self.xendTime, [self mapLink:self.to.xdescription lat:self.to.xlat lng:self.to.xlon textType:type]];
                    }
                    break;
				case TripTextTypeUI:
					self.to.displayTimeText = self.xendTime;
                    if (!self.to.thruRoute)
                    {
                        self.to.displayModeText = @"Deboard";
                        self.to.leftColor = [UIColor redColor];
                        [text appendFormat:	@"Get off at %@", self.to.xdescription];
                    }
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
            if (!self.to.thruRoute)
            {
                [text appendFormat:				@"<br><br>"];

            }
            else
            {
                text = [[[NSMutableString alloc] init] autorelease];
            }
            break;
        case TripTextTypeMap:
            if ([text length] != 0)
            {
                self.to.mapText = text;
            }
            break;
        
        case TripTextTypeClip:
            [text appendFormat:				@"\n"];
        case TripTextTypeUI:
            if (!self.to.thruRoute)
            {
                self.to.displayText = text;
            }
            break;
	}
	return text;
}

@end
