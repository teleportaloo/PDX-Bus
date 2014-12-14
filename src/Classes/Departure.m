//
//  Departure.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Departure.h"
#import "Trip.h"

#import "ViewControllerBase.h"
#import "TriMetRouteColors.h"
#import "RouteColorBlobView.h"
#import "DebugLogging.h"
#import "BlockColorDb.h"
#import "CanceledBusOverlay.h"

#define kVehicleDepartedText    NSLocalizedString(@"The time is shown in black as the vehicle has departed.",                                                               @"Infomation text")
#define kVehicleSoonText        NSLocalizedString(@"The time is shown in red as the vehicle will depart in 5 minutes or less.",                                           @"Infomation text")
#define kVehicleComingText      NSLocalizedString(@"The time is shown in blue as the vehicle will depart in more than 5 minutes.",                                         @"Infomation text")
#define kVehicleLongText        kVehicleComingText
#define kVehicleScheduled       NSLocalizedString(@"The time is shown in gray as no location infomation is available - the scheduled time is shown.",                          @"Infomation text")
#define kVehicleCanceled        NSLocalizedString(@"The time is shown in orange and crossed out as the vehicle was canceled.  The original scheduled time is shown for reference.",     @"Infomation text")
#define kVehicleDelayed         NSLocalizedString(@"The Time is shown in yellow as the vehicle is delayed.",                                                                 @"Infomation text")
#define kVehicleLate            NSLocalizedString(@"Note: the scheduled time is also shown in gray as the vehicle is not running to schedule.",                       @"Infomation text")


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
@synthesize streetcarId = _streetcarId;
@synthesize nextBusFeedInTriMetData = _nextBusFeedInTriMetData;

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
    self.streetcarId = nil;
	
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
		[str appendFormat:NSLocalizedString(@" 1 min", @"how long a bus layover will be")];
	}
	
	if (mins > 1)
	{
		[str appendFormat:NSLocalizedString(@" %lld mins", @"how long a bus layover will be"), mins ];
	}
	
	if (secs > 0)
	{
		[str appendFormat:NSLocalizedString(@" %02lld secs", @"how long a bus layover will be"), secs ];
	}
	
	return str;
	
}


-(TriMetTime)secondsToArrival
{
	
	return TriMetToUnixTime(self.departureTime - self.queryTime);
}

- (int)minsToArrival
{
	return (int)(self.secondsToArrival / 60);
}

