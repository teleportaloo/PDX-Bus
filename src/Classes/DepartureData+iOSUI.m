//
//  Departure.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogUserInterface

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

#define kMarkedUpVehicleDepartedText        NSLocalizedString(@"#DThe time is shown in this color as the vehicle has departed.",                                                            @"Infomation text")
#define kMarkedUpVehicleOffRouteText        NSLocalizedString(@"#OThe time is shown in #borange#b as the vehicle is off route.",                                                            @"Infomation text")
#define kMarkedUpVehicleTrackingError       NSLocalizedString(@"#OThe time is shown in #borange#b as there is an issue tracking the vehicle.",                                              @"Infomation text")
#define kMarkedUpVehicleSoonText            NSLocalizedString(@"#RThe time is shown in #bred#b as the vehicle will depart in 5 minutes or less.",                                           @"Infomation text")
#define kMarkedUpVehicleLateText            NSLocalizedString(@"#MThe time is shown in #bmagenta#b as the vehicle is late.",                                                                @"Infomation text")
#define kMarkedUpVehicleComingText          NSLocalizedString(@"#UThe time is shown in #bblue#b as the vehicle will depart in more than 5 minutes.",                                        @"Infomation text")
#define kMarkedUpVehicleLongText            kMarkedUpVehicleComingText
#define kMarkedUpVehicleScheduled           NSLocalizedString(@"#AThe time is shown in #bgray#b as no location infomation is available - the scheduled time is shown.",                     @"Infomation text")
#define kMarkedUpVehicleCanceled            NSLocalizedString(@"#OThe time is shown in #borange#b and crossed out as the vehicle was canceled.  #AThe original scheduled time is shown for reference.",     @"Infomation text")
#define kMarkedUpVehicleDelayed             NSLocalizedString(@"#OThe Time is shown in #borange#b as the vehicle is delayed.",                                                              @"Infomation text")
#define kMarkedUpVehicleNotToSchedule       NSLocalizedString(@"#AThe scheduled time is also shown in #bgray#b as the vehicle is not running to schedule.",                                 @"Infomation text")
#define kMarkedUpVehicleNotToScheduleLate   NSLocalizedString(@"#AThe scheduled time is also shown in #bgray#b.",                                                                           @"Infomation text")

@implementation Departure (iOSUI)

#pragma mark User Interface

- (void)populateCell:(DepartureCell *)cell decorate:(BOOL)decorate busName:(BOOL)busName fullSign:(BOOL)wide {
    [self populateCellAndGetMarkedUpExplaination:cell decorate:decorate busName:busName wide:wide];
}

