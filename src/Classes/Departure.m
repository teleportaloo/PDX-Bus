//
//  Departure.m
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

#import "Departure.h"
#import "Trip.h"

#import "ViewControllerBase.h"
#import "TriMetRouteColors.h"
#import "RouteColorBlobView.h"
#import "debug.h"

@implementation Departure

@synthesize hasBlock = _hasBlock;
@synthesize queryTime = _queryTime;
@synthesize blockPositionFeet = _blockPositionFeet;
@synthesize blockPositionAt = _blockPositionAt;
@synthesize blockPositionLat = _blockPositionLat;
@synthesize blockPositionLng = _blockPositionLng;
@synthesize routeName = _routeName;
@synthesize errorMessage = _errorMessage;
@synthesize route = _route;
@synthesize fullSign = _fullSign;
@synthesize departureTime = _departureTime;
@synthesize status = _status;
@synthesize detour = _detour;
@synthesize locationDesc = _locationDesc;
@synthesize locationDir = _locationDir;
@synthesize trips = _trips;
@synthesize block = _block;
@synthesize dir = _dir;
@synthesize locid = _locid;
@synthesize streetcar = _streetcar;
@synthesize nextBus = _nextBus;
@synthesize stopLat = _stopLat;
@synthesize stopLng = _stopLng;
@synthesize copyright = _copyright;
@synthesize scheduledTime = _scheduledTime;
@synthesize cacheTime = _cacheTime;

- (void)dealloc
{
	self.route = nil;
	self.fullSign = nil;
	self.errorMessage = nil;
	self.routeName = nil;
	self.blockPositionLat = nil;
	self.blockPositionLng = nil;
	self.locationDesc = nil;
	self.trips = nil;
	self.block = nil;
	self.dir = nil;
	self.locid = nil;
	self.locationDir = nil;
	self.stopLat = nil;
	self.stopLng = nil;
	self.copyright = nil;
    self.cacheTime = nil;
	
	[super dealloc];
	
}

- (id)init
{
	if ((self = [super init]))
	{

		self.trips = [[[NSMutableArray alloc] init] autorelease];
		
	}
	return self;
}


#pragma mark Formatting 

-(NSString *)formatLayoverTime:(TriMetTime)t
{
	NSMutableString * str = [[[NSMutableString alloc] init] autorelease];
	TriMetTime secs = TriMetToUnixTime(t) % 60;
	TriMetTime mins = t / 60000;
	
	if (mins == 1)
	{
		[str appendFormat:@" 1 min"];
	}
	
	if (mins > 1)
	{
		[str appendFormat:@" %d mins", mins ];
	}
	
	if (secs > 0)
	{
		[str appendFormat:@" %02d secs", secs ];
	}
	
	return str;
	
}


-(TriMetTime)secondsToArrival
{
	
	return TriMetToUnixTime(self.departureTime - self.queryTime);
}

- (int)minsToArrival
{
	return self.secondsToArrival / 60;
}

-(NSString *)formatDistance:(int)distance
{
	NSString *str = nil;
	if (distance < 500)
	{
		str = [NSString stringWithFormat:@"%d ft (%d meters)", distance,
			   (int)(distance / 3.2808398950131235) ];
	}
	else
	{
		str = [NSString stringWithFormat:@"%.2f miles (%.2f km)", (float)(distance / 5280.0),
			   (float)(distance / 3280.839895013123) ];
	}	
	return str;
}


#pragma mark User Interface

#define ROUTE_TAG 1
#define TIME_TAG  2
#define BIG_MINS_TAG  3
#define BIG_UNIT_TAG 4
#define COLOR_STRIPE_TAG 5
#define SCHEDULED_TAG 6
#define DETOUR_TAG 7

- (UILabel*)label:(UITableViewCell*)cell tag:(NSInteger)tag
{
	return ((UILabel*)[cell.contentView viewWithTag:tag]);
}

