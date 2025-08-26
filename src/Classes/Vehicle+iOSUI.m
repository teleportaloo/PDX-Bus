//
//  Vehicle.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BlockColorDb.h"
#import "DebugLogging.h"
#import "DepartureTimesViewController.h"
#import "FormatDistance.h"
#import "NSString+MoreMarkup.h"
#import "TaskDispatch.h"
#import "TriMetInfo+UI.h"
#import "Vehicle+iOSUI.h"

@class DepartureTimesViewController;

@implementation Vehicle (VehicleUI)

- (CLLocationCoordinate2D)coordinate {
    return self.location.coordinate;
}

- (NSString *)title {
    if (self.signMessage) {
        // DEBUG_LOG(@"Sign Message %@ b %@ %@\n", self.signMessage, self.block,
        // COORD_TO_LAT_LNG_STR(self.location.coordinate));
        return self.signMessage;
    }

    if ([self.type isEqualToString:kVehicleTypeStreetcar]) {
        PtrConstRouteInfo info = [TriMetInfo infoForRoute:self.routeNumber];

        if (info) {
            return info->full_name;
        }

        return @"Portland Streetcar";
    }

    if (self.garage) {
        return [NSString stringWithFormat:@"Garage %@", self.garage];
    }

    return @"no title";
}

- (NSString *)subtitle {
    NSString *located = [Vehicle locatedSomeTimeAgo:self.locationTime];

    if (self.vehicleId) {
        return [NSString stringWithFormat:@"ID %@ %@", self.vehicleId, located];
    }

    return located;
}

// From MapPinColor
- (MapPinColorValue)pinColor {
    if ([self.type isEqualToString:kVehicleTypeBus]) {
        return MAP_PIN_COLOR_PURPLE;
    }

    if ([self.type isEqualToString:kVehicleTypeStreetcar]) {
        return MAP_PIN_COLOR_GREEN;
    }

    return MAP_PIN_COLOR_RED;
}

- (bool)pinActionMenu {
    if (self.lastStopId) {
        return YES;
    }

    return NO;
}

- (bool)pinAction:(id<TaskController>)progress {
    [[DepartureTimesViewController viewController]
        fetchTimesForVehicleAsync:progress
                            route:self.routeNumber
                        direction:self.direction
                       nextStopId:self.lastStopId
                            block:self.block
                  targetDeparture:nil];
    return true;
}

- (NSString *)pinStopId {
    return self.nextStopId;
}

- (NSString *)pinMarkedUpStopId {
    if (self.nextStopId != nil) {
        return [NSString stringWithFormat:@"#DNext %@",
                                          self.nextStopId.markedUpLinkToStopId];
    }
    return nil;
}

- (NSString *)pinActionText {
    return @"Show next stops";
}

- (UIColor *)pinTint {
    return [TriMetInfo colorForRoute:self.routeNumber];
}

- (UIColor *)pinBlobColor {
    if (self.block != nil) {
        BlockColorDb *db = [BlockColorDb sharedInstance];
        return [db colorForBlock:self.block];
    }

    return nil;
}

- (bool)pinHasBearing {
    return self.bearing != nil;
}

- (double)pinBearing {
    if (self.bearing) {
        return self.bearing.doubleValue;
    }

    return 0.0;
}

- (void)setPinBearing:(double)pinBearing {
    if (self.bearing) {
        self.bearing = [NSString stringWithFormat:@"%f", pinBearing];
    }
}

- (NSString *)pinMarkedUpType {
    static NSDictionary<NSString *, NSString *> *types;

    DoOnce((^{
      types = @{
          kVehicleTypeBus : kPinTypeBus,
          kVehicleTypeTrain : kPinTypeTrain,
          kVehicleTypeStreetcar : kPinTypeStreetcar
      };
    }));

    return types[self.type];
}

- (NSString *)pinMarkedUpSubtitle {
    NSMutableString *vehicleInfo = [NSMutableString
        stringWithString:[TriMetInfo markedUpVehicleString:self.vehicleId]];

    if (self.garage != nil) {
        [vehicleInfo
            appendFormat:NSLocalizedString(@"\n#DGarage: #b%@#b", @"garage"),
                         self.garage];
    }

    if (self.offRoute) {
        [vehicleInfo
            appendFormat:NSLocalizedString(@"\n#D#bOff Route#b", @"off route")];
    }

    if (self.loadPercentage > 0) {
        [vehicleInfo appendFormat:NSLocalizedString(
                                      @"\n#DLoad percentage: %d%%", @"load"),
                                  (int)self.loadPercentage];
    }

    if (self.speedKmHr != nil) {
        [vehicleInfo
            appendFormat:NSLocalizedString(@"\n#DSpeed: %0.1f mph (%0.1f km/h)",
                                           @"speed"),
                         MilesForKm(self.speedKmHr.doubleValue),
                         self.speedKmHr.doubleValue];
    }

    if (self.lastStopId != nil) {
        [vehicleInfo appendFormat:NSLocalizedString(@"\n#DLast %@", @"stop id"),
                                  self.lastStopId.markedUpLinkToStopId];
    }

    if (self.routeNumber != nil) {
        [vehicleInfo appendFormat:NSLocalizedString(
                                      @"\n#D#Lroute:%@ Route Info#T", @"speed"),
                                  self.routeNumber];
    }

    if (self.locationTime != nil) {
        [vehicleInfo
            appendFormat:
                NSLocalizedString(@"\n#DLocated at: %@", @"speed"),
                [NSDateFormatter
                    localizedStringFromDate:self.locationTime
                                  dateStyle:NSDateFormatterNoStyle
                                  timeStyle:NSDateFormatterMediumStyle]];
    }

    if (self.delay != nil) {
        NSInteger delay = self.delay.integerValue;
        NSInteger mins = labs((long)(delay / 60));
        NSString *minsString = nil;

        if (mins == 0) {
            minsString = @"less than a minute";
        } else if (mins == 1) {
            minsString = @"1 minute";
        } else {
            minsString = [NSString
                stringWithFormat:NSLocalizedString(@"%d minutes", @"mins"),
                                 (int)mins];
        }

        if (delay < 0) {
            [vehicleInfo
                appendFormat:NSLocalizedString(@"\n#RDelayed: %@", @"delayed"),
                             minsString];
        } else if (delay > 0) {
            [vehicleInfo
                appendFormat:NSLocalizedString(@"\n#MAhead: %@", @"ahead"),
                             minsString];
        } else {
            [vehicleInfo
                appendFormat:NSLocalizedString(@"\n#GOn time", @"on time")];
        }
    }

    return vehicleInfo;
}

- (NSString *)key {
    return self.vehicleId;
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
    self.location =
        [[CLLocation alloc] initWithLatitude:newCoordinate.latitude
                                   longitude:newCoordinate.longitude];
}

- (NSDate *)lastUpdated {
    return self.locationTime;
}

- (NSString *)pinSmallText {
    if ([self.type isEqualToString:kVehicleTypeBus]) {
        return self.routeNumber;
    }
    return nil;
}

@end