- (NSString *)getMarkedUpExplaination {
    return [self populateCellAndGetMarkedUpExplaination:nil decorate:NO busName:NO wide:NO];;
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

- (void)populateErrorMessage:(DepartureCell *)cell messageDetails:(NSString **)messageDetails {
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
    
    [cell resetConstraints];
}

- (int)extrapolation
{
    int extrapolation = abs((int)self.timeAdjustment);
    
    DEBUG_LOGL(extrapolation);
    
    return extrapolation;
}

- (NSString *)populateCellAndGetMarkedUpExplaination:(DepartureCell *)cell decorate:(BOOL)decorate busName:(BOOL)busName wide:(BOOL)wide {
    NSString *markedUpMessageDetails = @"";
    
    if (self.errorMessage != nil) {
        [self populateErrorMessage:cell messageDetails:&markedUpMessageDetails];
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
            markedUpMessageDetails = kMarkedUpVehicleDepartedText;
            showLate = NO;
        } else if ((mins < 0 || self.invalidated) && self.trackingErrorOffRoute) {
            minsText = NSLocalizedString(@"OFF  ", @"off route");
            unitText = NSLocalizedString(@"ROUTE", @"off route");
            timeColor = ArrivalColorOffRoute;
            markedUpMessageDetails = kMarkedUpVehicleOffRouteText;
            showLate = NO;
        } else if ((mins < 0 || self.invalidated) && self.trackingError) {
            minsText = NSLocalizedString(@"??",    @"error message");
            unitText = NSLocalizedString(@"",      @"error message");
            timeColor = ArrivalColorOffRoute;
            markedUpMessageDetails = kMarkedUpVehicleTrackingError;
            showLate = NO;
        } else if (mins <= 0) {
            minsText = NSLocalizedString(@"Due", @"first line of text to display when bus is due");
            unitText = NSLocalizedString(@"now", @"second line of test to display when bus is due");
            timeColor = ArrivalColorSoon;
            markedUpMessageDetails = kMarkedUpVehicleSoonText;
        } else if (mins == 1) {
            minsText = NSLocalizedString(@"1", @"first line of text to display when bus is due in 1 minute");
            unitText = NSLocalizedString(@"min", @"second line of text to display when bus is due in 1 minute");
            timeColor = ArrivalColorSoon;
            markedUpMessageDetails = kMarkedUpVehicleSoonText;
        } else if (mins < 6) {
            minsText = [NSString stringWithFormat:@"%lld", mins];
            unitText = NSLocalizedString(@"mins", @"plural number of minutes to display for bus departure time");
            timeColor = ArrivalColorSoon;
            markedUpMessageDetails = kMarkedUpVehicleSoonText;
        } else if (mins < 60) {
            minsText = [NSString stringWithFormat:@"%lld", mins];
            unitText = NSLocalizedString(@"mins", @"plural number of minutes to display for bus departure time");
            timeColor = ArrivalColorOK;
            markedUpMessageDetails = kMarkedUpVehicleComingText;
        } else {
            switch (arrivalWindow) {
                case ArrivalThisWeek: {
                    NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
                    dayFormatter.dateStyle = NSDateFormatterMediumStyle;
                    dayFormatter.timeStyle = NSDateFormatterNoStyle;
                    
                    dayFormatter.dateFormat = @"E";
                    minsText = [dayFormatter stringFromDate:depatureDate];
                    dayFormatter.dateFormat = @"a";
                    unitText = [dayFormatter stringFromDate:depatureDate];
                    break;
                }
                    
                case ArrivalSoon: {
                    NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
                    dayFormatter.dateStyle = NSDateFormatterMediumStyle;
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
            case ArrivalStatusEstimated:
                
                if (self.trackingErrorOffRoute) {
                    timeColor = ArrivalColorOffRoute;
                    markedUpMessageDetails = kMarkedUpVehicleOffRouteText;;
                } else if (self.trackingError) {
                    timeColor = ArrivalColorOffRoute;
                    markedUpMessageDetails = kMarkedUpVehicleTrackingError;
                } else if (self.actuallyLate && showLate) {
                    timeColor = ArrivalColorLate;
                    markedUpMessageDetails = kMarkedUpVehicleLateText;
                } else if (timeColor == nil) {
                    timeColor = ArrivalColorOK;
                    markedUpMessageDetails = kMarkedUpVehicleComingText;
                }
                
                break;
                
            case ArrivalStatusScheduled:
                [scheduledText appendString:NSLocalizedString(@"scheduled ", @"info about departure time")];
                timeColor = ArrivalColorScheduled;
                markedUpMessageDetails = kMarkedUpVehicleScheduled;
                break;
                
            case ArrivalStatusCancelled:
                [detourText appendString:NSLocalizedString(@"canceled ", @"info about departure time")];
                timeColor = ArrivalColorCanceled;
                markedUpMessageDetails = kMarkedUpVehicleCanceled;
                canceled = YES;
                break;
                
            case ArrivalStatusDelayed:
                [detourText appendString:NSLocalizedString(@"delayed ",  @"info about departure time")];
                timeColor = ArrivalColorDelayed;
                markedUpMessageDetails = kMarkedUpVehicleDelayed;
                break;
        }
        
        if (self.detour) {
            if (self.sortedDetours.detourIds.count == 1) {
                [detourText appendString:NSLocalizedString(@"⚠️ alert ", @"info about departure time")];
            } else {
                [detourText appendString:NSLocalizedString(@"⚠️ alerts ", @"info about departure time")];
            }
        }
        
        if (self.loadPercentage > 0) {
            [fullText appendFormat:NSLocalizedString(@"%d%% full ",  @"info about departure time"), (int)self.loadPercentage];
        }
        
        // Append additional text to message details
        
        if (self.reason) {
            NSString *pad = [self padding:markedUpMessageDetails];
            markedUpMessageDetails = [NSString stringWithFormat:NSLocalizedString(@"%@%@#b#OStatus:\"%@#b.\"", @"status"), markedUpMessageDetails, pad, self.reason];
        }
        
        if (self.loadPercentage > 0) {
            NSString *pad = [self padding:markedUpMessageDetails];
            markedUpMessageDetails = [NSString stringWithFormat:NSLocalizedString(@"%@%@#b#DThe vehicle is loaded to %d%% of capacity#b.", @"status"), markedUpMessageDetails, pad, (int)self.loadPercentage];
        }
        
        if (self.dropOffOnly) {
            NSString *pad = [self padding:markedUpMessageDetails];
            markedUpMessageDetails = [NSString stringWithFormat:NSLocalizedString(@"%@%@#b#RDrop off only#D#b", @"status"), markedUpMessageDetails, pad];
        }
        
        if (self.notToSchedule) {
            [scheduledText appendFormat:NSLocalizedString(@"scheduled %@ ", @"info about departure time"), [dateFormatter stringFromDate:self.scheduledTime]];;
            markedUpMessageDetails = [NSString stringWithFormat:@"%@ %@", markedUpMessageDetails, self.actuallyLate ? kMarkedUpVehicleNotToScheduleLate
                                                       : kMarkedUpVehicleNotToSchedule];
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
    
    [cell resetConstraints];
    
    return markedUpMessageDetails;
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
    [cell resetConstraints];
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
        
        if (trip.distanceFeet > 0) {
            TriMetDistance toGoFeet = trip.distanceFeet - trip.progressFeet;
            
            if (trip.progressFeet > 0) {
                cell.routeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Current trip: %@", @"trip details"), trip.name];
                cell.routeLabel.textColor = [UIColor modeAwareText];
                timeText = [NSString stringWithFormat:NSLocalizedString(@"%@ left to go", @"distance remaining"), [FormatDistance formatFeet:(int)toGoFeet]];
                timeColor = [UIColor modeAwareBlue];
            } else {
                cell.routeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Trip: %@", @"name of trip"), trip.name];
                cell.routeLabel.textColor = [UIColor modeAwareText];
                timeText = [NSString stringWithFormat:NSLocalizedString(@"%@ total", @"total distance"), [FormatDistance formatFeet:(int)toGoFeet]];
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
    
    [cell resetConstraints];
}

#pragma mark Map callbacks

- (bool)pinActionMenu {
    return YES;
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
    return [self.pinMarkedUpSubtitle removeMarkUp];
}

- (NSString *)pinMarkedUpSubtitle {
    
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
            [text appendFormat:NSLocalizedString(@"#DDue - #b%@#b at %@", @"bus due <time> at <location>"), [dateFormatter stringFromDate:self.departureTime], loc];
        } else if (mins == 1) {
            [text appendFormat:NSLocalizedString(@"#D1 min - #b%@#b to %@", @"bus due <time> at <location>"), [dateFormatter stringFromDate:self.departureTime], loc];
        } else if (mins < 60) {
            [text appendFormat:NSLocalizedString(@"#D%lld mins - #b%@#b to %@ ", @"in <mins> minutes bus is due <time> at <location>"), mins, [dateFormatter stringFromDate:self.departureTime], loc];
        } else {
            [text appendFormat:NSLocalizedString(@"#D%@ to #b%@#b", @"at <time> bus will departure at <location>"), [dateFormatter stringFromDate:self.departureTime], loc];
        }
    }
    
    [text appendFormat:NSLocalizedString(@"\n#D%@ away\nLocated at #b%@", @"<distance> of vehicle"),
                                [FormatDistance formatFeet:self.blockPositionFeet],
                                [NSDateFormatter localizedStringFromDate:self.blockPositionAt dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle]];
    
    return text;
}

- (MapPinColorValue)pinColor {
    return MAP_PIN_COLOR_PURPLE;
}

- (UIColor *)pinTint {
    return [TriMetInfo colorForRoute:self.route];
}

- (UIColor *)pinBlobColor {
    if (self.block != nil) {
        BlockColorDb *db = [BlockColorDb sharedInstance];
        return [db colorForBlock:self.block];
    }
    
    return nil;
}

- (bool)pinHasBearing {
    return self.blockPositionHeading != nil;
}

- (double)pinBearing {
    if ([self pinHasBearing]) {
        return self.blockPositionHeading.doubleValue;
    }
    
    return 0.0;
}

- (NSString *)pinMarkedUpType
{
    PtrConstRouteInfo route = [TriMetInfo infoForRoute:self.route];
    if (route && route->streetcar)
    {
        return kPinTypeStreetcar;
    }
    else if (route)
    {
        return kPinTypeTrain;
    }
    
    return kPinTypeVehicle;
}

@end
