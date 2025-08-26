//
//  TripItinerary.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripItinerary.h"
#import "CLLocation+Helper.h"
#import "FormatDistance.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"

@implementation TripItinerary

- (instancetype)init {
    if ((self = [super init])) {
        self.legs = [NSMutableArray array];
    }

    return self;
}

- (double)distanceMiles {
    return self.strDistanceMiles.doubleValue;
}

- (NSInteger)waitingTimeMins {
    return self.strWaitingTimeMins.integerValue;
}

- (NSInteger)durationMins {
    return self.strDurationMins.integerValue;
}

- (NSInteger)numberOfTransfers {
    return self.strNumberOfTransfers.integerValue;
}

- (NSInteger)numberOfTripLegs {
    return self.strNumberOfTripLegs.integerValue;
}

- (NSInteger)walkingTimeMins {
    return self.strWalkingTimeMins.integerValue;
}

- (NSInteger)transitTimeMins {
    return self.strTransitTimeMins.integerValue;
}

- (bool)hasFare {
    return self.fare != nil && self.fare.length != 0;
}

- (TripLeg *)getLeg:(int)item {
    return self.legs[item];
}

- (NSString *)shortTravelTime {
    NSMutableString *strTime = [NSMutableString string];
    NSInteger t = self.durationMins;
    NSInteger h = t / 60;
    NSInteger m = t % 60;

    [strTime appendFormat:NSLocalizedString(@"Travel time: %ld:%02ld",
                                            @"hours, mins"),
                          (long)h, (long)m];
    return strTime;
}

- (NSString *)mins:(NSInteger)t {
    if (t == 1) {
        return @"1 min";
    }

    return [NSString
        stringWithFormat:NSLocalizedString(@"%ld mins", @"minutes"), (long)t];
}

- (NSString *)travelTime {
    NSMutableString *strTime = [NSMutableString string];

    [strTime appendString:[self mins:self.durationMins]];

    bool inc = false;

    if (self.strWalkingTimeMins != nil) {
        NSInteger walking = self.walkingTimeMins;

        if (walking > 0) {
            [strTime appendFormat:NSLocalizedString(@", including %@ walking",
                                                    @"time info, minutes"),
                                  [self mins:walking]];
            inc = true;
        }
    }

    if (self.strWaitingTimeMins != nil) {
        NSInteger waiting = self.waitingTimeMins;

        if (waiting > 0) {
            if (!inc) {
                [strTime
                    appendFormat:NSLocalizedString(@", including %@ waiting",
                                                   @"time info, minutes"),
                                 [self mins:waiting]];
            } else {
                [strTime appendFormat:NSLocalizedString(@" and %@ waiting",
                                                        @"time info, minutes"),
                                      [self mins:waiting]];
            }
        }
    }

    [strTime appendString:@"."];

    return strTime;
}

- (NSInteger)legCount {
    if (self.legs) {
        return self.legs.count;
    }

    return 0;
}

- (NSString *)startPointText:(TripTextType)type {
    NSMutableString *text = [NSMutableString string];

    TripLeg *firstLeg = nil;
    TripLegEndPoint *firstPoint = nil;

    if (self.legs.count > 0) {
        firstLeg = self.legs.firstObject;
        firstPoint = firstLeg.from;
    } else {
        return nil;
    }

    if (self.startPoint == nil) {
        self.startPoint = [firstPoint copy];
    }

    if (firstPoint != nil && type != TripTextTypeMap) {
        bool nearTo = [firstPoint.desc hasPrefix:kNearTo];

        if (type == TripTextTypeUI) {
            self.startPoint.displayModeText = @"Start";
            [text appendFormat:@"%@%@", nearTo ? @"" : @"#bStart at#b ",
                               firstPoint.desc.safeEscapeForMarkUp];
        } else if (type == TripTextTypeHTML && firstPoint.loc != nil) {
            [text appendFormat:
                      @"%@<a "
                      @"href=\"http://map.google.com/?q=location@%@\">%@</a>",
                      nearTo ? @"Start " : @"Start at ",
                      COORD_TO_LAT_LNG_STR(firstPoint.coordinate),
                      firstPoint.desc];
        } else {
            [text appendFormat:@"%@%@", nearTo ? @"Starting " : @"Starting at ",
                               firstPoint.desc];
        }
    }

    if (self.startPoint.strStopId != nil) {
        if (type == TripTextTypeHTML) {
            [text appendFormat:@" (Stop ID <a href=\"pdxbus://%@?%@/\">%@</a>)",
                               self.startPoint.desc.fullyPercentEncodeString,
                               [self.startPoint stopId], firstPoint.stopId];
        } else {
            [text appendFormat:@" (Stop ID %@)", self.startPoint.stopId];
        }
    }

    switch (type) {
    case TripTextTypeHTML:
        [text appendFormat:@"<br><br>"];
        break;

    case TripTextTypeMap:

        if (text.length != 0) {
            self.startPoint.mapText = text;
        }

        break;

    case TripTextTypeClip:
        [text appendFormat:@"\n"];

    case TripTextTypeUI:
        self.startPoint.displayText = text;
        break;
    }
    return text;
}

- (bool)hasBlocks {
    for (TripLeg *leg in self.legs) {
        if (leg.block != nil && leg.block.length != 0) {
            return YES;
        }
    }

    return NO;
}

- (NSString *)formattedDistance {
    return [FormatDistance formatMiles:self.distanceMiles];
}

@end
