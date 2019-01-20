//
//  Departure.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureData+iOSUI.h"
#import "DepartureTrip.h"

#import "ViewControllerBase.h"
#import "TriMetInfo.h"
#import "RouteColorBlobView.h"
#import "DebugLogging.h"
#import "BlockColorDb.h"
#import "CanceledBusOverlay.h"
#import "FormatDistance.h"
#import "ArrivalColors.h"
#import "StringHelper.h"

#define kVehicleDepartedText      NSLocalizedString(@"#0The time is shown in #bblack#b as the vehicle has departed.",                                                             @"Infomation text")
#define kVehicleOffRouteText      NSLocalizedString(@"#YThe time is shown in #byellow#b as the vehicle is off route.",                                                             @"Infomation text")
#define kVehicleSoonText          NSLocalizedString(@"#RThe time is shown in #bred#b as the vehicle will depart in 5 minutes or less.",                                           @"Infomation text")
#define kVehicleLateText          NSLocalizedString(@"#MThe time is shown in #bmagenta#b as the vehicle is late.",                                                                 @"Infomation text")
#define kVehicleComingText        NSLocalizedString(@"#BThe time is shown in #bblue#b as the vehicle will depart in more than 5 minutes.",                                        @"Infomation text")
#define kVehicleLongText          kVehicleComingText
#define kVehicleScheduled         NSLocalizedString(@"#AThe time is shown in #bgray#b as no location infomation is available - the scheduled time is shown.",                     @"Infomation text")
#define kVehicleCanceled          NSLocalizedString(@"#OThe time is shown in #borange#b and crossed out as the vehicle was canceled.  #AThe original scheduled time is shown for reference.",     @"Infomation text")
#define kVehicleDelayed           NSLocalizedString(@"#YThe Time is shown in #byellow#b as the vehicle is delayed.",                                                              @"Infomation text")
#define kVehicleNotToSchedule     NSLocalizedString(@"#AThe scheduled time is also shown in #bgray#b as the vehicle is not running to schedule.",                                 @"Infomation text")
#define kVehicleNotToScheduleLate NSLocalizedString(@"#AThe scheduled time is also shown in #bgray#b.",                                                                          @"Infomation text")


@implementation DepartureData (iOSUI)

#pragma mark User Interface



- (void)populateCell:(DepartureCell *)cell decorate:(BOOL)decorate busName:(BOOL)busName wide:(BOOL)wide
{
    [self populateCellAndGetExplaination:cell decorate:decorate busName:busName wide:wide details:nil];
}


- (NSString *)getFormattedExplaination
{
    NSString *str = nil;
    [self populateCellAndGetExplaination:nil decorate:NO busName:NO wide:NO details:&str];
    
    return str;
}

- (NSString*)padding:(NSString **)formattedDetails
{
    NSString *pad = @"";
    if (*formattedDetails == nil)
    {
        *formattedDetails = @"";
    }
    else
    {
        pad = @"\n";
    }
    
    return pad;
}

