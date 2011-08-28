//
//  XMLTrips.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/27/09.
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

#import "XMLTrips.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "ScreenConstants.h"
#import "UserFaves.h"
#import "debug.h"
#import "TriMetRouteColors.h"
#import "RouteColorBlobView.h"




#define kTextViewFontSize		15.0
#define kTextViewLargeFontSize  20.0
#define kBoldFontName			@"Helvetica-Bold" //@"Arial-BoldMT"
#define kFontName				@"Helvetica"

#define kDictEndPointUseCurrentLocation @"useCurrentLocation"
#define kDictEndPointLocationDec		@"locationDesc"
#define kDictEndPointAddtionalInfo		@"additionalInfo"
#define kDictUserRequestTripMode		@"tripMode"
#define kDictUserRequestTripMin			@"tripMin"
#define kDictUserRequestMaxItineraries	@"maxItineraries"
#define kDictUserRequestWalk			@"walk"
#define kDictUserRequestFromPoint		@"fromPoint"
#define kDictUserRequestToPoint			@"toPoint"
#define kDictUserRequestDateAndTime		@"dateAndTime"
#define kDictUserRequestArrivalTime		@"arrivalTime"
#define kDictUserRequestTimeChoice		@"timeChoice"
#define kDictEndPointLocationLat		@"lat"
#define kDictEndPointLocationLng		@"lng"


@implementation TripLegEndPoint

@synthesize xlat			= _xlat;
@synthesize xlon			= _xlon;
@synthesize xdescription	= _xdescription;
@synthesize xstopId			= _xstopId;
@synthesize displayText		= _displayText;
@synthesize mapText			= _mapText;
@synthesize index			= _index;
@synthesize callback		= _callback;
@synthesize displayModeText = _displayModeText;
@synthesize displayTimeText = _displayTimeText;
@synthesize leftColor       = _leftColor;
@synthesize xnumber			= _xnumber;

- (void)dealloc {
	
	self.xlat			= nil;
	self.xlon			= nil;
	self.xdescription	= nil;
	self.xstopId		= nil;
	self.displayText    = nil;
	self.mapText		= nil;
	self.callback		= nil;
	self.displayModeText = nil;
	self.displayTimeText = nil;
	self.leftColor		 = nil;
	self.xnumber		 = nil;
	[super dealloc];
}	

- (id)copyWithZone:(NSZone *)zone
{
	TripLegEndPoint *ep = [[ TripLegEndPoint allocWithZone:zone] init];
	
	ep.xlat				= [self.xlat			copyWithZone:zone];
	ep.xlon				= [self.xlon			copyWithZone:zone];
	ep.xdescription		= [self.xdescription	copyWithZone:zone];
	ep.xstopId			= [self.xstopId			copyWithZone:zone];
	ep.displayText		= [self.displayText		copyWithZone:zone];
	ep.displayText		= [self.displayText		copyWithZone:zone];
	ep.mapText			= [self.mapText			copyWithZone:zone];
	ep.xnumber			= [self.xnumber			copyWithZone:zone];
	ep.callback			= self.callback;
	ep.displayModeText	= [self.displayModeText copyWithZone:zone];
	ep.displayTimeText	= [self.displayTimeText copyWithZone:zone];
	ep.leftColor		= self.leftColor;
	ep.index			= self.index;
	
	return ep;
}

#pragma mark Map callbacks

- (NSString*)stopId
{
	if (self.xstopId)
	{
		return [NSString stringWithFormat:@"%d", [self.xstopId	intValue]];
	}
	return nil;
}

- (bool)mapTapped:(id<BackgroundTaskProgress>) progress
{
	if (self.callback != nil)
	{
		[self.callback chosenEndpoint:self];
		
		return YES;
	}
	return NO;
}

- (NSString *)tapActionText
{
	if (self.callback != nil)
	{
		return @"Choose this stop";
	}
	else {
		return @"Show arrivals";
	}

}

- (MKPinAnnotationColor) getPinColor
{
	return MKPinAnnotationColorGreen;
}

- (NSString *)mapStopId
{
	return [self stopId];
}

- (CLLocationCoordinate2D)coordinate
{
	CLLocationCoordinate2D pos;
	
	pos.latitude = [self.xlat doubleValue];
	pos.longitude = [self.xlon doubleValue];
	return pos;
}

- (bool)mapDisclosure
{
	return self.xstopId!=nil || self.callback!=nil;
}

- (NSString *)title
{
	return self.xdescription;
}

- (NSString *)subtitle
{
	if (self.mapText != nil)
	{
		return [NSString stringWithFormat:@"%d: %@", self.index, self.mapText];
	}
	return nil;
}



