//
//  WatchArrivalScheduleInfo.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/17/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchArrivalScheduleInfo.h"
#import "ArrivalColors.h"
#import "FormatDistance.h"
#import "NSString+MoreMarkup.h"
#import "NSString+Convenience.h"
#import "Vehicle.h"
#import "XMLDepartures.h"

@implementation WatchArrivalScheduleInfo

+ (NSString *)identifier {
    return @"Schedule";
}

- (void)populate:(XMLDepartures *)xml departures:(NSArray<Departure *> *)deps {
    NSMutableString *detourText = [NSMutableString string];
    Departure *dep = deps.firstObject;

    NSInteger mins = dep.minsToArrival;
    NSDate *depatureDate = dep.departureTime;
    NSMutableString *timeText = [NSMutableString string];
    NSMutableString *scheduledText = [NSMutableString string];
    NSMutableString *distanceText = [NSMutableString string];
    UIColor *timeColor = nil;

    NSDateFormatter *dateFormatter =
        [dep dateAndTimeFormatterWithPossibleLongDateStyle:kLongDateFormat
                                             arrivalWindow:nil];

    if ((mins < 0 || dep.invalidated) && dep.status != ArrivalStatusCancelled) {
        [timeText
            appendString:NSLocalizedString(@"Gone - ",
                                           @"first part of text to display on "
                                           @"a single line if a bus has gone")];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];
        timeColor = ArrivalColorDeparted;
    } else if (mins == 0 && dep.status != ArrivalStatusCancelled) {
        [timeText
            appendString:NSLocalizedString(@"Due - ",
                                           @"first part of text to display on "
                                           @"a single line if a bus is due")];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];

        if (dep.actuallyLate) {
            timeColor = ArrivalColorLate;
        } else {
            timeColor = ArrivalColorSoon;
        }
    } else if (mins == 1 && dep.status != ArrivalStatusCancelled) {
        [timeText appendString:NSLocalizedString(
                                   @"1 min - ",
                                   @"first part of text to display on a single "
                                   @"line if a bus is due in 1 minute")];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];

        if (dep.actuallyLate) {
            timeColor = ArrivalColorLate;
        } else {
            timeColor = ArrivalColorSoon;
        }
    } else if (mins < 6 && dep.status != ArrivalStatusCancelled) {
        [timeText appendFormat:NSLocalizedString(
                                   @"%d mins - ",
                                   @"first part of text to display on a single "
                                   @"line if a bus is due in several minutes"),
                               (int)mins];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];

        if (dep.actuallyLate) {
            timeColor = ArrivalColorLate;
        } else {
            timeColor = ArrivalColorSoon;
        }
    } else if (mins < 60 && dep.status != ArrivalStatusCancelled) {
        [timeText appendFormat:NSLocalizedString(
                                   @"%d mins - ",
                                   @"first part of text to display on a single "
                                   @"line if a bus is due in several minutes"),
                               (int)mins];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];

        if (dep.actuallyLate) {
            timeColor = ArrivalColorLate;
        } else {
            timeColor = ArrivalColorOK;
        }
    } else {
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];

        if (dep.actuallyLate) {
            timeColor = ArrivalColorLate;
        } else {
            timeColor = ArrivalColorOK;
        }
    }

    switch (dep.status) {
    case ArrivalStatusEstimated:
        break;

    case ArrivalStatusScheduled:
        [scheduledText
            appendString:
                NSLocalizedString(
                    @"🕔Scheduled - no location information available. ",
                    @"info about departure time")];
        timeColor = ArrivalColorScheduled;
        break;

    case ArrivalStatusCancelled:
        [scheduledText
            appendString:NSLocalizedString(@"❌Canceled ",
                                           @"info about departure time")];
        timeColor = ArrivalColorCanceled;
        break;

    case ArrivalStatusDelayed:
        [detourText
            appendString:NSLocalizedString(@"Delayed ",
                                           @"info about departure time")];
        timeColor = ArrivalColorDelayed;
        break;
    }

    if (dep.notToSchedule) {
        NSDate *scheduledDate = dep.scheduledTime;
        [scheduledText
            appendFormat:NSLocalizedString(@"scheduled %@ ",
                                           @"info about departure time"),
                         [dateFormatter stringFromDate:scheduledDate]];
        ;
    }

    NSMutableAttributedString *string = [NSMutableAttributedString new];

    NSString *location = [NSString stringWithFormat:@"%@\n", dep.locationDesc];
    NSDictionary *attributes =
        @{NSForegroundColorAttributeName : [UIColor cyanColor]};
    NSAttributedString *subString =
        [location attributedStringWithAttributes:attributes];

    [string appendAttributedString:subString];

    NSString *fullsign = [NSString stringWithFormat:@"%@\n", dep.fullSign];

    attributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    subString = [fullsign attributedStringWithAttributes:attributes];
    [string appendAttributedString:subString];

    if (scheduledText.length > 0) {
        [timeText appendString:@"\n"];
    }

    attributes = @{NSForegroundColorAttributeName : timeColor};
    subString = [timeText attributedStringWithAttributes:attributes];
    [string appendAttributedString:subString];

    if (detourText.length > 0) {
        [scheduledText appendString:@"\n"];
    }

    attributes = @{NSForegroundColorAttributeName : ArrivalColorScheduled};
    subString = [scheduledText attributedStringWithAttributes:attributes];
    [string appendAttributedString:subString];

    attributes = @{NSForegroundColorAttributeName : [UIColor orangeColor]};
    subString = [detourText attributedStringWithAttributes:attributes];
    [string appendAttributedString:subString];

    if (dep.blockPosition && dep.blockPositionFeet > 0) {
        [distanceText
            appendFormat:@"\n%@ away\n",
                         [FormatDistance formatFeet:dep.blockPositionFeet]];
        [distanceText
            appendString:[Vehicle locatedSomeTimeAgo:dep.blockPositionAt]];
        attributes = @{NSForegroundColorAttributeName : [UIColor yellowColor]};
        subString = [distanceText attributedStringWithAttributes:attributes];
        [string appendAttributedString:subString];
    }

    self.label.attributedText = string;
}

@end