- (void)populateCellAndGetExplaination:(DepartureCell *)cell decorate:(BOOL)decorate busName:(BOOL)busName wide:(BOOL)wide details:(NSString **)formattedDetails;
{
    if (self.errorMessage != nil)
    {
        if (cell!=nil)
        {
            cell.routeLabel.text = self.errorMessage;
            cell.timeLabel.text = nil;
            cell.scheduledLabel.text = nil;
            cell.detourLabel.text = nil;
            cell.fullLabel.text = nil;
            
            cell.minsLabel.hidden = YES;
            cell.unitLabel.hidden = YES;
            [cell.routeColorView setRouteColor:nil];
            
        
            

        }
        
        if (formattedDetails != nil)
        {
            *formattedDetails = NSLocalizedString(@"#OThere was an error getting the arrival data.", @"Error explaination");
        }
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else
    {
        UIColor *timeColor = nil;
        UILabel *minsView  = nil;
        
        if (cell!=nil)
        {
            cell.textLabel.text = nil;
            minsView = cell.minsLabel;
        }
        //if (decorate)
        //{
        //    ((UILabel*)[cell.contentView viewWithTag:ROUTE_TAG]).text = self.routeName;
        //}
        //else
        
        TriMetTime mins = MinsBetweenDates(self.departureTime, self.queryTime);

        
        NSDate *depatureDate = self.departureTime;
        NSMutableString *timeText = [NSMutableString string];
        NSMutableString *scheduledText = [NSMutableString string];
        NSMutableString *detourText = [NSMutableString string];
        NSMutableString *fullText = [NSMutableString string];
        NSString *minsText = nil;
        NSString *unitText = nil;
        ArrivalWindow arrivalWindow;
        
        NSDateFormatter *dateFormatter = [self dateAndTimeFormatterWithPossibleLongDateStyle:kLongDateFormat arrivalWindow:&arrivalWindow];
        
        
        if (cell!=nil)
        {
            cell.blockColorView.color = [[BlockColorDb sharedInstance] colorForBlock:self.block];
        }

        
        /* if (self.hasBlock)
         {
         [text appendFormat:@"(%@) ", self.block];
         } */
        
        if ((mins < 0 || self.invalidated) && !self.offRoute)
        {
            minsText = NSLocalizedString(@"--", @"DNL");
            unitText = NSLocalizedString(@"gone", @"text displayed for arrival time if the bus has gone already");
            [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
            [timeText appendString:@" "];
            timeColor = ArrivalColorDeparted;
            
            if (formattedDetails)
            {
                *formattedDetails = kVehicleDepartedText;
            }
        }
        else if ((mins < 0 || self.invalidated) && self.offRoute)
        {
            minsText = NSLocalizedString(@"OFF  ", @"off route");
            unitText = NSLocalizedString(@"ROUTE", @"ff route");
            [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
            [timeText appendString:@" "];
            timeColor = ArrivalColorOffRoute;
            
            if (formattedDetails)
            {
                *formattedDetails = kVehicleOffRouteText;
            }
            
        }
        else if (mins == 0)
        {
            minsText = NSLocalizedString(@"Due", @"first line of text to display when bus is due");
            unitText = NSLocalizedString(@"now", @"second line of test to display when bus is due");
            [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
            [timeText appendString:@" "];
            
            if (self.actuallyLate)
            {
                timeColor = ArrivalColorLate;
                
                if (formattedDetails)
                {
                    *formattedDetails = kVehicleLateText;
                }
            }
            else
            {
                timeColor = ArrivalColorSoon;
                
                if (formattedDetails)
                {
                    *formattedDetails = kVehicleSoonText;
                }
            }
        }
        else if (mins == 1)
        {
            minsText = NSLocalizedString(@"1", @"first line of text to display when bus is due in 1 minute");
            unitText = NSLocalizedString(@"min", @"second line of text to display when bus is due in 1 minute");
            [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
            [timeText appendString:@" "];
            
            if (self.actuallyLate)
            {
                timeColor = ArrivalColorLate;
                
                if (formattedDetails)
                {
                    *formattedDetails = kVehicleLateText;
                }
            }
            else
            {
                timeColor = ArrivalColorSoon;
                
                if (formattedDetails)
                {
                    *formattedDetails = kVehicleSoonText;
                }
            }
        }
        else if (mins < 6)
        {
            minsText = [NSString stringWithFormat:@"%lld", mins];
            unitText = NSLocalizedString(@"mins", @"plural number of minutes to display for bus arrival time");
            [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
            [timeText appendString:@" "];
            
            if (self.actuallyLate)
            {
                timeColor = ArrivalColorLate;
                
                if (formattedDetails)
                {
                   *formattedDetails = kVehicleLateText;
                }
            }
            else
            {
                timeColor = ArrivalColorSoon;
                
                if (formattedDetails)
                {
                  *formattedDetails = kVehicleSoonText;
                }
            }
        }
        else if (mins < 60)
        {
            minsText = [NSString stringWithFormat:@"%lld", mins];
            unitText = NSLocalizedString(@"mins", @"plural number of minutes to display for bus arrival time");
            [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
            [timeText appendString:@" "];
            
            if (self.actuallyLate)
            {
                timeColor = ArrivalColorLate;
                
                if (formattedDetails)
                {
                    *formattedDetails = kVehicleLateText;
                }
            }
            else
            {
                timeColor = ArrivalColorOK;
                
                if (formattedDetails)
                {
                   *formattedDetails = kVehicleComingText;
                }
            }
        }
        else
        {
            switch (arrivalWindow)
            {
                case ArrivalThisWeek:
                {
                    NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
                    dayFormatter.dateStyle = kCFDateFormatterMediumStyle;
                    dayFormatter.timeStyle = NSDateFormatterNoStyle;
                
                    dayFormatter.dateFormat = @"E";
                    minsText = [dayFormatter stringFromDate:depatureDate];
                    dayFormatter.dateFormat = @"a";
                    unitText = [dayFormatter stringFromDate:depatureDate];
                    break;
                }
                case ArrivalSoon:
                {
                    NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
                    dayFormatter.dateStyle = kCFDateFormatterMediumStyle;
                    dayFormatter.timeStyle = NSDateFormatterNoStyle;
                
                    dayFormatter.dateFormat = @"h:mm";
                    minsText = [dayFormatter stringFromDate:depatureDate];
                    dayFormatter.dateFormat = @"a";
                    unitText = [dayFormatter stringFromDate:depatureDate];
                    break;
                }
                default:
                case ArrivalNextWeek:
                    minsText = @":::";
                    unitText = @":::";
                    break;
            }
            
            [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
            [timeText appendString:@" "];
            
            
            if (self.actuallyLate)
            {
                timeColor = ArrivalColorLate;
                
                if (formattedDetails)
                {
                    *formattedDetails = kVehicleLateText;
                }
            }
            else
            {
                timeColor = ArrivalColorOK;
                
                if (formattedDetails)
                {
                    *formattedDetails = kVehicleLongText;
                }
            }
        }
        
        CanceledBusOverlay *canceled = nil;
        
        if (cell!=nil)
        {
            canceled = cell.cancelledOverlayView;
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
                [scheduledText appendString:NSLocalizedString(@"scheduled ", @"info about arrival time")];
                timeColor = ArrivalColorScheduled;
                
                if (formattedDetails)
                {
                    *formattedDetails = kVehicleScheduled;
                }
                
                break;
            case kStatusCancelled:
                [detourText appendString:NSLocalizedString(@"canceled ", @"info about arrival time")];
                timeColor = ArrivalColorCancelled;
                if (canceled!=nil)
                {
                    canceled.hidden = NO;
                }
                
                if (formattedDetails)
                {
                    *formattedDetails = kVehicleCanceled;
                }
                
                break;
            case kStatusDelayed:
                [detourText appendString:NSLocalizedString(@"delayed ",  @"info about arrival time")];
                timeColor = ArrivalColorDelayed;
                
                if (formattedDetails)
                {
                    *formattedDetails = kVehicleDelayed;
                }
                break;
        }
        
        if (canceled!=nil)
        {
            [canceled setNeedsDisplay];
        }
        
        if (self.notToSchedule)
        {
            [scheduledText appendFormat:NSLocalizedString(@"scheduled %@ ",@"info about arrival time"), [dateFormatter stringFromDate:self.scheduledTime]];;
            
            if (formattedDetails)
            {
                NSString *old = *formattedDetails;
                *formattedDetails = [NSString stringWithFormat:@"%@ %@", old, self.actuallyLate ? kVehicleNotToScheduleLate
                                                                                               : kVehicleNotToSchedule];
            }
        }
        
        if (self.detour)
        {
            if (self.detours.count == 1)
            {
                [detourText appendString:NSLocalizedString(@"⚠️alert ",@"info about arrival time")];
            }
            else
            {
                 [detourText appendString:NSLocalizedString(@"⚠️alerts ",@"info about arrival time")];
            }
        }
        
        if (self.loadPercentage > 0)
        {
             [fullText appendFormat:NSLocalizedString(@"%d%% full ",  @"info about arrival time"),
                (int)self.loadPercentage];
        }
        
        if (formattedDetails && self.reason)
        {
            NSString *pad = [self padding:formattedDetails];
            *formattedDetails = [NSString stringWithFormat:@"%@%@#b#OStatus:\"%@#b.\"", *formattedDetails, pad, self.reason];
        }
        
        
        if (formattedDetails && self.loadPercentage > 0)
        {
            NSString *pad = [self padding:formattedDetails];
            *formattedDetails = [NSString stringWithFormat:@"%@%@#b#0The vehicle is loaded to %d%% of capacity#b.",*formattedDetails, pad, (int)self.loadPercentage];
        }
        
        
        if (formattedDetails && self.dropOffOnly)
        {
            NSString *pad = [self padding:formattedDetails];
            *formattedDetails = [NSString stringWithFormat:@"%@%@#b#RDrop off only#0#b",*formattedDetails, pad];
        }
        
        if (formattedDetails && self.offRoute)
        {
            NSString *pad = [self padding:formattedDetails];
            *formattedDetails = [NSString stringWithFormat:@"%@%@#b#RThe vehicle is off route.#0#b",*formattedDetails, pad];
        }
        
        
        if (cell!=nil)
        {
            UILabel * unitView = cell.unitLabel;
            
            if (minsText !=nil)
            {
                minsView.text = minsText;
                minsView.hidden = NO;
                minsView.textAlignment = NSTextAlignmentCenter;
                minsView.textColor = timeColor;
                
                unitView.textColor = timeColor;
                unitView.text = unitText;
                unitView.hidden = NO;
                unitView.textAlignment = NSTextAlignmentCenter;
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
    
            cell.routeLabel.hidden = NO;
            
            // Layout the time text, scheduled text and detour text all in a row
            
            cell.timeLabel.text = timeText;
            cell.timeLabel.textColor = timeColor;
            
            cell.scheduledLabel.text = scheduledText;
            cell.scheduledLabel.textColor = [UIColor grayColor];
            
            cell.detourLabel.text = detourText;
            cell.detourLabel.textColor = [UIColor orangeColor];
            
            cell.fullLabel.text = fullText;
            cell.fullLabel.textColor = [UIColor blackColor];
            
            if (busName)
            {
                if (wide)
                {
                    cell.routeLabel.text = self.fullSign;
                }
                else
                {
                    cell.routeLabel.text = self.shortSign;
                }
            }
            else
            {
                cell.routeLabel.text = self.locationDesc;
            }
            
            
            cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@ %@, %@ %@ %@",
                                         cell.routeLabel.text.phonetic, minsText, unitText, timeText, scheduledText, detourText];
        }

        [cell.routeColorView setRouteColor:self.route];
    }
    
}




- (void)populateCellGeneric:(DepartureCell *)cell first:(NSString *)first second:(NSString *)second col1:(UIColor *)col1 col2:(UIColor *)col2;

{
    cell.routeLabel.text = first;
    cell.routeLabel.textColor = col1;
    cell.routeLabel.hidden = NO;
    cell.timeLabel.text = second;
    cell.timeLabel.textColor = col2;
    cell.routeColorView.hidden = YES;
    cell.scheduledLabel.text = nil;
    cell.detourLabel.text = nil;
    cell.fullLabel.text = nil;
}

- (void)populateTripCell:(DepartureCell *)cell item:(NSInteger)item
{
    DepartureTrip * trip = self.trips[item];
    
    cell.textLabel.text = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    
    NSString *timeText = nil;
    UIColor *timeColor = nil;
    cell.minsLabel.hidden = YES;
    cell.unitLabel.hidden = YES;

    cell.routeLabel.hidden = NO;
    
    if (trip.distance > 0)
    {
        TriMetDistance toGo = trip.distance - trip.progress;
        
        if (trip.progress > 0)
        {
            cell.routeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Current trip: %@", @"trip details"), trip.name];
            cell.routeLabel.textColor = [UIColor blackColor];
            timeText = [NSString stringWithFormat:NSLocalizedString(@"%@ left to go", @"distance remaining"), [FormatDistance formatFeet:(int)toGo]];
            timeColor = [UIColor blueColor];
        }
        else
        {
            cell.routeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Trip: %@", @"name of trip"), trip.name];
            cell.routeLabel.textColor = [UIColor blackColor];
            timeText = [NSString stringWithFormat:NSLocalizedString(@"%@ total", @"total distance"), [FormatDistance formatFeet:(int)toGo]];
            timeColor = [UIColor grayColor];
        }
        cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", 
                                            cell.routeLabel.text.phonetic,
                                            timeText];
    }
    
    if (trip.startTime > 0)
    {
        cell.routeLabel.text = [NSString stringWithFormat:@"%@", trip.name];
        cell.routeLabel.textColor = [UIColor blackColor];
        
        TriMetTime toGo; 
        
        // NSDate *startLayover = trip.startTime;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        
        if ([[dateFormatter stringFromDate:trip.startTime] isEqualToString:[dateFormatter stringFromDate:[NSDate date]]])
        {
            dateFormatter.dateStyle = NSDateFormatterNoStyle;
        }
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
        
        // Ascending measn receiver is earlier.  
        if ([trip.startTime compare:self.queryTime] == NSOrderedAscending  &&  [trip.endTime compare:self.queryTime] == NSOrderedDescending)
        {
            toGo =  [trip.endTime timeIntervalSinceDate:self.queryTime];
            timeText = [NSString stringWithFormat:NSLocalizedString(@"Layover at %@ remaining: %@", @"bus waiting at <location> for a <time>"),
                             [dateFormatter stringFromDate:trip.startTime],  [self formatLayoverTime:toGo]];
            timeColor = [UIColor blueColor];
        }
        else
        {
            NSMutableString *str = [NSMutableString string];
            toGo =   [trip.endTime timeIntervalSinceDate:trip.startTime];
            
            [str appendFormat:NSLocalizedString(@"Layover at %@", @"waiting starting at <time>"), [dateFormatter stringFromDate:trip.startTime]];
            [str appendFormat:NSLocalizedString(@" for%@", @"waiting for length of time"), [self formatLayoverTime:toGo]];
            timeText = str;
            timeColor = [UIColor grayColor];
        }
        cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", 
                                     cell.routeLabel.text.phonetic,
                                        timeText];
        
    }
    
    cell.timeLabel.text = timeText;
    cell.timeLabel.textColor = timeColor;
    cell.scheduledLabel.text = nil;
    cell.detourLabel.text = nil;
    cell.fullLabel.text = nil;
    cell.routeColorView.hidden = YES;
    
    [cell setNeedsLayout];
}


#pragma mark Map callbacks 

- (bool)showActionMenu
{
    return YES;
}

- (DepartureData*)mapDeparture
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
    return self.blockPosition.coordinate;
}

- (NSString *)title
{
    return self.shortSign;
}

- (NSString *)subtitle
{
    NSMutableString *text = [NSMutableString string];
    if (self.errorMessage ==nil)
    {
        TriMetTime mins = MinsBetweenDates(self.departureTime, self.queryTime) ; 
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        // NSDate *depatureDate = self.departureTime;
        NSString *loc = self.locationDesc;
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        
        if ([[dateFormatter stringFromDate:self.departureTime] isEqualToString:[dateFormatter stringFromDate:[NSDate date]]])
        {
            dateFormatter.dateStyle = NSDateFormatterNoStyle;
        }
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
        
        if (mins <= 0)
        {
            [text appendFormat:NSLocalizedString(@"Due - %@ at %@", @"bus due <time> at <location>"), [dateFormatter stringFromDate:self.departureTime], loc];
        }
        else if (mins == 1)
        {
            [text appendFormat:NSLocalizedString(@"1 min - %@ to %@",@"bus due <time> at <location>"), [dateFormatter stringFromDate:self.departureTime], loc];
        }
        else if (mins < 60)
        {
            [text appendFormat:NSLocalizedString(@"%lld mins - %@ to %@ ", @"in <mins> minutes bus is due <time> at <location>"), mins, [dateFormatter stringFromDate:self.departureTime], loc];
        } 
        else
        {            
            [text appendFormat:NSLocalizedString(@"%@ to %@", @"at <time> bus will arrival at <location>"), [dateFormatter stringFromDate:self.departureTime], loc];
        }
    }
    
    return text;
    
}

- (MapPinColorValue)pinColor
{
    return MAP_PIN_COLOR_PURPLE;
}

- (UIColor *)pinTint
{
    return [TriMetInfo colorForRoute:self.route];
}

- (UIColor*)pinSubTint
{
    if (self.block!=nil)
    {
        BlockColorDb *db = [BlockColorDb sharedInstance];
        return [db colorForBlock:self.block];
        
    }
    return nil;
}


- (bool)hasBearing
{
    return self.blockPositionHeading!=nil;
}

- (double)doubleBearing
{
    if ([self hasBearing])
    {
        return self.blockPositionHeading.doubleValue;
    }
    
    return 0.0;
}

@end