- (NSString *)cellReuseIdentifier:(NSString *)identifier width:(ScreenType)width
{
	return [NSString stringWithFormat:@"%@-%d", identifier, width];
}

- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier big:(bool)big spaceToDecorate:(bool)spaceToDecorate width:(ScreenType)width
{
	CGFloat LEFT_COLUMN_OFFSET			= 11.0;
	CGFloat LEFT_COLUMN_WIDTH			= 280.0;
	CGFloat SHORT_LEFT_COLUMN_WIDTH		= 254.0;
	CGFloat LONG_LEFT_COLUMN_WIDTH		= 300.0;
	// CGFloat MINS_LEFT					= 254.0;
	CGFloat MINS_LEFT					= 266.0;
	
	CGFloat MINS_WIDTH					= 30.0;
	CGFloat MINS_HEIGHT					= 26.0;
	CGFloat MINS_UNIT_HEIGHT			= 16.0;
		
	CGFloat MAIN_FONT_SIZE				= 18.0;
	CGFloat BIG_MINS_FONT_SIZE			= 24.0;
	CGFloat UNIT_FONT_SIZE				= 14.0;
	CGFloat LABEL_HEIGHT				= 26.0;
	CGFloat TIME_FONT_SIZE				= 14.0;	
	CGFloat ROW_HEIGHT					= kDepartureCellHeight;
	CGFloat MINS_GAP = ((ROW_HEIGHT - MINS_HEIGHT - MINS_UNIT_HEIGHT) / 3.0);
	CGFloat ROW_GAP  = ((ROW_HEIGHT - LABEL_HEIGHT - LABEL_HEIGHT) / 3.0);
	
	
	switch (width)
	{
    default:
	case WidthiPhoneNarrow:
			break;
	//case WidthiPhoneWide:
	//		MINS_LEFT					= 400.0;
	//		SHORT_LEFT_COLUMN_WIDTH     = 390.0;
	//		break;
	case WidthiPadWide:
	case WidthiPadNarrow:
			// ROW_HEIGHT				= kWideDepartureCellHeight;
			LEFT_COLUMN_OFFSET		= 16.0;
			LEFT_COLUMN_WIDTH		= 560.0;
			
			if (width == WidthiPadWide)
			{
				LONG_LEFT_COLUMN_WIDTH	= 900.0;
				
			}
			else
			{
				LONG_LEFT_COLUMN_WIDTH	= 640.0;
			}
			SHORT_LEFT_COLUMN_WIDTH = (LONG_LEFT_COLUMN_WIDTH + 10.0);
			MINS_LEFT				= (LONG_LEFT_COLUMN_WIDTH + 30.0);
			
			MINS_WIDTH				= 60.0;
			MINS_HEIGHT				= 45.0;
			MINS_UNIT_HEIGHT		= 28.0;
			
			
			MAIN_FONT_SIZE			= 32.0;
			BIG_MINS_FONT_SIZE		= 44.0;
			UNIT_FONT_SIZE			= 28.0;
			LABEL_HEIGHT			= 43.0;
			TIME_FONT_SIZE			= 28.0;
			
			MINS_GAP				= ((kWideDepartureCellHeight - MINS_HEIGHT - MINS_UNIT_HEIGHT) / 3.0);
			ROW_GAP					= ((kWideDepartureCellHeight - LABEL_HEIGHT - LABEL_HEIGHT) / 3.0);
			
			break;
	}
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, local time, and quarter image of the time zone.
	 */
	CGRect rect;
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
	
	
	
	/*
	 Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
	 */
	UILabel *label;

	if (big)
	{
		rect = CGRectMake(LEFT_COLUMN_OFFSET, MINS_GAP, SHORT_LEFT_COLUMN_WIDTH, LABEL_HEIGHT);
		label = [[UILabel alloc] initWithFrame:rect];
		label.tag = ROUTE_TAG;
		label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
		label.adjustsFontSizeToFitWidth = YES;
		[cell.contentView addSubview:label];
		label.highlightedTextColor = [UIColor whiteColor];
		[label release];
		
		rect = CGRectMake(0, MINS_GAP, COLOR_STRIPE_WIDTH, LABEL_HEIGHT);
		RouteColorBlobView *colorStripe = [[RouteColorBlobView alloc] initWithFrame:rect];
		colorStripe.tag = COLOR_STRIPE_TAG;
		[cell.contentView addSubview:colorStripe];
		[colorStripe release];
		
		rect = CGRectMake(LEFT_COLUMN_OFFSET, MINS_GAP+MINS_HEIGHT+MINS_GAP, SHORT_LEFT_COLUMN_WIDTH, MINS_UNIT_HEIGHT);
		label = [[UILabel alloc] initWithFrame:rect];
		label.tag = TIME_TAG;
		label.font = [UIFont systemFontOfSize:UNIT_FONT_SIZE];
		label.adjustsFontSizeToFitWidth = YES;
		[cell.contentView addSubview:label];
		label.highlightedTextColor = [UIColor whiteColor];
		[label release];
		
		label = [[UILabel alloc] initWithFrame:rect];
		label.tag = SCHEDULED_TAG;
		label.font = [UIFont systemFontOfSize:UNIT_FONT_SIZE];
		label.adjustsFontSizeToFitWidth = YES;
		[cell.contentView addSubview:label];
		label.highlightedTextColor = [UIColor whiteColor];
		[label release];
		
		label = [[UILabel alloc] initWithFrame:rect];
		label.tag = DETOUR_TAG;
		label.font = [UIFont systemFontOfSize:UNIT_FONT_SIZE];
		label.adjustsFontSizeToFitWidth = YES;
		[cell.contentView addSubview:label];
		label.highlightedTextColor = [UIColor whiteColor];
		[label release];
		
		rect = CGRectMake(MINS_LEFT, MINS_GAP, MINS_WIDTH, MINS_HEIGHT);
		label = [[UILabel alloc] initWithFrame:rect];
		label.tag = BIG_MINS_TAG;
		label.font = [UIFont boldSystemFontOfSize:BIG_MINS_FONT_SIZE];
		label.adjustsFontSizeToFitWidth = YES;
		[cell.contentView addSubview:label];
		label.highlightedTextColor = [UIColor whiteColor];
		[label release];
		
		rect = CGRectMake(MINS_LEFT, MINS_GAP+MINS_HEIGHT+MINS_GAP, MINS_WIDTH, MINS_UNIT_HEIGHT);
		label = [[UILabel alloc] initWithFrame:rect];
		label.tag = BIG_UNIT_TAG;
		label.font = [UIFont systemFontOfSize:UNIT_FONT_SIZE];
		label.adjustsFontSizeToFitWidth = YES;
		[cell.contentView addSubview:label];
		label.highlightedTextColor = [UIColor whiteColor];
		[label release];
	}
	else
	{
		rect = CGRectMake(LEFT_COLUMN_OFFSET, ROW_GAP, spaceToDecorate? LEFT_COLUMN_WIDTH : LONG_LEFT_COLUMN_WIDTH, LABEL_HEIGHT);
		label = [[UILabel alloc] initWithFrame:rect];
		label.tag = ROUTE_TAG;
		label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
		label.adjustsFontSizeToFitWidth = YES;
		[cell.contentView addSubview:label];
		label.highlightedTextColor = [UIColor whiteColor];
		[label release];
		
		rect = CGRectMake(0, ROW_GAP, COLOR_STRIPE_WIDTH, LABEL_HEIGHT);
		RouteColorBlobView *colorStripe = [[RouteColorBlobView alloc] initWithFrame:rect];
		colorStripe.tag = COLOR_STRIPE_TAG;
		[cell.contentView addSubview:colorStripe];
		[colorStripe release];
		
		rect = CGRectMake(LEFT_COLUMN_OFFSET,ROW_GAP * 2.0 + LABEL_HEIGHT, spaceToDecorate? LEFT_COLUMN_WIDTH : LONG_LEFT_COLUMN_WIDTH, LABEL_HEIGHT);
		label = [[UILabel alloc] initWithFrame:rect];
		label.tag = TIME_TAG;
		label.font = [UIFont systemFontOfSize:TIME_FONT_SIZE];
		label.adjustsFontSizeToFitWidth = YES;
		[cell.contentView addSubview:label];
		label.highlightedTextColor = [UIColor whiteColor];
		[label release];

		label = [[UILabel alloc] initWithFrame:rect];
		label.tag = SCHEDULED_TAG;
		label.font = [UIFont systemFontOfSize:UNIT_FONT_SIZE];
		label.adjustsFontSizeToFitWidth = YES;
		[cell.contentView addSubview:label];
		label.highlightedTextColor = [UIColor whiteColor];
		[label release];
		
		label = [[UILabel alloc] initWithFrame:rect];
		label.tag = DETOUR_TAG;
		label.font = [UIFont systemFontOfSize:UNIT_FONT_SIZE];
		label.adjustsFontSizeToFitWidth = YES;
		[cell.contentView addSubview:label];
		label.highlightedTextColor = [UIColor whiteColor];
		[label release];
	}
	
	
	
	/*
	rect = CGRectMake(MIDDLE_COLUMN_OFFSET, (ROW_HEIGHT - LABEL_HEIGHT) / 2.0, MIDDLE_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = TIME_TAG;
	label.font = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
	label.textAlignment = UITextAlignmentRight;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	[label release];
	*/
	
	return cell;
}

