//
//  Departure.m
//  PDXBus
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
#import "NSString+Helper.h"

#define kVehicleDepartedText      NSLocalizedString(@"#DThe time is shown in this color as the vehicle has departed.",                                                            @"Infomation text")
#define kVehicleOffRouteText      NSLocalizedString(@"#OThe time is shown in #borange#b as the vehicle is off route.",                                                            @"Infomation text")
#define kVehicleTrackingError     NSLocalizedString(@"#OThe time is shown in #borange#b as there is an issue tracking the vehicle.",                                              @"Infomation text")
#define kVehicleSoonText          NSLocalizedString(@"#RThe time is shown in #bred#b as the vehicle will depart in 5 minutes or less.",                                           @"Infomation text")
#define kVehicleLateText          NSLocalizedString(@"#MThe time is shown in #bmagenta#b as the vehicle is late.",                                                                @"Infomation text")
#define kVehicleComingText        NSLocalizedString(@"#UThe time is shown in #bblue#b as the vehicle will depart in more than 5 minutes.",                                        @"Infomation text")
#define kVehicleLongText          kVehicleComingText
#define kVehicleScheduled         NSLocalizedString(@"#AThe time is shown in #bgray#b as no location infomation is available - the scheduled time is shown.",                     @"Infomation text")
#define kVehicleCanceled          NSLocalizedString(@"#OThe time is shown in #borange#b and crossed out as the vehicle was canceled.  #AThe original scheduled time is shown for reference.",     @"Infomation text")
#define kVehicleDelayed           NSLocalizedString(@"#OThe Time is shown in #borange#b as the vehicle is delayed.",                                                              @"Infomation text")
#define kVehicleNotToSchedule     NSLocalizedString(@"#AThe scheduled time is also shown in #bgray#b as the vehicle is not running to schedule.",                                 @"Infomation text")
#define kVehicleNotToScheduleLate NSLocalizedString(@"#AThe scheduled time is also shown in #bgray#b.",                                                                           @"Infomation text")

@implementation Departure (iOSUI)

#pragma mark User Interface

- (void)populateCell:(DepartureCell *)cell decorate:(BOOL)decorate busName:(BOOL)busName wide:(BOOL)wide {
    [self populateCellAndGetExplaination:cell decorate:decorate busName:busName wide:wide];
}

- (NSString *)getFormattedExplaination {
    return [self populateCellAndGetExplaination:nil decorate:NO busName:NO wide:NO];;
}

- (NSString *)padding:(NSString *)old {
    NSString *pad = nil;
    
    if (old == nil || old.length == 0) {
        pad = @"";
    } else {
        pad = @"\n";
    }
    
    return pad;
}

