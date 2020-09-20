//
//  Stop.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Stop.h"


@implementation Stop

@dynamic  pinTint;

- (void)dealloc {
    self.tp = nil;
}

- (MapPinColorValue)pinColor {
    return MAP_PIN_COLOR_PURPLE;
}

- (bool)hasBearing {
    return NO;
}

- (bool)showActionMenu {
    return YES;
}

- (bool)mapTapped:(id<TaskController>)progress {
    [self.callback chosenStop:self progress:progress];
    return YES;
}

- (NSString *)tapActionText {
    return [self.callback actionText];
}

- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D pos;
    
    pos.latitude = self.lat.doubleValue;
    pos.longitude = self.lng.doubleValue;
    return pos;
}

- (NSString *)title {
    return self.desc;
}

- (NSString *)subtitle {
    if (self.dir == nil) {
        return [NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), self.stopId];
    }
    
    return [NSString stringWithFormat:@"%@ ID %@", self.dir, self.stopId];
}

- (NSComparisonResult)compareUsingStopName:(Stop *)inStop {
    return [self.desc compare:inStop.desc];
}

- (NSComparisonResult)compareUsingIndex:(Stop *)inStop {
    if (self.index < inStop.index) {
        return NSOrderedAscending;
    }
    
    if (self.index > inStop.index) {
        return NSOrderedDescending;
    }
    
    return NSOrderedSame;
}

- (NSString *)stringToFilter {
    return self.desc;
}

- (UIColor *)pinTint {
    return nil;
}

@end