-(NSString *)formatDistance:(TriMetDistance)distance
{
	NSString *str = nil;
	if (distance < 500)
	{
		str = [NSString stringWithFormat:NSLocalizedString(@"%lld ft (%lld meters)", @"distance of bus or train"), distance,
			   (TriMetDistance)(distance / 3.2808398950131235) ];
	}
	else
	{
		str = [NSString stringWithFormat:NSLocalizedString(@"%.2f miles (%.2f km)", @"distance of bus or train"), (float)(distance / 5280.0),
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
#define BLOCK_COLOR_TAG 8
#define CANCELED_OVERLAY 9

- (UILabel*)label:(UITableViewCell*)cell tag:(NSInteger)tag
{
	return ((UILabel*)[cell.contentView viewWithTag:tag]);
}

- (NSString *)cellReuseIdentifier:(NSString *)identifier width:(ScreenType)width
{
	return [NSString stringWithFormat:@"%@-%d", identifier, width];
}

typedef struct _DepartureCellAttributes
{
    CGFloat LeftColumnOffset;
    CGFloat LeftColumnWidth;
    CGFloat ShortLeftColumnWidth;
    CGFloat LongLeftColumnWidth;
    
    CGFloat MinsLeft;
    CGFloat MinsWidth;
    CGFloat MinsHeight;
    CGFloat MinsUnitHeight;
    
    CGFloat MainFontSize;
    CGFloat BigMinsFontSize;
    CGFloat UnitFontSize;
    CGFloat LabelHeight;
    CGFloat TimeFontSize;
    CGFloat RowHeight;
    CGFloat MinsGap;
    CGFloat RowGap;
    CGFloat BlockColorGap;
    CGFloat BlockColorWidth;
    CGFloat BlockColorHeight;
    
} DepartureCellAttributes;

- (void)initDepartureCellAttributesWithWidth:(ScreenType)width attribures:(DepartureCellAttributes *)attr
{
    attr->LeftColumnOffset			= 11.0;
    attr->LeftColumnWidth			= 280.0;
    attr->ShortLeftColumnWidth		= 254.0;
    attr->LongLeftColumnWidth		= 300.0;
    attr->MinsLeft					= 266.0;
    
    attr->MinsWidth					= 30.0;
    attr->MinsHeight			    = 26.0;
    attr->MinsUnitHeight			= 16.0;
    
    attr->MainFontSize				= 18.0;
    attr->BigMinsFontSize			= 24.0;
    attr->UnitFontSize				= 14.0;
    attr->LabelHeight				= 26.0;
    attr->TimeFontSize				= 14.0;
    attr->RowHeight					= kDepartureCellHeight;
    attr->MinsGap                   = ((attr->RowHeight - attr->MinsHeight - attr->MinsUnitHeight) / 3.0);
    attr->RowGap                    = ((attr->RowHeight - attr->LabelHeight - attr->LabelHeight) / 3.0);
    attr->BlockColorGap             = 2;
    attr->BlockColorWidth           = 15;
    attr->BlockColorHeight          = attr->RowHeight - 5;
    
    
    switch (width)
    {
        default:
        case WidthiPhone:
            break;
        case WidthiPhone6:
            attr->MinsLeft                 += 54;
            attr->ShortLeftColumnWidth     += 54;
            attr->UnitFontSize             = 15.0;
            break;
        case WidthiPhone6Plus:
            attr->MinsLeft                 += 84;
            attr->ShortLeftColumnWidth     += 84;
            attr->UnitFontSize             = 15.0;
            break;
        case WidthiPadWide:
        case WidthiPadNarrow:
            attr->RowHeight				= kWideDepartureCellHeight;
            attr->LeftColumnOffset		= 16.0;
            attr->LeftColumnWidth		= 560.0;
            
            if (width == WidthiPadWide)
            {
                attr->LongLeftColumnWidth	= 900.0;
            }
            else
            {
                attr->LongLeftColumnWidth	= 640.0;
            }
            attr->ShortLeftColumnWidth   = (attr->LongLeftColumnWidth + 10.0);
            attr->MinsLeft				= (attr->LongLeftColumnWidth + 30.0);
            
            attr->MinsWidth				= 60.0;
            attr->MinsHeight			= 45.0;
            attr->MinsUnitHeight		= 28.0;
            
            
            attr->MainFontSize			= 32.0;
            attr->BigMinsFontSize		= 44.0;
            attr->UnitFontSize			= 28.0;
            attr->LabelHeight			= 43.0;
            attr->TimeFontSize			= 28.0;
            
            attr->MinsGap				= ((kWideDepartureCellHeight - attr->MinsHeight -  attr->MinsUnitHeight) / 3.0);
            attr->RowGap					= ((kWideDepartureCellHeight - attr->LabelHeight - attr->LabelHeight) / 3.0);
            attr->BlockColorHeight      = 70;
            
            break;
    }
    
}


- (UITableViewCell *)bigTableviewCellWithReuseIdentifier:(NSString *)identifier width:(ScreenType)width
{
    DepartureCellAttributes attr;
    
    [self initDepartureCellAttributesWithWidth:width attribures:&attr];
    
    
    /*
     Create an instance of UITableViewCell and add tagged subviews for the name, local time, and quarter image of the time zone.
     */
    CGRect rect;
    
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
    
    
    /*
     Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
     */
    UILabel *label;
    CanceledBusOverlay *canceled;
    
    rect = CGRectMake(attr.MinsLeft+attr.MinsWidth+attr.BlockColorGap, (attr.RowHeight - attr.BlockColorHeight)/2, attr.BlockColorWidth, attr.BlockColorHeight);
    UIView *blockColor = [[UIView alloc] initWithFrame:rect];
    blockColor.tag = BLOCK_COLOR_TAG;
    [cell.contentView addSubview:blockColor];
    [blockColor release];
    
    rect = CGRectMake(attr.LeftColumnOffset, attr.MinsGap, attr.ShortLeftColumnWidth, attr.LabelHeight);
    label = [[UILabel alloc] initWithFrame:rect];
    label.tag = ROUTE_TAG;
    label.font = [UIFont boldSystemFontOfSize:attr.MainFontSize];
    label.adjustsFontSizeToFitWidth = YES;
    [cell.contentView addSubview:label];
    label.highlightedTextColor = [UIColor whiteColor];
    [label release];
    
    rect = CGRectMake(0, attr.MinsGap, COLOR_STRIPE_WIDTH, attr.LabelHeight);
    RouteColorBlobView *colorStripe = [[RouteColorBlobView alloc] initWithFrame:rect];
    colorStripe.tag = COLOR_STRIPE_TAG;
    [cell.contentView addSubview:colorStripe];
    [colorStripe release];
    
    rect = CGRectMake(attr.LeftColumnOffset, attr.MinsGap+attr.MinsHeight+attr.MinsGap, attr.ShortLeftColumnWidth, attr.MinsUnitHeight);
    label = [[UILabel alloc] initWithFrame:rect];
    label.tag = TIME_TAG;
    label.font = [UIFont systemFontOfSize:attr.UnitFontSize];
    label.adjustsFontSizeToFitWidth = YES;
    [cell.contentView addSubview:label];
    label.highlightedTextColor = [UIColor whiteColor];
    [label release];
    
    
    label = [[UILabel alloc] initWithFrame:rect];
    label.tag = SCHEDULED_TAG;
    label.font = [UIFont systemFontOfSize:attr.UnitFontSize];
    label.adjustsFontSizeToFitWidth = YES;
    [cell.contentView addSubview:label];
    label.highlightedTextColor = [UIColor whiteColor];
    [label release];
    
    label = [[UILabel alloc] initWithFrame:rect];
    label.tag = DETOUR_TAG;
    label.font = [UIFont systemFontOfSize:attr.UnitFontSize];
    label.adjustsFontSizeToFitWidth = YES;
    [cell.contentView addSubview:label];
    label.highlightedTextColor = [UIColor whiteColor];
    [label release];
    
    rect = CGRectMake(attr.MinsLeft, attr.MinsGap, attr.MinsWidth, attr.MinsHeight);
    label = [[UILabel alloc] initWithFrame:rect];
    label.tag = BIG_MINS_TAG;
    label.font = [UIFont boldSystemFontOfSize:attr.BigMinsFontSize];
    label.adjustsFontSizeToFitWidth = YES;
    [cell.contentView addSubview:label];
    label.highlightedTextColor = [UIColor whiteColor];
    [label release];
    
    canceled = [[CanceledBusOverlay alloc] initWithFrame:rect];
    canceled.tag = CANCELED_OVERLAY;
    [cell.contentView addSubview:canceled];
    canceled.backgroundColor = [UIColor clearColor];
    canceled.hidden = YES;
    [canceled release];
    
    rect = CGRectMake(attr.MinsLeft, attr.MinsGap+attr.MinsHeight+attr.MinsGap, attr.MinsWidth, attr.MinsUnitHeight);
    label = [[UILabel alloc] initWithFrame:rect];
    label.tag = BIG_UNIT_TAG;
    label.font = [UIFont systemFontOfSize:attr.UnitFontSize];
    label.adjustsFontSizeToFitWidth = YES;
    [cell.contentView addSubview:label];
    label.highlightedTextColor = [UIColor whiteColor];
    [label release];
    
    return cell;
}

- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier spaceToDecorate:(bool)spaceToDecorate width:(ScreenType)width
{
    DepartureCellAttributes attr;
    
    [self initDepartureCellAttributesWithWidth:width attribures:&attr];
    
    
    /*
     Create an instance of UITableViewCell and add tagged subviews for the name, local time, and quarter image of the time zone.
     */
    CGRect rect;
    
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
    
    
    /*
     Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
     */
    UILabel *label;
    
    
    rect = CGRectMake(attr.MinsLeft+attr.MinsWidth+attr.BlockColorGap, (attr.RowHeight - attr.BlockColorHeight)/2, attr.BlockColorWidth, attr.BlockColorHeight);
    UIView *blockColor = [[UIView alloc] initWithFrame:rect];
    blockColor.tag = BLOCK_COLOR_TAG;
    [cell.contentView addSubview:blockColor];
    [blockColor release];
    
    rect = CGRectMake(attr.LeftColumnOffset, attr.RowGap, spaceToDecorate? attr.LeftColumnWidth : attr.LongLeftColumnWidth, attr.LabelHeight);
    label = [[UILabel alloc] initWithFrame:rect];
    label.tag = ROUTE_TAG;
    label.font = [UIFont boldSystemFontOfSize:attr.MainFontSize];
    label.adjustsFontSizeToFitWidth = YES;
    [cell.contentView addSubview:label];
    label.highlightedTextColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    [label release];
    
    rect = CGRectMake(0, attr.RowGap, COLOR_STRIPE_WIDTH, attr.LabelHeight);
    RouteColorBlobView *colorStripe = [[RouteColorBlobView alloc] initWithFrame:rect];
    colorStripe.tag = COLOR_STRIPE_TAG;
    [cell.contentView addSubview:colorStripe];
    [colorStripe release];
    
    rect = CGRectMake(attr.LeftColumnOffset,attr.RowGap * 2.0 + attr.LabelHeight, spaceToDecorate? attr.LeftColumnWidth : attr.LongLeftColumnWidth, attr.LabelHeight);
    label = [[UILabel alloc] initWithFrame:rect];
    label.tag = TIME_TAG;
    label.font = [UIFont systemFontOfSize:attr.TimeFontSize];
    label.adjustsFontSizeToFitWidth = YES;
    [cell.contentView addSubview:label];
    label.highlightedTextColor = [UIColor whiteColor];
    [label release];
    
    label = [[UILabel alloc] initWithFrame:rect];
    label.tag = SCHEDULED_TAG;
    label.font = [UIFont systemFontOfSize:attr.UnitFontSize];
    label.adjustsFontSizeToFitWidth = YES;
    [cell.contentView addSubview:label];
    label.highlightedTextColor = [UIColor whiteColor];
    [label release];
    
    label = [[UILabel alloc] initWithFrame:rect];
    label.tag = DETOUR_TAG;
    label.font = [UIFont systemFontOfSize:attr.UnitFontSize];
    label.adjustsFontSizeToFitWidth = YES;
    [cell.contentView addSubview:label];
    label.highlightedTextColor = [UIColor whiteColor];
    [label release];
    
    
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

- (void)populateCell:(UITableViewCell *)cell decorate:(BOOL)decorate big:(BOOL)big busName:(BOOL)busName wide:(BOOL)wide
{
    [self populateCellAndGetExplaination:cell decorate:decorate big:big busName:busName wide:wide color:nil details:nil];
}


- (void)getExplaination:(UIColor **)color details:(NSString **)details
{
    [self populateCellAndGetExplaination:nil decorate:NO big:NO busName:NO wide:NO color:color details:details];
}



- (void)populateCellAndGetExplaination:(UITableViewCell *)cell decorate:(BOOL)decorate big:(BOOL)big busName:(BOOL)busName wide:(BOOL)wide color:(UIColor **)color details:(NSString **)details;
{
	if ([self errorMessage] !=nil)
	{
        if (cell!=nil)
        {
            [self label:cell tag:ROUTE_TAG].text = [self errorMessage];
            [self label:cell tag:TIME_TAG].text = nil;
            if (big)
            {
                [self label:cell tag:BIG_MINS_TAG].hidden = YES;
                [self label:cell tag:BIG_UNIT_TAG].hidden = YES;
            }
        }
        
        if (details != nil)
        {
            *details = NSLocalizedString(@"There was an error getting the arrival data.", @"Error explaination");
            *color   = [UIColor orangeColor];
        }
	}
	else
    {
        UIColor *timeColor = nil;
        UILabel *minsView  = nil;
        
        if (cell!=nil)
        {
            cell.textLabel.text = nil;
            minsView = [self label:cell tag:BIG_MINS_TAG];
        }
        //if (decorate)
        //{
        //	((UILabel*)[cell.contentView viewWithTag:ROUTE_TAG]).text = self.routeName;
        //}
        //else
        
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
        
        if (cell!=nil)
        {
            UIView * blockColor = [cell.contentView viewWithTag:BLOCK_COLOR_TAG];
            blockColor.backgroundColor = [[BlockColorDb getSingleton] colorForBlock:self.block];
        }
        
        if (big)
        {
            /* if (self.hasBlock)
             {
             [text appendFormat:@"(%@) ", self.block];
             } */
            
            if (mins < 0)
            {
                minsText = @"-";
                unitText = NSLocalizedString(@"gone", @"text displayed for arrival time if the bus has gone already");
                [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
                [timeText appendString:@" "];
                timeColor = [UIColor blackColor];
            }
            else if (mins == 0)
            {
                minsText = NSLocalizedString(@"Due", @"first line of text to display when bus is due");
                unitText = NSLocalizedString(@"now", @"second line of test to display when bus is due");
                [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
                [timeText appendString:@" "];
                timeColor = [UIColor redColor];
            }
            else if (mins == 1)
            {
                minsText = NSLocalizedString(@"1", @"first line of text to display when bus is due in 1 minute");
                unitText = NSLocalizedString(@"min", @"second line of text to display when bus is due in 1 minute");
                [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
                [timeText appendString:@" "];
                timeColor = [UIColor redColor];
            }
            else if (mins < 6)
            {
                minsText = [NSString stringWithFormat:@"%lld", mins];
                unitText = NSLocalizedString(@"mins", @"plural number of minutes to display for bus arrival time");
                [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
                [timeText appendString:@" "];
                timeColor = [UIColor redColor];
                
              
            }
            else if (mins < 60)
            {
                minsText = [NSString stringWithFormat:@"%lld", mins];
                unitText = NSLocalizedString(@"mins", @"plural number of minutes to display for bus arrival time");
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
            if (mins < 0 && self.status != kStatusCancelled)
            {
                [timeText appendString:NSLocalizedString(@"Gone - ", @"first part of text to display on a single line if a bus has gone")];
                [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
                [timeText appendString:@" "];
                timeColor = [UIColor redColor];
                
                if (details && color)
                {
                    *details = kVehicleDepartedText;
                    *color   = [UIColor blackColor];
                }
            }
            else if (mins == 0 && self.status != kStatusCancelled)
            {
                [timeText appendString:NSLocalizedString(@"Due - ", @"first part of text to display on a single line if a bus is due")];
                [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
                [timeText appendString:@" "];
                timeColor = [UIColor redColor];
                
                if (details && color)
                {
                    *details = kVehicleSoonText;
                    *color   = [UIColor redColor];
                }
            }
            else if (mins == 1 && self.status != kStatusCancelled)
            {
                [timeText appendString:NSLocalizedString(@"1 min - ", @"first part of text to display on a single line if a bus is due in 1 minute")];
                [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
                [timeText appendString:@" "];
                timeColor = [UIColor redColor];
                
                if (details && color)
                {
                    *details = kVehicleSoonText;
                    *color   = [UIColor redColor];
                }
            }
            else if (mins < 6 && self.status != kStatusCancelled)
            {
                [timeText appendFormat:NSLocalizedString(@"%lld mins - ", @"first part of text to display on a single line if a bus is due in several minutes"), mins];
                [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
                [timeText appendString:@" "];
                timeColor = [UIColor redColor];
                
                if (details && color)
                {
                    *details = kVehicleSoonText;
                    *color   = [UIColor redColor];
                }

            }
            else if (mins < 60 && self.status != kStatusCancelled)
            {
                [timeText appendFormat:NSLocalizedString(@"%lld mins - ", @"first part of text to display on a single line if a bus is due in several minutes"), mins];
                [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
                [timeText appendString:@" "];
                timeColor = [UIColor blueColor];
                
                
                if (details && color)
                {
                    *details = kVehicleComingText;
                    *color   = [UIColor blueColor];
                }
            }
            else
            {
                [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
                [timeText appendString:@" "];
                timeColor = [UIColor blueColor];
                
                
                if (details && color)
                {
                    *details = kVehicleLongText;
                    *color   = [UIColor blueColor];
                }
                
            }
        }
        
        CanceledBusOverlay *canceled = nil;
        
        if (cell!=nil)
        {
            canceled = (CanceledBusOverlay*)[cell.contentView viewWithTag:CANCELED_OVERLAY];
        }
        
        if (canceled!=nil)
        {
            canceled.hidden = YES;
        }
        
        switch (self.status)
        {
            case kStatusEstimated:
                break;
            case kStatusScheduled:
                [scheduledText appendFormat:NSLocalizedString(@"scheduled ", @"info about arrival time")];
                timeColor = [UIColor grayColor];
                
                if (details && color)
                {
                    *details = kVehicleScheduled;
                    *color   = [UIColor grayColor];
                }
                
                break;
            case kStatusCancelled:
                [detourText appendFormat:NSLocalizedString(@"canceled ", @"info about arrival time")];
                timeColor = [UIColor orangeColor];
                if (canceled!=nil)
                {
                    canceled.hidden = NO;
                }
                
                if (details && color)
                {
                    *details = kVehicleCanceled;
                    *color   = [UIColor grayColor];
                }

                break;
            case kStatusDelayed:
                [detourText appendFormat:NSLocalizedString(@"delayed ",  @"info about arrival time")];
                timeColor = [UIColor yellowColor];
                
                if (details && color)
                {
                    *details = kVehicleDelayed;
                    *color   = [UIColor yellowColor];
                }
                break;
        }
        
        if (canceled!=nil)
        {
            [canceled setNeedsDisplay];
        }
        
        if (self.status != kStatusScheduled && self.scheduledTime !=0 && (self.scheduledTime/60000) != (self.departureTime/60000))
        {
            NSDate *scheduledDate = [NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime(self.scheduledTime)];
            [scheduledText appendFormat:NSLocalizedString(@"scheduled %@ ",@"info about arrival time"), [dateFormatter stringFromDate:scheduledDate]];;
            
            if (details)
            {
                NSString *old = *details;
                *details = [NSString stringWithFormat:@"%@ %@", old, kVehicleLate];
            }
        }
        
        if (self.detour)
        {
            [detourText appendFormat:NSLocalizedString(@"detour",@"info about arrival time")];
        }
        
        
        if (cell!=nil)
        {
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

- (void)populateTripCell:(UITableViewCell *)cell item:(NSInteger)item
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
			[self label:cell tag:ROUTE_TAG].text = [NSString stringWithFormat:NSLocalizedString(@"Current trip: %@", @"trip details"), trip.name];
			[self label:cell tag:ROUTE_TAG].textColor = [UIColor blackColor];
			timeText = [NSString stringWithFormat:NSLocalizedString(@"%@ left to go", @"distance remaining"), [self formatDistance:(int)toGo]];
			timeColor = [UIColor blueColor];
		}
		else
		{
			[self label:cell tag:ROUTE_TAG].text = [NSString stringWithFormat:NSLocalizedString(@"Trip: %@", @"name of trip"), trip.name];
			[self label:cell tag:ROUTE_TAG].textColor = [UIColor blackColor];
			timeText = [NSString stringWithFormat:NSLocalizedString(@"%@ total", @"total distance"), [self formatDistance:(int)toGo]];
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
			timeText = [NSString stringWithFormat:NSLocalizedString(@"Layover at %@ remaining: %@", @"bus waiting at <location> for a <time>"),
							 [dateFormatter stringFromDate:startLayover],  [self formatLayoverTime:toGo]];
			timeColor = [UIColor blueColor];
		}
		else
		{
			NSMutableString *str = [[[NSMutableString alloc] init] autorelease];
			toGo = trip.endTime - trip.startTime;
			
			[str appendFormat:NSLocalizedString(@"Layover at %@", @"waiting starting at <time>"), [dateFormatter stringFromDate:startLayover]];
			[str appendFormat:NSLocalizedString(@" for%@", @"waiting for length of time"), [self formatLayoverTime:toGo]];
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

- (bool)showActionMenu
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
			[text appendFormat:NSLocalizedString(@"Due - %@ at %@", @"bus due <time> at <location>"), [dateFormatter stringFromDate:depatureDate], loc];
		}
		else if (mins == 1)
		{
			[text appendFormat:NSLocalizedString(@"1 min - %@ to %@",@"bus due <time> at <location>"), [dateFormatter stringFromDate:depatureDate], loc];
		}
		else if (mins < 60)
		{
			[text appendFormat:NSLocalizedString(@"%lld mins - %@ to %@ ", @"in <mins> minutes bus is due <time> at <location>"), mins, [dateFormatter stringFromDate:depatureDate], loc];
		} 
		else
		{			
			[text appendFormat:NSLocalizedString(@"%@ to %@", @"at <time> bus will arrival at <location>"), [dateFormatter stringFromDate:depatureDate], loc];
		}
	}
	
	return text;
	
}

- (MKPinAnnotationColor) getPinColor
{
	return MKPinAnnotationColorPurple;
}

@end
