//
//  RoutePin.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/12/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RoutePin.h"
#import "DirectionView.h"

@implementation RoutePin


- (MapPinColorValue)pinColor {
    return MAP_PIN_COLOR_GREEN;
}

- (UIColor *)pinTint {
    return self.color;
}

- (bool)showActionMenu {
    if (self.route != nil) {
        return YES;
    }
    
    return NO;
}

- (bool)hasBearing {
    return NO;
}

- (CLLocationCoordinate2D)coordinate {
    return _touchPosition;
}

- (NSString *)title {
    return self.desc;
}

- (NSString *)subtitle {
    return self.dir;
}

- (NSString *)tapActionText {
    return @"Route info";
}

- (bool)mapTapped:(id<TaskController>)progress {
    [[DirectionView viewController] fetchDirectionsAsync:progress route:self.route];
    return true;
}

- (NSUInteger)hash {
    return self.route.hash ^ self.dir.hash;
}

- (BOOL)isEqualToRoutePin:(RoutePin *)pin {
    if (self.route == nil) {
        if (pin.route == nil) {
            return [self.desc isEqualToString:pin.desc];
        }
    } else if ([self.route isEqualToString:pin.route]) {
        if (self.dir && pin.dir) {
            return [self.dir isEqualToString:pin.dir];
        } else {
            return self.dir == pin.dir;
        }
    }
    
    return NO;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[RoutePin class]]) {
        return NO;
    }
    
    return [self isEqualToRoutePin:(RoutePin *)object];
}

- (NSComparisonResult)compare:(RoutePin *)other {
    NSComparisonResult result = [self.desc compare:other.desc];
    
    if (result == NSOrderedSame) {
        result = [self.dir compare:other.dir];
    }
    
    return result;
}

@end