- (void)populateErrorMessagbe:(DepartureCell *)cell messageDetails:(NSString **)messageDetails {
    if (cell != nil) {
        cell.routeLabel.text = self.errorMessage;
        cell.timeLabel.text = nil;
        cell.scheduledLabel.text = nil;
        cell.detourLabel.text = nil;
        cell.fullLabel.text = nil;
        
        cell.minsLabel.hidden = YES;
        cell.unitLabel.hidden = YES;
        [cell.routeColorView setRouteColor:nil];
    }
    
    *messageDetails = NSLocalizedString(@"#OThere was an error getting the departure data.", @"Error explaination");
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (int)extrapolation
{
    int extrapolation = abs((int)self.timeAdjustment);
    
    DEBUG_LOGL(extrapolation);
    
    return extrapolation;
}

- (NSString *)populateCellAndGetExplaination:(DepartureCell *)cell decorate:(BOOL)decorate busName:(BOOL)busName wide:(BOOL)wide {
    NSString *messageDetails = @"";
    
    if (self.errorMessage != nil) {
        [self populateErrorMessagbe:cell messageDetails:&messageDetails];
    } else {
        NSDate *depatureDate = self.departureTime;
        TriMetTime mins = MinsBetweenDates(depatureDate, self.queryTime);
        
        UIColor *timeColor = nil;
        NSMutableString *timeText = [NSMutableString string];
        NSMutableString *scheduledText = [NSMutableString string];
        NSMutableString *detourText = [NSMutableString string];
        NSMutableString *fullText = [NSMutableString string];
        NSString *minsText = nil;
        NSString *unitText = nil;
        ArrivalWindow arrivalWindow;
        bool canceled = NO;
        bool showLate = YES;
        
        NSDateFormatter *dateFormatter = [self dateAndTimeFormatterWithPossibleLongDateStyle:kLongDateFormat arrivalWindow:&arrivalWindow];
        
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];
        
        if ((mins < 0 || self.invalidated) && !self.trackingErrorOffRoute && !self.trackingError
            &&  self.extrapolation > 30) {
            // We should only use this item for extrapolated items that are negative
            
            minsText = NSLocalizedString(@"--", @"DNL");
            unitText = NSLocalizedString(@"gone", @"text displayed for departure time if the bus has gone already");
            timeColor = ArrivalColorDeparted;
            messageDetails = kVehicleDepartedText;
            showLate = NO;
        } else if ((mins < 0 || self.invalidated) && self.trackingErrorOffRoute) {
            minsText = NSLocalizedString(@"OFF  ", @"off route");
            unitText = NSLocalizedString(@"ROUTE", @"off route");
            timeColor = ArrivalColorOffRoute;
            messageDetails = kVehicleOffRouteText;
            showLate = NO;
        } else if ((mins < 0 || self.invalidated) && self.trackingError) {
            minsText = NSLocalizedString(@"??",    @"error message");
            unitText = NSLocalizedString(@"",      @"error message");
            timeColor = ArrivalColorOffRoute;
            messageDetails = kVehicleTrackingError;
            showLate = NO;
        } else if (mins <= 0) {
            minsText = NSLocalizedString(@"Due", @"first line of text to display when bus is due");
            unitText = NSLocalizedString(@"now", @"second line of test to display when bus is due");
            timeColor = ArrivalColorSoon;
            messageDetails = kVehicleSoonText;
        } else if (mins == 1) {
            minsText = NSLocalizedString(@"1", @"first line of text to display when bus is due in 1 minute");
            unitText = NSLocalizedString(@"min", @"second line of text to display when bus is due in 1 minute");
            timeColor = ArrivalColorSoon;
            messageDetails = kVehicleSoonText;
        } else if (mins < 6) {
            minsText = [NSString stringWithFormat:@"%lld", mins];
            unitText = NSLocalizedString(@"mins", @"plural number of minutes to display for bus departure time");
            timeColor = ArrivalColorSoon;
            messageDetails = kVehicleSoonText;
        } else if (mins < 60) {
            minsText = [NSString stringWithFormat:@"%lld", mins];
            unitText = NSLocalizedString(@"mins", @"plural number of minutes to display for bus departure time");
            timeColor = ArrivalColorOK;
            messageDetails = kVehicleComingText;
        } else {
            switch (arrivalWindow) {
                case ArrivalThisWeek: {
                    NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
                    dayFormatter.dateStyle = kCFDateFormatterMediumStyle;
                    dayFormatter.timeStyle = NSDateFormatterNoStyle;
                    
                    dayFormatter.dateFormat = @"E";
                    minsText = [dayFormatter stringFromDate:depatureDate];
                    dayFormatter.dateFormat = @"a";
                    unitText = [dayFormatter stringFromDate:depatureDate];
                    break;
                }
                    
                case ArrivalSoon: {
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
                    minsText = NSLocalizedString(@":::", @"DNL");
                    unitText = NSLocalizedString(@":::", @"DNL");
                    break;
            }
        }
        
        // Override color based on status or lateness
        switch (self.status) {
            case kStatusEstimated:
                
                if (self.trackingErrorOffRoute) {
                    timeColor = ArrivalColorOffRoute;
                    messageDetails = kVehicleOffRouteText;;
                } else if (self.trackingError) {
                    timeColor = ArrivalColorOffRoute;
                    messageDetails = kVehicleTrackingError;
                } else if (self.actuallyLate && showLate) {
                    timeColor = ArrivalColorLate;
                    messageDetails = kVehicleLateText;
                } else if (timeColor == nil) {
                    timeColor = ArrivalColorOK;
                    messageDetails = kVehicleComingText;
                }
                
                break;
                
            case kStatusScheduled:
                [scheduledText appendString:NSLocalizedString(@"scheduled ", @"info about departure time")];
                timeColor = ArrivalColorScheduled;
                messageDetails = kVehicleScheduled;
                break;
                
            case kStatusCancelled:
                [detourText appendString:NSLocalizedString(@"canceled ", @"info about departure time")];
                timeColor = ArrivalColorCanceled;
                messageDetails = kVehicleCanceled;
                canceled = YES;
                break;
                
            case kStatusDelayed:
                [detourText appendString:NSLocalizedString(@"delayed ",  @"info about departure time")];
                timeColor = ArrivalColorDelayed;
                messageDetails = kVehicleDelayed;
                break;
        }
        
        if (self.detour) {
            if (self.sortedDetours.detourIds.count == 1) {
                [detourText appendString:NSLocalizedString(@"⚠️alert ", @"info about departure time")];
            } else {
                [detourText appendString:NSLocalizedString(@"⚠️alerts ", @"info about departure time")];
            }
        }
        
        if (self.loadPercentage > 0) {
            [fullText appendFormat:NSLocalizedString(@"%d%% full ",  @"info about departure time"), (int)self.loadPercentage];
        }
        
        // Append additional text to message details
        
        if (self.reason) {
            NSString *pad = [self padding:messageDetails];
            messageDetails = [NSString stringWithFormat:NSLocalizedString(@"%@%@#b#OStatus:\"%@#b.\"", @"status"), messageDetails, pad, self.reason];
        }
        
        if (self.loadPercentage > 0) {
            NSString *pad = [self padding:messageDetails];
            messageDetails = [NSString stringWithFormat:NSLocalizedString(@"%@%@#b#DThe vehicle is loaded to %d%% of capacity#b.", @"status"), messageDetails, pad, (int)self.loadPercentage];
        }
        
        if (self.dropOffOnly) {
            NSString *pad = [self padding:messageDetails];
            messageDetails = [NSString stringWithFormat:NSLocalizedString(@"%@%@#b#RDrop off only#D#b", @"status"), messageDetails, pad];
        }
        
        if (self.notToSchedule) {
            [scheduledText appendFormat:NSLocalizedString(@"scheduled %@ ", @"info about departure time"), [dateFormatter stringFromDate:self.scheduledTime]];;
            messageDetails = [NSString stringWithFormat:@"%@ %@", messageDetails, self.actuallyLate ? kVehicleNotToScheduleLate
                                                       : kVehicleNotToSchedule];
        }
        
        // Finally populate cell
        
        if (cell != nil) {
            cell.blockColorView.color = [[BlockColorDb sharedInstance] colorForBlock:self.block];
            cell.textLabel.text = nil;
            
            if (cell.cancelledOverlayView != nil) {
                cell.cancelledOverlayView.hidden = !canceled;
                [cell.cancelledOverlayView setNeedsDisplay];
            }
            
            UILabel *unitView = cell.unitLabel;
            UILabel *minsView = cell.minsLabel;
            
            if (minsText != nil) {
                minsView.text = minsText;
                minsView.hidden = NO;
                minsView.textAlignment = NSTextAlignmentCenter;
                minsView.textColor = timeColor;
                
                unitView.textColor = timeColor;
                unitView.text = unitText;
                unitView.hidden = NO;
                unitView.textAlignment = NSTextAlignmentCenter;
            } else {
                unitView.hidden = YES;
                minsView.hidden = YES;
            }
            
            if (decorate) { //  && (self.hasBlock || self.detour))
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                // cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            } else {
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
            cell.fullLabel.textColor = [UIColor modeAwareText];
            
            if (busName) {
                if (wide) {
                    cell.routeLabel.text = self.fullSign;
                } else {
                    cell.routeLabel.text = self.shortSign;
                }
            } else {
                cell.routeLabel.text = self.locationDesc;
            }
            
            cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@ %@, %@ %@ %@",
                                       cell.routeLabel.text.phonetic, minsText, unitText, timeText, scheduledText, detourText];
        }
        
        [cell.routeColorView setRouteColor:self.route];
    }
    
    return messageDetails;
}

- (void)populateCellGeneric:(DepartureCell *)cell first:(NSString *)first second:(NSString *)second col1:(UIColor *)col1 col2:(UIColor *)col2; {
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

- (void)populateTripCell:(DepartureCell *)cell item:(NSInteger)item {
    if (item<self.trips.count)
    {
        DepartureTrip *trip = self.trips[item];
        
        cell.textLabel.text = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        NSString *timeText = nil;
        UIColor *timeColor = nil;
        
        cell.minsLabel.hidden = YES;
        cell.unitLabel.hidden = YES;
        
        cell.routeLabel.hidden = NO;
        
        if (trip.distance > 0) {
            TriMetDistance toGo = trip.distance - trip.progress;
            
            if (trip.progress > 0) {
                cell.routeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Current trip: %@", @"trip details"), trip.name];
                cell.routeLabel.textColor = [UIColor modeAwareText];
                timeText = [NSString stringWithFormat:NSLocalizedString(@"%@ left to go", @"distance remaining"), [FormatDistance formatFeet:(int)toGo]];
                timeColor = [UIColor modeAwareBlue];
            } else {
                cell.routeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Trip: %@", @"name of trip"), trip.name];
                cell.routeLabel.textColor = [UIColor modeAwareText];
                timeText = [NSString stringWithFormat:NSLocalizedString(@"%@ total", @"total distance"), [FormatDistance formatFeet:(int)toGo]];
                timeColor = [UIColor grayColor];
            }
            
            cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@",
                                       cell.routeLabel.text.phonetic,
                                       timeText];
        }
        
        if (trip.startTime > 0) {
            cell.routeLabel.text = [NSString stringWithFormat:@"%@", trip.name];
            cell.routeLabel.textColor = [UIColor modeAwareText];
            
            TriMetTime toGo;
            
            // NSDate *startLayover = trip.startTime;
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            
            dateFormatter.dateStyle = NSDateFormatterMediumStyle;
            dateFormatter.timeStyle = NSDateFormatterNoStyle;
            
            if ([[dateFormatter stringFromDate:trip.startTime] isEqualToString:[dateFormatter stringFromDate:[NSDate date]]]) {
                dateFormatter.dateStyle = NSDateFormatterNoStyle;
            }
            
            dateFormatter.timeStyle = NSDateFormatterMediumStyle;
            
            // Ascending mean receiver is earlier.
            if ([trip.startTime compare:self.queryTime] == NSOrderedAscending  &&  [trip.endTime compare:self.queryTime] == NSOrderedDescending) {
                toGo = [trip.endTime timeIntervalSinceDate:self.queryTime];
                timeText = [NSString stringWithFormat:NSLocalizedString(@"Layover at %@ remaining: %@", @"bus waiting at <location> for a <time>"),
                            [dateFormatter stringFromDate:trip.startTime],  [self formatLayoverTime:toGo]];
                timeColor = [UIColor modeAwareBlue];
            } else {
                NSMutableString *str = [NSMutableString string];
                toGo = [trip.endTime timeIntervalSinceDate:trip.startTime];
                
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
    else
    {
        DEBUG_HERE();
        cell.textLabel.text = nil;
        cell.timeLabel.text = nil;
        cell.scheduledLabel.text = nil;
        cell.detourLabel.text = nil;
        cell.fullLabel.text = nil;
        cell.routeColorView.hidden = YES;
        cell.minsLabel.hidden = YES;
        cell.unitLabel.hidden = YES;
        cell.routeLabel.hidden = YES;
       
        cell.routeLabel.text = NSLocalizedString(@"Unknown", @"unknown route");
        cell.routeLabel.textColor = [UIColor modeAwareText];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [cell setNeedsLayout];
    }
}

#pragma mark Map callbacks

- (bool)showActionMenu {
    return YES;
}

- (Departure *)mapDeparture {
    return self;
}

- (NSString *)description {
    // Override of -[NSObject description] to print a meaningful representation of self.
    return [NSString stringWithFormat:@"%@", self.fullSign];
}

// MK Annotate
- (CLLocationCoordinate2D)coordinate {
    return self.blockPosition.coordinate;
}

- (NSString *)title {
    return self.shortSign;
}

- (NSString *)subtitle {
    NSMutableString *text = [NSMutableString string];
    
    if (self.errorMessage == nil) {
        TriMetTime mins = MinsBetweenDates(self.departureTime, self.queryTime);
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        // NSDate *depatureDate = self.departureTime;
        NSString *loc = self.locationDesc;
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        
        if ([[dateFormatter stringFromDate:self.departureTime] isEqualToString:[dateFormatter stringFromDate:[NSDate date]]]) {
            dateFormatter.dateStyle = NSDateFormatterNoStyle;
        }
        
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
        
        if (mins <= 0) {
            [text appendFormat:NSLocalizedString(@"Due - %@ at %@", @"bus due <time> at <location>"), [dateFormatter stringFromDate:self.departureTime], loc];
        } else if (mins == 1) {
            [text appendFormat:NSLocalizedString(@"1 min - %@ to %@", @"bus due <time> at <location>"), [dateFormatter stringFromDate:self.departureTime], loc];
        } else if (mins < 60) {
            [text appendFormat:NSLocalizedString(@"%lld mins - %@ to %@ ", @"in <mins> minutes bus is due <time> at <location>"), mins, [dateFormatter stringFromDate:self.departureTime], loc];
        } else {
            [text appendFormat:NSLocalizedString(@"%@ to %@", @"at <time> bus will departure at <location>"), [dateFormatter stringFromDate:self.departureTime], loc];
        }
    }
    
    return text;
}

- (MapPinColorValue)pinColor {
    return MAP_PIN_COLOR_PURPLE;
}

- (UIColor *)pinTint {
    return [TriMetInfo colorForRoute:self.route];
}

- (UIColor *)pinSubTint {
    if (self.block != nil) {
        BlockColorDb *db = [BlockColorDb sharedInstance];
        return [db colorForBlock:self.block];
    }
    
    return nil;
}

- (bool)hasBearing {
    return self.blockPositionHeading != nil;
}

- (double)doubleBearing {
    if ([self hasBearing]) {
        return self.blockPositionHeading.doubleValue;
    }
    
    return 0.0;
}

@end