@end

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
	
	rect = CGRectMake(0.0, 0.0, width + (320.0 - 212.0), height);
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:rect reuseIdentifier:identifier] autorelease];
	
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
				
				if ([self.mode isEqualToString:kModeBus])
				{
					self.from.displayModeText = [NSString stringWithFormat:@"Bus %@", self.xnumber];
				}
				else if ([self.mode isEqualToString:kModeMax])
				{
					self.from.displayModeText = @"MAX";
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

@implementation TripItinerary

@synthesize xdate				= _xdate;
@synthesize xstartTime			= _xstartTime;
@synthesize xendTime			= _xendTime;
@synthesize xduration			= _xduration;
@synthesize xdistance			= _xdistance;
@synthesize xmessage			= _xmessage;
@synthesize xnumberOfTransfers	= _xnumberOfTransfers;
@synthesize xnumberofTripLegs	= _xnumberofTripLegs;
@synthesize xwalkingTime		= _xwalkingTime;
@synthesize xtransitTime		= _xtransitTime;
@synthesize xwaitingTime		= _xwaitingTime;
@synthesize legs				= _legs;
@synthesize displayEndPoints    = _displayEndPoints;
@synthesize fare			    = _fare;
@synthesize travelTime          = _travelTime;
@synthesize startPoint			= _startPoint;

- (void)dealloc {
	self.xdate					= nil;
	self.xstartTime				= nil;
	self.xendTime				= nil;
	self.xduration				= nil;
	self.xdistance				= nil;
	self.xwalkingTime			= nil;
	self.xtransitTime			= nil;
	self.xwaitingTime			= nil;
	self.xnumberOfTransfers		= nil;
	self.xnumberofTripLegs		= nil;
	self.legs					= nil;
	self.xmessage				= nil;
	self.fare					= nil;
	self.travelTime				= nil;
	self.xnumberOfTransfers     = nil;
	self.xnumberofTripLegs      = nil;
	[super dealloc];
}

- (id)init {
	if ((self = [super init]))
	{
		self.legs = [[[ NSMutableArray alloc ] init] autorelease];
		
		
	}
	return self;
}

- (bool)hasFare
{
	return self.fare != nil && [self.fare length]!=0;
}

- (TripLeg*) getLeg:(int)item
{
	return [self.legs objectAtIndex:item];
}

- (NSString *)getShortTravelTime
{
	
	NSMutableString *strTime = [[[NSMutableString alloc] init] autorelease];
	int t = [self.xduration intValue];
	int h = t/60;
	int m = t%60;
		
	[strTime appendFormat:@"Travel time: %d:%02d", h, m];
	return strTime;
}


- (NSString *)mins:(int)t
{
	if (t==1)
	{
		return @"1 min";
	}
	return [NSString stringWithFormat:@"%d mins", t];
}

- (NSString *)getTravelTime
{
	if (self.travelTime == nil)
	{
		NSMutableString *strTime = [[[NSMutableString alloc] init] autorelease];
		int t = [self.xduration intValue];
		
		[strTime appendString:[self mins:t]];
		

		bool inc = false;
		
		if (self.xwalkingTime != nil)
		{
			int walking = [self.xwalkingTime intValue];
		
			if (walking > 0)
			{
				[strTime appendFormat: @", including %@ walking", [self mins:walking]];
				inc = true;
			}
		}
		
		if (self.xwaitingTime !=nil)
		{
			int waiting = [self.xwaitingTime intValue];
		
			if (waiting > 0)
			{
				if (!inc)
				{
					[strTime appendFormat: @", including %@ waiting", [self mins:waiting]];
				}
				else
				{
					[strTime appendFormat: @" and %@ waiting", [self mins:waiting]];
				}
			}
		}
			
		[strTime appendString: @"."];
				
		
		self.travelTime = strTime;
	}
	return self.travelTime;
	
}

- (int)legCount
{
	if (self.legs)
	{
		return [self.legs count];
	}
	return 0;
}

- (NSString *)startPointText:(TripTextType)type
{
	NSMutableString * text  = [[ NSMutableString alloc] init];
	
	TripLeg * firstLeg = nil;
	TripLegEndPoint * firstPoint = nil;
	
	if ([self.legs count] > 0)
	{
		firstLeg = [self.legs objectAtIndex:0];
		firstPoint = [firstLeg from];
	}
	else
	{
		[text release];
		return nil;
	}
	
	if (self.startPoint == nil)
	{
		self.startPoint = [firstPoint copy];
	}
	
	if (firstPoint!=nil && type != TripTextTypeMap)
	{
		bool nearTo = [firstPoint.xdescription hasPrefix:kNearTo];
		
		if (type == TripTextTypeUI)
		{
			self.startPoint.displayModeText = @"Start";
			[text appendFormat:@"%@%@", nearTo ? @"" : @"Start at ", firstPoint.xdescription];
		}
		else if (type == TripTextTypeHTML && firstPoint.xlon!=nil)
		{
			[text appendFormat:@"%@<a href=\"http://map.google.com/?q=location@%@,%@\">%@</a>", 
						nearTo ? @"Start " : @"Start at ",
						firstPoint.xlat, firstPoint.xlon,  firstPoint.xdescription];
		}
		else
		{
			[text appendFormat:@"%@%@", nearTo ? @"Starting " : @"Starting at ",firstPoint.xdescription];
		}
	}
	
	if (self.startPoint.xstopId !=nil)
	{
		if (type == TripTextTypeHTML)
		{
			[text appendFormat:@" (ID <a href=\"pdxbus://%@?%@/\">%@</a>)", 
			 [self.startPoint.xdescription	stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
			 [self.startPoint stopId], [firstPoint stopId]];
		}
		else
		{
			[text appendFormat:@" (ID %@)", [self.startPoint stopId]];
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
				self.startPoint.mapText = text;
			}
			break;
		case TripTextTypeUI:
		case TripTextTypeClip:
			[text appendFormat:				@"\n"];
			self.startPoint.displayText = text;
			break;
	}
	[text autorelease];
	return text;
}

@end
 
@implementation TripEndPoint
@synthesize locationDesc			= _locationDesc;
@synthesize currentLocation			= _currentLocation;
@synthesize useCurrentLocation		= _useCurrentLocation;
@synthesize additionalInfo			= _additionalInfo;

- (void)dealloc
{
	self.locationDesc = nil;
	self.currentLocation = nil;
	self.additionalInfo = nil;

	[super dealloc];
}

- (NSString *)toQuery:(NSString *)toOrFrom
{
	NSMutableString *ret = [[[ NSMutableString alloc ] init] autorelease];
	
		
	NSString * desc = self.locationDesc;
		
	if (desc == nil)
	{
		desc = kAcquiredLocation;
	}
		
	NSMutableString *ms = [[NSMutableString alloc] init];
		
	[ms appendString:[desc stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		
		
	[ms replaceOccurrencesOfString:@"/" 
								withString:@"%2F" 
								   options:NSLiteralSearch 
									 range:NSMakeRange(0, [ms length])]; 
		
		
	[ms replaceOccurrencesOfString:@"&" 
							withString:@"%26" 
							   options:NSLiteralSearch 
								 range:NSMakeRange(0, [ms length])]; 
		
	[ret appendFormat:@"%@Place=%@",toOrFrom, ms];
	[ms release];

	if (self.currentLocation != nil)
	{
		[ret appendFormat:@"&%@Coord=%f,%f", toOrFrom, self.currentLocation.coordinate.longitude, self.currentLocation.coordinate.latitude];	
	}
	return ret;
}




- (NSDictionary *)toDictionary
{
	NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
	
	
	[dict setObject:[[[NSNumber alloc] initWithBool:self.useCurrentLocation] autorelease] 
			 forKey:kDictEndPointUseCurrentLocation];
	
	if (self.locationDesc != nil)
	{
		[dict setObject:self.locationDesc forKey:kDictEndPointLocationDec];
	}
	
	if (self.additionalInfo != nil)
	{
		[dict setObject:self.additionalInfo forKey:kDictEndPointAddtionalInfo];
	}
	
	if (self.currentLocation!=nil)
	{
		[dict setObject:[[[NSNumber alloc] initWithDouble:self.currentLocation.coordinate.latitude] autorelease]
				 forKey:kDictEndPointLocationLat];
		[dict setObject:[[[NSNumber alloc] initWithDouble:self.currentLocation.coordinate.longitude] autorelease]
				 forKey:kDictEndPointLocationLng];
		
	}
	return dict;
	
}

- (NSNumber *)forceNSNumber:(NSObject*)obj
{
	if (obj && [obj isKindOfClass:[NSNumber class]])
	{
		return (NSNumber *)obj;
	}
	return nil;
	
}


- (NSString *)forceNSString:(NSObject*)obj
{
	if (obj && [obj isKindOfClass:[NSString class]])
	{
		return (NSString*)obj;
	}
	return nil;
	
}
- (bool)fromDictionary:(NSDictionary *)dict
{
	if (dict == nil)
	{
		return false;
	}
	
	
	NSNumber *useCurretLocation = [self forceNSNumber:[dict objectForKey:kDictEndPointUseCurrentLocation]];
	
	if (useCurretLocation)
	{
		self.useCurrentLocation = [useCurretLocation boolValue];
	}
	else {
		self.useCurrentLocation = false;
	}

	self.locationDesc = [self forceNSString:[dict objectForKey:kDictEndPointLocationDec]];
	self.additionalInfo = [self forceNSString:[dict objectForKey:kDictEndPointAddtionalInfo]];
	
	
	NSNumber *lat = [self forceNSNumber:[dict objectForKey:kDictEndPointLocationLat]];
	NSNumber *lng = [self forceNSNumber:[dict objectForKey:kDictEndPointLocationLng]];
		
	if (lat!=nil && lng!=nil)
	{
		self.currentLocation = [[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:[lng doubleValue]];
	}
	

	return YES;
}

- (bool)equalsTripEndPoint:(TripEndPoint *)endPoint
{
	return self.useCurrentLocation == endPoint.useCurrentLocation
		&& ( self.useCurrentLocation 
			|| (self.locationDesc == nil && endPoint.locationDesc == nil)
			|| (self.locationDesc != nil && [self.locationDesc isEqualToString:endPoint.locationDesc]));
}

- (id)initFromDict:(NSDictionary *)dict
{
	if ((self = [super init]))
	{
		[self fromDictionary:dict];
	}
	return self;
	
}

- (NSString *)displayText
{
	if (self.useCurrentLocation)
	{
		return kAcquiredLocation;
	}
	return self.locationDesc;
}

- (NSString *)userInputDisplayText
{
	if (self.useCurrentLocation)
	{
		return @"Current Location (GPS)";
	}
	
	if (self.locationDesc == nil)
	{
		return @"<touch to choose location>";
	}
	
	for (int i=0; i<self.locationDesc.length; i++)
	{
		unichar c = [self.locationDesc characterAtIndex:i];
		
		if ((c > '9' || c <'0') && c!=' ')
		{
			return self.locationDesc;
		}
	}
	
	if (self.additionalInfo)
	{
		return [NSString stringWithFormat:@"%@ - Stop ID %@",  self.additionalInfo, self.locationDesc];
	}
	return [NSString stringWithFormat:@"Stop ID %@", self.locationDesc];
}

@end

@implementation TripUserRequest

@synthesize fromPoint		= _fromPoint;
@synthesize toPoint			= _toPoint;
@synthesize tripMode		= _tripMode;
@synthesize tripMin			= _tripMin;
@synthesize maxItineraries	= _maxItineraries;
@synthesize walk			= _walk;
@synthesize dateAndTime		= _dateAndTime;
@synthesize arrivalTime		= _arrivalTime;
@synthesize timeChoice	    = _timeChoice;

- (void)dealloc {
	self.fromPoint = nil;
	self.toPoint   = nil;
	self.dateAndTime = nil;
	[super dealloc];
}

#pragma mark Data helpers

- (NSString *)getMode
{
	switch (self.tripMode)
	{
		case TripModeBusOnly:
			return @"Bus only";
		case TripModeTrainOnly:
			return @"Train only";
		case TripModeAll:
			return @"Bus or train";
			
	}
	return @"";
}

- (NSString *)getMin
{
	switch (self.tripMin)
	{
		case TripMinQuickestTrip:
			return @"Quickest trip";
		case TripMinShortestWalk:
			return @"Shortest walk";
		case TripMinFewestTransfers:
			return @"Fewest transfers";
	}
	return @"T";
	
}

- (NSString *)minToString
{
	switch (self.tripMin)
	{
		case TripMinQuickestTrip:
			return @"T";
		case TripMinShortestWalk:
			return @"W";
		case TripMinFewestTransfers:
			return @"X";
	}
	return @"T";
	
}


- (NSString *)modeToString
{
	switch (self.tripMode)
	{
		case TripModeBusOnly:
			return @"B";
		case TripModeTrainOnly:
			return @"T";
		case TripModeAll:
			return @"A";
	}
	return @"A";
	
}

- (NSMutableDictionary *)toDictionary
{
	NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
	
	if (self.fromPoint)
	{
		[dict setObject:[self.fromPoint toDictionary]
				 forKey:kDictUserRequestFromPoint];
	}
	
	if (self.toPoint)
	{
		[dict setObject:[self.toPoint toDictionary]
				 forKey:kDictUserRequestToPoint];
	}
	
	[dict setObject:[[[NSNumber alloc] initWithInt:self.tripMode] autorelease]
			 forKey:kDictUserRequestTripMode];
	
	[dict setObject:[[[NSNumber alloc] initWithInt:self.tripMin] autorelease]
			 forKey:kDictUserRequestTripMin];
	
	[dict setObject:[[[NSNumber alloc] initWithInt:self.maxItineraries] autorelease]
			 forKey:kDictUserRequestMaxItineraries];
	
	[dict setObject:[[[NSNumber alloc] initWithFloat:self.walk] autorelease]
			 forKey:kDictUserRequestWalk];
	
	if (self.dateAndTime)
	{
		[dict setObject:[[[NSNumber alloc] initWithBool:self.arrivalTime] autorelease]
			 forKey:kDictUserRequestArrivalTime];
	
		[dict setObject:self.dateAndTime
			 forKey:kDictUserRequestDateAndTime];
	}
	
	[dict setObject:[[[NSNumber alloc] initWithFloat:self.timeChoice] autorelease]
			 forKey:kDictUserRequestTimeChoice];
	
	
	return dict;
}

- (id) init
{
	if ((self = [super init]))
	{
		TriMetTimesAppDelegate *appDelegate = (TriMetTimesAppDelegate *)[[UIApplication sharedApplication] delegate];
	
		self.walk =		appDelegate.prefs.maxWalkingDistance;
		self.tripMode = appDelegate.prefs.travelBy;
		self.tripMin =  appDelegate.prefs.tripMin;
		self.maxItineraries = 6;
		self.toPoint = [[[TripEndPoint alloc] init] autorelease];
		self.fromPoint = [[[TripEndPoint alloc] init] autorelease];
	}
	return self;
}

- (id)initFromDict:(NSDictionary *)dict
{
	if ((self = [super init]))
	{
		[self fromDictionary:dict];
	}
	return self;
	
}


- (NSNumber *)forceNSNumber:(NSObject*)obj
{
	if (obj && [obj isKindOfClass:[NSNumber class]])
	{
		return (NSNumber*)obj;
	}
	return nil;
	
}


- (NSString *)forceNSString:(NSObject*)obj
{
	if (obj && [obj isKindOfClass:[NSString class]])
	{
		return (NSString*)obj;
	}
	return nil;
	
}

- (NSDictionary *)forceNSDictionary:(NSObject*)obj
{
	if (obj && [obj isKindOfClass:[NSDictionary class]])
	{
		return (NSDictionary*)obj;
	}
	return nil;
	
}

- (NSDate *)forceNSDate:(NSObject*)obj
{
	if (obj && [obj isKindOfClass:[NSDate class]])
	{
		return(NSDate*)obj;
	}
	return nil;
	
}


- (bool)fromDictionary:(NSDictionary *)dict
{
	TriMetTimesAppDelegate *appDelegate = (TriMetTimesAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	self.fromPoint = [[[TripEndPoint alloc] initFromDict:[self forceNSDictionary:[dict objectForKey:kDictUserRequestFromPoint]]] autorelease];
	self.toPoint   = [[[TripEndPoint alloc] initFromDict:[self forceNSDictionary:[dict objectForKey:kDictUserRequestToPoint  ]]] autorelease];
	
	NSNumber *tripMode = [self forceNSNumber:[dict objectForKey:kDictUserRequestTripMode]];
	
	self.tripMode = tripMode	? [tripMode intValue]
								: appDelegate.prefs.travelBy;


	
	NSNumber *tripMin = [self forceNSNumber:[dict objectForKey:kDictUserRequestTripMin]];
	self.tripMin = tripMin	? [tripMin intValue]
							: appDelegate.prefs.tripMin;
	
	NSNumber *maxItineraries = [self forceNSNumber:[dict objectForKey:kDictUserRequestMaxItineraries]];
	self.maxItineraries =  maxItineraries ? [maxItineraries intValue]
										  : 6;
	
	NSNumber *walk = [self forceNSNumber:[dict objectForKey:kDictUserRequestWalk]];
	self.walk = walk	? [walk floatValue]
						: appDelegate.prefs.maxWalkingDistance;

	
	NSNumber *arrivalTime = [self forceNSNumber:[dict objectForKey:kDictUserRequestArrivalTime]];
	self.arrivalTime = arrivalTime	? [arrivalTime boolValue]
									: false;
	
	
	NSNumber *timeChoice  = [self forceNSNumber:[dict objectForKey:kDictUserRequestTimeChoice]];
	if (timeChoice)
	{
		self.timeChoice = [timeChoice intValue];
	}
	
	self.dateAndTime = [self forceNSDate:[dict objectForKey:kDictUserRequestDateAndTime]];

	
	return YES;
}

- (NSString *)getTimeType
{
	if (self.dateAndTime == nil)
	{
		return (self.arrivalTime ? @"Arrive" : @"Depart");
	}
	return (self.arrivalTime ? @"Arrive by" : @"Depart after");;
}

- (NSString*)getDateAndTime
{
	if (self.dateAndTime == nil)
	{
		return @"Now";
	}

	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	// [dateFormatter setDateFormat:@"MM-dd-yy"];
	
	[dateFormatter setDateStyle:kCFDateFormatterShortStyle];
	[dateFormatter setTimeStyle:kCFDateFormatterShortStyle];
	// NSDateFormatter *timeFormatter = [[[NSDateFormatter alloc] init] autorelease];
	// [timeFormatter setDateFormat:@"hh:mm'%20'aa"];
	
	
	return [NSString stringWithFormat:@"%@",
			[dateFormatter stringFromDate:self.dateAndTime]];
	
	
}

- (NSString *)tripName
{
	return [NSString stringWithFormat:@"From: %@\nTo: %@",
					   self.fromPoint.locationDesc==nil ? kAcquiredLocation : self.fromPoint.locationDesc,
					   self.toPoint.locationDesc==nil ? kAcquiredLocation : self.toPoint.locationDesc];
					   
	
	
}

- (NSString*)shortName
{
	NSString *title = nil;
	
	if (self.toPoint.locationDesc !=nil && !self.toPoint.useCurrentLocation)
	{
		title = [NSString stringWithFormat:@"To %@", self.toPoint.locationDesc];
	}
	else if (self.fromPoint.locationDesc !=nil)
	{
		if (self.fromPoint.useCurrentLocation)
		{
			title = [NSString stringWithFormat:@"From %@", kAcquiredLocation];
		}
		else
		{
			title = [NSString stringWithFormat:@"From %@", self.fromPoint.locationDesc];
		}
	}
	
	return title;
	
}

- (NSString *)optionsAccessability
{
	return [NSString stringWithFormat:@"Options, Maximum walking distance %0.1f miles, Travel by %@, Show the %@", 
			self.walk, [self getMode], [self getMin]];
	
}

- (NSString*)optionsDisplayText
{
	return [NSString stringWithFormat:@"Max walk: %0.1f miles\nTravel by: %@\nShow the: %@", self.walk,
			[self getMode], [self getMin]];
}





- (bool)equalsTripUserRequest:(TripUserRequest *)userRequest
{
	return [self.fromPoint equalsTripEndPoint:userRequest.fromPoint]
		&& [self.toPoint   equalsTripEndPoint:userRequest.toPoint]
		&& self.tripMode  == userRequest.tripMode
	    && self.tripMin   == userRequest.tripMin
		&& self.maxItineraries == userRequest.maxItineraries
	    && self.walk		== userRequest.walk 
	    && self.timeChoice  == userRequest.timeChoice;
}


@end


@implementation XMLTrips


@synthesize userRequest     = _userRequest;
@synthesize currentItinerary= _currentItinerary;
@synthesize currentLeg		= _currentLeg;
//@synthesize itineraries	= _itineraries;
@synthesize currentObject   = _currentObject;
@synthesize currentTagData  = _currentTagData;
@synthesize toList			= _toList;
@synthesize fromList		= _fromList;
@synthesize currentList     = _currentList;
@synthesize xdate			= _xdate;
@synthesize xtime			= _xtime;
@synthesize resultFrom		= _resultFrom;
@synthesize resultTo		= _resultTo;
@synthesize userFaves       = _userFaves;
@synthesize reversed        = _reversed;

static NSString *tripURLString = @"trips/tripplanner?%@&%@&Date=%@&Time=%@&Arr=%@&Walk=%f&Mode=%@&Min=%@&Format=XML&MaxItineraries=%d&";

- (void)dealloc {
	self.userRequest		= nil;
	self.currentItinerary	= nil;
	self.currentLeg			= nil;
	self.currentObject		= nil;
	self.currentTagData		= nil;
	self.toList				= nil;
	self.fromList			= nil;
	self.currentList		= nil;
	self.xdate				= nil;
	self.xtime				= nil;
	self.resultFrom			= nil;
	self.resultTo			= nil;
	self.userFaves			= nil;
	[super dealloc];
}

- (XMLTrips *) createReverse
{
	XMLTrips *reverse = [[[XMLTrips alloc] init] autorelease];
	
	reverse.userRequest.fromPoint = [[[TripEndPoint alloc] init] autorelease];
	reverse.userRequest.toPoint = [[[TripEndPoint alloc] init] autorelease];
	
	
	reverse.userRequest.fromPoint.locationDesc			= self.userRequest.toPoint.locationDesc;
	reverse.userRequest.fromPoint.currentLocation		= self.userRequest.toPoint.currentLocation;
	reverse.userRequest.fromPoint.useCurrentLocation	= self.userRequest.toPoint.useCurrentLocation;
	
	reverse.userRequest.toPoint.locationDesc			= self.userRequest.fromPoint.locationDesc;
	reverse.userRequest.toPoint.currentLocation			= self.userRequest.fromPoint.currentLocation;
	reverse.userRequest.toPoint.useCurrentLocation		= self.userRequest.fromPoint.useCurrentLocation;
	
	
	reverse.userRequest.dateAndTime			= self.userRequest.dateAndTime;
	reverse.userRequest.arrivalTime			= self.userRequest.arrivalTime;
	reverse.userRequest.tripMode			= self.userRequest.tripMode;
	reverse.userRequest.tripMin				= self.userRequest.tripMin;
	reverse.userRequest.maxItineraries		= self.userRequest.maxItineraries;
	reverse.userRequest.walk				= self.userRequest.walk;
	reverse.userFaves						= self.userFaves;
	reverse.reversed						= !self.reversed;
	reverse.userRequest.timeChoice          = TripAskForTime;
	
	return reverse;
}


- (XMLTrips *) createAuto
{
	XMLTrips *copy = [[[XMLTrips alloc] init] autorelease];
	
	copy.userRequest.fromPoint = [[[TripEndPoint alloc] init] autorelease];
	copy.userRequest.toPoint = [[[TripEndPoint alloc] init] autorelease];
	
	
	copy.userRequest.fromPoint.locationDesc			= self.userRequest.fromPoint.locationDesc;
	copy.userRequest.fromPoint.currentLocation		= self.userRequest.fromPoint.currentLocation;
	copy.userRequest.fromPoint.useCurrentLocation	= self.userRequest.fromPoint.useCurrentLocation;
	
	copy.userRequest.toPoint.locationDesc			= self.userRequest.toPoint.locationDesc;
	copy.userRequest.toPoint.currentLocation		= self.userRequest.toPoint.currentLocation;
	copy.userRequest.toPoint.useCurrentLocation		= self.userRequest.toPoint.useCurrentLocation;
	
	
	copy.userRequest.dateAndTime			= [self.userRequest.dateAndTime copyWithZone:NSDefaultMallocZone()];
	copy.userRequest.arrivalTime			= self.userRequest.arrivalTime;
	copy.userRequest.tripMode				= self.userRequest.tripMode;
	copy.userRequest.tripMin				= self.userRequest.tripMin;
	copy.userRequest.maxItineraries			= self.userRequest.maxItineraries;
	copy.userRequest.walk					= self.userRequest.walk;
	copy.userRequest.timeChoice				= self.userRequest.timeChoice;
	copy.userFaves							= self.userFaves;
	copy.reversed							= false;
	copy.userRequest.timeChoice				= TripAskForTime;
	
	return copy;
}

- (bool)isProp:(NSString *)elementName
{
	return ([elementName isEqualToString:@"date"]
			|| [elementName isEqualToString:@"time"]
			|| [elementName isEqualToString:@"message"]
			|| [elementName isEqualToString:@"startTime"]
			|| [elementName isEqualToString:@"endTime"]
			|| [elementName isEqualToString:@"duration"]
			|| [elementName isEqualToString:@"distance"] 
			|| [elementName isEqualToString:@"numberOfTransfers"] 
			|| [elementName isEqualToString:@"numberOfTripLegs"] 
			|| [elementName isEqualToString:@"walkingTime"]
			|| [elementName isEqualToString:@"transitTime"]
			|| [elementName isEqualToString:@"waitingTime"]	
			|| [elementName isEqualToString:@"number"]
			|| [elementName isEqualToString:@"internalNumber"]
			|| [elementName isEqualToString:@"name"]
			|| [elementName isEqualToString:@"direction"]
			|| [elementName isEqualToString:@"block"]
			|| [elementName isEqualToString:@"lat"]
			|| [elementName isEqualToString:@"lon"]
			|| [elementName isEqualToString:@"stopId"]
			|| [elementName isEqualToString:@"description"]
			);
}






#pragma mark Initiate parsing

- (void)fetchItineraries:(NSMutableData*)oldRawData
{
	
	NSError *parseError = nil;
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"MM-dd-yy"];
	NSDateFormatter *timeFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[timeFormatter setDateFormat:@"hh:mm'%20'aa"];
	
	// Trip planner takes a long time so never time out!
	self.giveUp = 0.0;
	
	// NSString *temp = [dateFormatter stringFromDate:self.dateAndTime];


	if (self.userRequest.dateAndTime == nil)
	{
		self.userRequest.dateAndTime = [NSDate date];
	}
		
	NSString * finalTripURLString = [NSString stringWithFormat: tripURLString,
									 [self.userRequest.fromPoint toQuery:@"from"], 
									 [self.userRequest.toPoint toQuery:@"to"], 
									 [dateFormatter stringFromDate:self.userRequest.dateAndTime],
									 [timeFormatter stringFromDate:self.userRequest.dateAndTime],
									 (self.userRequest.arrivalTime ? @"A" : @"D"),
									 self.userRequest.walk,
									 [self.userRequest modeToString],
									 [self.userRequest minToString],
									 self.userRequest.maxItineraries];
									 
	// self.itineraries = nil;
	self.currentLeg = nil;
	self.currentItinerary = nil;
	self.currentObject = nil;
	self.currentList = nil;
	self.toList = nil;
	self.fromList = nil;
	self.resultTo = nil;
	self.resultFrom = nil;
	
	if (oldRawData == nil)
	{
		[self startParsing:finalTripURLString parseError:&parseError];
	}
	else {
		self.rawData = oldRawData;
		
		[self parseRawData:&parseError];
	}

	
	int i;
	int l;
	TripItinerary *it;
	TripLeg		  *leg;
	
		
	for (i=0; i< [self safeItemCount]; i++)
	{
		it = [self itemAtIndex:i];
		it.displayEndPoints = [[[NSMutableArray alloc] init] autorelease];

		[it startPointText:TripTextTypeUI];
		
		if (it.startPoint !=nil && it.startPoint.displayText != nil)
		{
			[it.displayEndPoints addObject:it.startPoint];
		}
		
		if (it.legs != nil)
		{
			for (l = 0; l < [it.legs count]; l++)
			{
				leg = [it.legs objectAtIndex:l];
				
				[leg createFromText:(l==0) textType:TripTextTypeUI];
				leg.to.xnumber = leg.xinternalNumber;
				
				[leg createToText:  (l==[it.legs count]-1) textType:TripTextTypeUI];
				leg.from.xnumber = leg.xinternalNumber;
				
				if (leg.from && leg.from.displayText !=nil)
				{
					[it.displayEndPoints addObject:leg.from];
				}
				
				if (leg.to && leg.to.displayText != nil)
				{
					[it.displayEndPoints addObject:leg.to];
				}
			}
		}
	}
	
	if ([self safeItemCount] ==0 || !hasData)
	{
		[self initArray];
		
		TripItinerary *it = [[[TripItinerary alloc] init] autorelease];
		
		it.xmessage = @"Network error, touch here to check network.";
		
		[self addItem:it];
		
	}
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
	
	if ([elementName isEqualToString:@"request"])
	{
		self.currentObject = nil;
	}
	
	if ([elementName isEqualToString:@"response"]) {
		[self initArray]; 
		hasData = YES;
		self.currentObject = self;
	}
	else if ([elementName isEqualToString:@"itinerary"]
		|| [elementName isEqualToString:@"error"]) {
		self.currentItinerary =  [[[TripItinerary alloc] init] autorelease];
		self.currentLeg = nil;
		[self addItem:self.currentItinerary];
		self.currentObject = self.currentItinerary;
	}
	else if ([elementName isEqualToString:@"leg"])
	{
		self.currentLeg = [[[TripLeg alloc] init] autorelease];
		[self.currentItinerary.legs addObject:self.currentLeg];
		self.currentObject = self.currentLeg;
		self.currentLeg.mode = [self safeValueFromDict:attributeDict valueForKey:@"mode"];
	} 
	else if ([elementName isEqualToString:@"from"] && self.currentLeg !=nil)
	{
		self.currentLeg.from = [[[TripLegEndPoint alloc] init] autorelease];
		self.currentObject = self.currentLeg.from;
	}
	else if ([elementName isEqualToString:@"to"] && self.currentLeg !=nil)
	{
		self.currentLeg.to = [[[TripLegEndPoint alloc] init] autorelease];
		self.currentObject = self.currentLeg.to;
	}
	else if ([elementName isEqualToString:@"from"] && self.resultFrom == nil)
	{
		self.resultFrom = [[[TripLegEndPoint alloc] init] autorelease];
		self.currentObject = self.resultFrom;
	}
	else if ([elementName isEqualToString:@"to"] && self.resultTo == nil)
	{
		self.resultTo = [[[TripLegEndPoint alloc] init] autorelease];
		self.currentObject = self.resultTo;
	}
	else if ([elementName isEqualToString:@"special"])
	{
		NSString *tag = [self safeValueFromDict:attributeDict valueForKey:@"id"];
		if ([tag isEqualToString:@"honored"])
		{
			self.currentTagData = @"Honored Citizen: $%@\n";
		}
		else if ([tag isEqualToString:@"youth"])
		{
			self.currentTagData = @"Youth/Student: $%@\n";
		}
		else 
		{
			self.currentTagData = [NSString stringWithFormat:@"@% ($@%)", tag];
		}
	}
	else if ([elementName isEqualToString:@"fare"])
	{
		self.currentItinerary.fare = [NSMutableString string];
		// [self.currentItinerary.fare appendFormat:@"Fare: "];	
	}
	else if ([elementName isEqualToString:@"toList"])
	{
		self.toList = [[[NSMutableArray alloc] init] autorelease];
		self.currentList = self.toList;
	}
	else if ([elementName isEqualToString:@"location"])
	{
		if (self.currentList != nil)
		{
			TripLegEndPoint *loc = [[[TripLegEndPoint alloc] init] autorelease];
			[self.currentList addObject:loc];
			self.currentObject = loc;
		}
	}
	else if ([elementName isEqualToString:@"fromList"])
	{
		self.fromList = [[[NSMutableArray alloc] init] autorelease];
		self.currentList = self.fromList;
	}
	
	if ([self isProp:elementName] || [elementName isEqualToString:@"regular"] || [elementName isEqualToString:@"special"]
			|| [elementName isEqualToString:@"url"])		
	{
		self.contentOfCurrentProperty = [[[NSMutableString alloc] init] autorelease];
	}
	
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
    if (qName) {
        elementName = qName;
    }
	
	if (self.currentObject != nil && [self isProp:elementName])
		
	{
		NSString *selName = [NSString stringWithFormat:@"setX%@:", elementName];
		SEL prop = NSSelectorFromString(selName);
		if ([self.currentObject respondsToSelector:prop])
		{
			[self.currentObject performSelector:prop withObject:self.contentOfCurrentProperty];
		}
	}
	
	if ([elementName isEqualToString:@"regular"])
	{
		[self.currentItinerary.fare appendFormat:@"Adult: $%@\n", self.contentOfCurrentProperty];
	} 
	else if ([elementName isEqualToString:@"special"])
	{
		[self.currentItinerary.fare appendFormat:self.currentTagData, self.contentOfCurrentProperty];
	}
	else if ([elementName isEqualToString:@"leg"])
	{
		self.currentLeg = nil;
		self.currentObject = nil;
	}
	else if ([elementName isEqualToString:@"from"]
		|| [elementName isEqualToString:@"to"])
	{
		self.currentObject = self.currentLeg;
	}
	else if ([elementName isEqualToString:@"itinerary"]
			 || [elementName isEqualToString:@"error"])
	{
		self.currentItinerary = nil;
		self.currentObject = nil;
	}
	else if ([elementName isEqualToString:@"toList"]
		||	 [elementName isEqualToString:@"fromList"])
	{
		self.currentList = nil;
	}
	else if ([elementName isEqualToString:@"url"] && self.currentLeg !=nil)
	{
		self.currentLeg.legShape = [[[LegShapeParser alloc] init] autorelease];
		self.currentLeg.legShape.lineURL = self.contentOfCurrentProperty;
		// [self.currentLeg.legShape fetchCoords];
	}
	
	self.contentOfCurrentProperty = nil;
}

#pragma mark Data Helpers

-(void)clearRawData
{
	// we need this data to be cached, so do nothing
}

- (void)saveTrip
{
	SafeUserData *userData = [SafeUserData getSingleton];
	
	if (self.rawData !=nil)
	{
		[userData addToRecentTripsWithUserRequest:[self.userRequest toDictionary] 
										 description:[self longName] 
												blob:self.rawData];
	}
}

- (NSString*)shortName
{
	NSString *title = nil;
	
	if (self.userRequest.toPoint.locationDesc !=nil && !self.userRequest.toPoint.useCurrentLocation)
	{
		if (self.resultTo !=nil && self.resultTo.xdescription != nil)
		{
			title = [NSString stringWithFormat:@"To %@", self.resultTo.xdescription ];
		}
		else
		{
			title = [NSString stringWithFormat:@"To %@", self.userRequest.toPoint.locationDesc];
		}
	}
	else if (self.userRequest.fromPoint.locationDesc !=nil)
	{
		
		if (self.resultFrom !=nil && self.resultFrom.xdescription != nil)
		{
			title = [NSString stringWithFormat:@"From %@", self.resultFrom.xdescription ];
		}
		else
		{
			title = [NSString stringWithFormat:@"From %@", self.userRequest.fromPoint.locationDesc];
		}
	}
	
	return title;
	
}

- (NSString*)longName
{
	return [NSString stringWithFormat:
			@"%@%@ %@",
			[self mediumName], 
			[self.userRequest getTimeType],
			[self.userRequest getDateAndTime]];
}

- (NSString*)mediumName
{
	NSMutableString *title = [[[NSMutableString alloc] init] autorelease];
	
	
	if (self.userRequest.fromPoint.locationDesc !=nil)
	{
		
		if (self.resultFrom !=nil && self.resultFrom.xdescription != nil)
		{
			[title appendFormat:@"From: %@\n", self.resultFrom.xdescription ];
		}
		else
		{
			[title appendFormat:@"From: %@\n", self.userRequest.fromPoint.locationDesc];
		}
	}
	else {
		[title appendFormat:@"From: Acquired Location\n"];
	}
	
	
	if (self.userRequest.toPoint.locationDesc !=nil)
	{
		if (self.resultTo !=nil && self.resultTo.xdescription != nil)
		{
			[title appendFormat:@"To: %@\n", self.resultTo.xdescription ];
		}
		else
		{
			[title appendFormat:@"To: %@\n", self.userRequest.toPoint.locationDesc];
		}
	}
	else {
		[title appendFormat:@"To: %@\n", kAcquiredLocation];
	}
	

	return title;
	
}


- (void)addStopsFromUserFaves:(NSArray *)userFaves
{
	NSMutableArray * justStops = [[[NSMutableArray alloc] init] autorelease];
	
	int i;
	
	for (i=0; i< [userFaves count]; i++)
	{
		NSDictionary *dict = [userFaves objectAtIndex:i];
		
		if ([dict valueForKey:kUserFavesLocation] != nil)
		{
			[justStops insertObject:dict atIndex:[justStops count]];
		}
		
	}
	self.userFaves = justStops;
	
}

- (id)init
{
	if ((self = [super init]))
	{
		self.userRequest = [[[TripUserRequest alloc] init] autorelease];
	}
	return self;
	
}

@end