- (CGFloat)moveLabelInCell:(UITableViewCell*)cell nextX:(CGFloat)nextX text:(NSString *)text tag:(int)tag color:(UIColor *)col
{
	UILabel *label = [self label:cell tag:tag];
	UILabel *unitView = [self label:cell tag:BIG_UNIT_TAG];
	
	if (text !=nil && [text length] !=0)
	{
		label.textColor = col;
		label.text = text;
		label.hidden = NO;
	
		CGSize size = [label.text sizeWithFont:label.font
							 constrainedToSize:CGSizeMake(9999, 9999)
								 lineBreakMode:label.lineBreakMode];
	
		CGRect frame = CGRectMake( nextX, label.frame.origin.y, size.width, label.frame.size.height );
		label.frame = frame;
		nextX += size.width;
		DEBUG_LOG(@"%@ y %f h %f\n", text, frame.origin.y, frame.size.height);
		
		if (unitView && nextX > unitView.frame.origin.x)
		{
			unitView.hidden = YES;
		}
	}
	else {
		label.hidden = YES;
	}
	
	return nextX;
	
}

- (void)populateCell:(UITableViewCell *)cell decorate:(BOOL)decorate big:(BOOL)big busName:(BOOL)busName wide:(BOOL)wide;
{
	if ([self errorMessage] !=nil)
	{
		[self label:cell tag:ROUTE_TAG].text = [self errorMessage];
		[self label:cell tag:TIME_TAG].text = nil;
		if (big)
		{
			[self label:cell tag:BIG_MINS_TAG].hidden = YES;
			[self label:cell tag:BIG_UNIT_TAG].hidden = YES;
		}
	}
	else
	{
		cell.textLabel.text = nil;
		
		//if (decorate)
		//{
		//	((UILabel*)[cell.contentView viewWithTag:ROUTE_TAG]).text = self.routeName;
		//}
		//else
		
	
		UIColor *timeColor = nil;
		UILabel *minsView = [self label:cell tag:BIG_MINS_TAG];
        
		TriMetTime mins = (self.departureTime - self.queryTime) / 60000;
		
		NSDate *depatureDate = [NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime(self.departureTime)];
		NSMutableString *timeText = [[[NSMutableString alloc] init] autorelease];
		NSMutableString *scheduledText = [[[NSMutableString alloc] init] autorelease];
		NSMutableString *detourText = [[[NSMutableString alloc] init] autorelease];
		NSString *minsText = nil;
		NSString *unitText = nil;
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		
		
		
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:kCFDateFormatterNoStyle];
		
		// If date is tomorrow and more than 12 hours away then put the full date
		if (([[dateFormatter stringFromDate:depatureDate] isEqualToString:[dateFormatter stringFromDate:[NSDate date]]])
			 || ([depatureDate timeIntervalSinceDate:[NSDate date]] < 12 * 60 * 60)
			 || self.status == kStatusEstimated)
		{
			[dateFormatter setDateStyle:kCFDateFormatterNoStyle];
		}
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		
		
		if (big)
		{
			/* if (self.hasBlock)
			{
				[text appendFormat:@"(%@) ", self.block];
			} */
			
            if (mins < 0)
            {
                minsText = @"-";
				unitText = @"gone";
				[timeText appendString:[dateFormatter stringFromDate:depatureDate]];
				[timeText appendString:@" "];
				timeColor = [UIColor blackColor]; 
            }
			else if (mins == 0)
			{
				minsText = @"Due";
				unitText = @"now";
				[timeText appendString:[dateFormatter stringFromDate:depatureDate]];
				[timeText appendString:@" "];
				timeColor = [UIColor redColor];
			}
			else if (mins == 1)
			{
				minsText = @"1";
				unitText = @"min";
				[timeText appendString:[dateFormatter stringFromDate:depatureDate]];
				[timeText appendString:@" "];
				timeColor = [UIColor redColor];
			}
			else if (mins < 6)
			{	
				minsText = [NSString stringWithFormat:@"%d", mins];
				unitText = @"mins";
				[timeText appendString:[dateFormatter stringFromDate:depatureDate]];
				[timeText appendString:@" "];
				timeColor = [UIColor redColor];	
			}
			else if (mins < 60)
			{
				minsText = [NSString stringWithFormat:@"%d", mins];
				unitText = @"mins";
				[timeText appendString:[dateFormatter stringFromDate:depatureDate]];
				[timeText appendString:@" "];
				timeColor = [UIColor blueColor];
			} 
			else
			{
				minsText = @":::";
				unitText = @":::";
				[timeText appendString:[dateFormatter stringFromDate:depatureDate]];
				[timeText appendString:@" "];
				timeColor = [UIColor blueColor];	
			}
		}
		else
		{
            if (mins < 0)
            {
                [timeText appendString:@"Gone - "];
				[timeText appendString:[dateFormatter stringFromDate:depatureDate]];
				[timeText appendString:@" "];
				timeColor = [UIColor redColor];
            }
			else if (mins == 0)
			{
				[timeText appendString:@"Due - "];
				[timeText appendString:[dateFormatter stringFromDate:depatureDate]];
				[timeText appendString:@" "];
				timeColor = [UIColor redColor];
			}
			else if (mins == 1)
			{
				[timeText appendString:@"1 min - "];
				[timeText appendString:[dateFormatter stringFromDate:depatureDate]];
				[timeText appendString:@" "];
				timeColor = [UIColor redColor];
			}
			else if (mins < 6)
			{
				[timeText appendFormat:@"%d mins - ", mins];
				[timeText appendString:[dateFormatter stringFromDate:depatureDate]];
				[timeText appendString:@" "];
				timeColor = [UIColor redColor];	
			}
			else if (mins < 60)
			{
				[timeText appendFormat:@"%d mins - ", mins];
				[timeText appendString:[dateFormatter stringFromDate:depatureDate]];
				[timeText appendString:@" "];
				timeColor = [UIColor blueColor];
			} 
			else
			{			
				[timeText appendString:[dateFormatter stringFromDate:depatureDate]];
				[timeText appendString:@" "];
				timeColor = [UIColor blueColor];	
			}
		}
		
		switch (self.status)
		{
		case kStatusEstimated:
			break;
		case kStatusScheduled:
			[scheduledText appendFormat:@"scheduled "];
			timeColor = [UIColor grayColor];
			break;
		case kStatusCancelled:
			[detourText appendFormat:@"canceled "];
			timeColor = [UIColor orangeColor];
			break;
		case kStatusDelayed:
			[detourText appendFormat:@"delayed "];
			timeColor = [UIColor orangeColor];
			break;	
		}
		
		if (self.status != kStatusScheduled && self.scheduledTime !=0 && (self.scheduledTime/60000) != (self.departureTime/60000))
		{
			NSDate *scheduledDate = [NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime(self.scheduledTime)];
			[scheduledText appendFormat:@"scheduled %@ ", [dateFormatter stringFromDate:scheduledDate]];;
		}
		
		if (self.detour)
		{
			[detourText appendFormat:@"detour"];
		}
		
		
		UILabel * unitView = [self label:cell tag:BIG_UNIT_TAG];
		if (minsText !=nil)
		{
			minsView.text = minsText;
			minsView.hidden = NO;
			minsView.textAlignment = UITextAlignmentCenter;
			minsView.textColor = timeColor;

			unitView.textColor = timeColor;
			unitView.text = unitText;
			unitView.hidden = NO;
			unitView.textAlignment = UITextAlignmentCenter;
		}
		else
		{
			unitView.hidden = YES;
			minsView.hidden = YES;
		}
			
		if (decorate) //  && (self.hasBlock || self.detour))
		{
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			// cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
		else
		{
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		
		UILabel *routeLabel;
		
		DEBUG_LOG(@"Unit y %f h %f\n", unitView.frame.origin.y, unitView.frame.size.height);
		
		
		routeLabel = [self label:cell tag:ROUTE_TAG ];
		[self label:cell tag:ROUTE_TAG			].hidden = NO;
		
		// Layout the time text, scheduled text and detour text all in a row
		
		UILabel *timeLabel = [self label:cell tag:TIME_TAG ];
		CGFloat nextX = timeLabel.frame.origin.x;
		nextX = [self moveLabelInCell:cell nextX:nextX text:timeText		tag:TIME_TAG		color:timeColor];
		nextX = [self moveLabelInCell:cell nextX:nextX text:scheduledText	tag:SCHEDULED_TAG	color:[UIColor grayColor]];
		[self moveLabelInCell:cell nextX:nextX text:detourText		tag:DETOUR_TAG		color:[UIColor orangeColor]];
		
		if (big)
		{
			if (busName)
			{
				if (wide)
				{
					routeLabel.text = self.fullSign;
				}
				else 
				{
					routeLabel.text = self.routeName;
				}

				
				//routeLabel.lineBreakMode = UILineBreakModeWordWrap;
				//routeLabel.adjustsFontSizeToFitWidth = YES;

			}
			else 
			{
				routeLabel.text = self.locationDesc;
				//routeLabel.lineBreakMode = UILineBreakModeTailTruncation;
				//routeLabel.adjustsFontSizeToFitWidth = NO;
			}

			
			[cell setAccessibilityLabel:[NSString stringWithFormat:@"%@, %@ %@, %@ %@ %@",
										 routeLabel.text, minsText, unitText, timeText, scheduledText, detourText]];
			
			
		}
		else
		{
			if (busName)
			{
				routeLabel.text = self.fullSign;
			}
			else {
				routeLabel.text = self.locationDesc;
			}

			
			[cell setAccessibilityLabel:[NSString stringWithFormat:@"%@, %@ %@ %@",
										 routeLabel.text, timeText, scheduledText, detourText]];
		}
		routeLabel.textColor = [UIColor blackColor];
	}	
	
	RouteColorBlobView *colorStripe = (RouteColorBlobView*)[cell.contentView viewWithTag:COLOR_STRIPE_TAG];
	[colorStripe setRouteColor:self.route];

}




- (void)populateCellGeneric:(UITableViewCell *)cell first:(NSString *)first second:(NSString *)second col1:(UIColor *)col1 col2:(UIColor *)col2;

{
	[self label:cell tag:ROUTE_TAG].text = first;
	[self label:cell tag:ROUTE_TAG].textColor = col1;
	[self label:cell tag:ROUTE_TAG].hidden = NO;
	[self label:cell tag:TIME_TAG].text = second;
	[self label:cell tag:TIME_TAG].textColor = col2;
	RouteColorBlobView *colorStripe = (RouteColorBlobView*)[cell.contentView viewWithTag:COLOR_STRIPE_TAG];
	colorStripe.hidden = YES;
	
	UILabel *timeLabel = [self label:cell tag:TIME_TAG ];
	CGFloat nextX = timeLabel.frame.origin.x;
	nextX = [self moveLabelInCell:cell nextX:nextX text:second		tag:TIME_TAG		color:col2];
	nextX = [self moveLabelInCell:cell nextX:nextX text:nil			tag:SCHEDULED_TAG	color:col2];
			[self moveLabelInCell:cell nextX:nextX text:nil			tag:DETOUR_TAG		color:col2];
	
}

- (void)populateTripCell:(UITableViewCell *)cell item:(int)item
{
	Trip * trip = [self.trips objectAtIndex:item];
	
	cell.textLabel.text = nil;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	
	NSString *timeText = nil;
	UIColor *timeColor = nil;
	[self label:cell tag:BIG_MINS_TAG].hidden = YES;
	[self label:cell tag:BIG_UNIT_TAG].hidden = YES;

	[self label:cell tag:ROUTE_TAG].hidden = NO;
	
	if (trip.distance > 0)
	{
		TriMetDistance toGo = trip.distance - trip.progress;
		
		if (trip.progress > 0)
		{
			[self label:cell tag:ROUTE_TAG].text = [NSString stringWithFormat:@"Current trip: %@", trip.name];
			[self label:cell tag:ROUTE_TAG].textColor = [UIColor blackColor];
			timeText = [NSString stringWithFormat:@"%@ left to go", [self formatDistance:toGo]];
			timeColor = [UIColor blueColor];
		}
		else
		{
			[self label:cell tag:ROUTE_TAG].text = [NSString stringWithFormat:@"Trip: %@", trip.name];
			[self label:cell tag:ROUTE_TAG].textColor = [UIColor blackColor];
			timeText = [NSString stringWithFormat:@"%@ total", [self formatDistance:toGo]];
			timeColor = [UIColor grayColor];
		}
		[cell setAccessibilityLabel:[NSString stringWithFormat:@"%@, %@", 
											[self label:cell tag:ROUTE_TAG].text,
											timeText]];
	}
	
	if (trip.startTime > 0)
	{
		[self label:cell tag:ROUTE_TAG].text = [NSString stringWithFormat:@"%@", trip.name];
		[self label:cell tag:ROUTE_TAG].textColor = [UIColor blackColor];
		
		TriMetTime toGo; 
		
		NSDate *startLayover = [NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime(trip.startTime)];
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:kCFDateFormatterNoStyle];
		
		if ([[dateFormatter stringFromDate:startLayover] isEqualToString:[dateFormatter stringFromDate:[NSDate date]]])
		{
			[dateFormatter setDateStyle:kCFDateFormatterNoStyle];
		}
		[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
		
		if (trip.startTime < self.queryTime && trip.endTime > self.queryTime)
		{
			toGo = trip.endTime - self.queryTime;
			timeText = [NSString stringWithFormat:@"Layover at %@ remaining: %@",  
							 [dateFormatter stringFromDate:startLayover],  [self formatLayoverTime:toGo]];
			timeColor = [UIColor blueColor];
		}
		else
		{
			NSMutableString *str = [[[NSMutableString alloc] init] autorelease];
			toGo = trip.endTime - trip.startTime;
			
			[str appendFormat:@"Layover at %@", [dateFormatter stringFromDate:startLayover]];
			[str appendFormat:@" for%@", [self formatLayoverTime:toGo]];
			timeText = str;
			timeColor = [UIColor grayColor];
		}
		[cell setAccessibilityLabel:[NSString stringWithFormat:@"%@, %@", 
									 [self label:cell tag:ROUTE_TAG].text,
										timeText]];
		
	}
	
	UILabel *timeLabel = [self label:cell tag:TIME_TAG ];
	CGFloat nextX = timeLabel.frame.origin.x;
	nextX = [self moveLabelInCell:cell nextX:nextX text:timeText	tag:TIME_TAG		color:timeColor];
	nextX = [self moveLabelInCell:cell nextX:nextX text:nil			tag:SCHEDULED_TAG	color:timeColor];
	[self moveLabelInCell:cell nextX:nextX text:nil			tag:DETOUR_TAG		color:timeColor];

	RouteColorBlobView *colorStripe = (RouteColorBlobView*)[cell.contentView viewWithTag:COLOR_STRIPE_TAG];
	colorStripe.hidden = YES;

	
}


#pragma mark Map callbacks 

- (bool)mapDisclosure
{
	return YES;
}

- (Departure*)mapDeparture
{
	return self;
}

- (NSString *)description
{
    // Override of -[NSObject description] to print a meaningful representation of self.
    return [NSString stringWithFormat:@"%@", self.fullSign];
}

// MK Annotate
- (CLLocationCoordinate2D)coordinate
{
	CLLocationCoordinate2D pos;
	
	pos.latitude = [self.blockPositionLat doubleValue];
	pos.longitude = [self.blockPositionLng doubleValue];
	return pos;
}

- (NSString *)title
{
	return self.routeName;
}

- (NSString *)subtitle
{
	NSMutableString *text = [[[NSMutableString alloc] init] autorelease];
	if ([self errorMessage] ==nil)
	{
		TriMetTime mins = (self.departureTime - self.queryTime) / 60000;
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		NSDate *depatureDate = [NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime(self.departureTime)];
		NSString *loc = self.locationDesc;
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:kCFDateFormatterNoStyle];
		
		if ([[dateFormatter stringFromDate:depatureDate] isEqualToString:[dateFormatter stringFromDate:[NSDate date]]])
		{
			[dateFormatter setDateStyle:kCFDateFormatterNoStyle];
		}
		[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
		
		if (mins <= 0)
		{
			[text appendString:@"Due - "];
			[text appendString:[dateFormatter stringFromDate:depatureDate]];
			[text appendFormat:@" at %@", loc];
		}
		else if (mins == 1)
		{
			[text appendString:@"1 min - "];
			[text appendString:[dateFormatter stringFromDate:depatureDate]];
			[text appendFormat:@" to %@", loc];
		}
		else if (mins < 6)
		{
			[text appendFormat:@"%d mins - ", mins];
			[text appendString:[dateFormatter stringFromDate:depatureDate]];
			[text appendFormat:@" to %@", loc];
			
		}
		else if (mins < 60)
		{
			[text appendFormat:@"%d mins - ", mins];
			[text appendString:[dateFormatter stringFromDate:depatureDate]];
			[text appendFormat:@" to %@", loc];
		} 
		else
		{			
			[text appendString:[dateFormatter stringFromDate:depatureDate]];
			[text appendFormat:@" to %@", loc];
		}
		
		
	}
	
	return text;
	
}

- (MKPinAnnotationColor) getPinColor
{
	return MKPinAnnotationColorPurple;
}

@end
