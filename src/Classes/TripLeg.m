//
//  TripLeg.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripLeg.h"
#import "RouteColorBlobView.h"
#import "DebugLogging.h"
#import "FormatDistance.h"
#import "ViewControllerBase.h"
#import "NSString+Helper.h"
#import "CLLocation+Helper.h"


@implementation TripLeg


#define ROW_HEIGHT kDepartureCellHeight

- (double)distanceMiles
{
    return self.strDistanceMiles.doubleValue;
}


- (NSInteger)durationMins
{
    return self.strDurationMins.integerValue;
}

- (NSString *)direction:(NSString *)dir {
    static NSDictionary *strmap = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        strmap = @{ @"n": @"north",
                    @"s": @"south",
                    @"e": @"east",
                    @"w": @"west",
                    @"ne": @"northeast",
                    @"se": @"southeast",
                    @"sw": @"southwest",
                    @"nw": @"northwest" };
    });
    
    NSString *ret = strmap[dir];
    
    if (ret == nil) {
        ret = dir;
    }
    
    return ret;
}

- (NSString *)mapLink:(NSString *)desc loc:(CLLocation *)loc textType:(TripTextType)type {
    if (loc == nil || type != TripTextTypeHTML) {
        return desc;
    }
    
    return [NSString stringWithFormat:@"<a href=\"http://map.google.com/?q=location@%@\">%@</a>",
            COORD_TO_LAT_LNG_STR(loc.coordinate), desc];
}

- (NSString *)createFromText:(bool)first textType:(TripTextType)type; {
    NSMutableString *text = [NSMutableString string];
    
    if (self.from != nil) {
        if (![self.mode isEqualToString:kModeWalk]) {
            if (type == TripTextTypeUI) {
                self.from.displayTimeText = self.startTimeFormatted;
                self.from.leftColor = [UIColor modeAwareBlue];
                
                // Bug in response can give streetcar data as MAX Mode.
                
                if ([self.mode isEqualToString:kModeBus]) {
                    self.from.displayModeText = [NSString stringWithFormat:@"Bus %@", self.displayRouteNumber];
                } else if ([self.mode isEqualToString:kModeMax]) {
                    self.from.displayModeText = @"MAX";
                } else if ([self.mode isEqualToString:kModeSc]) {
                    self.from.displayModeText = @"Streetcar";
                } else {
                    self.from.displayModeText = self.displayRouteNumber;
                }
                
                if (self.from.thruRoute) {
                    self.from.displayModeText = @"Stay on board";
                    self.from.leftColor = [UIColor modeAwareText];
                    
                    [text appendFormat:@"#bStay on board#b at %@, route changes to '%@'", self.from.desc, self.routeName];
                } else {
                    [text appendFormat:@"#bBoard#b %@", self.routeName];
                }
            } else {
                if (self.from.thruRoute) {
                    [text appendFormat:@"%@ Stay on board at %@,  route changes to '%@'", self.startTimeFormatted,    self.from.desc, self.routeName];
                } else {
                    [text appendFormat:@"%@ Board %@",            self.startTimeFormatted, self.routeName];
                }
            }
        } else if (type == TripTextTypeMap) {
            NSInteger mins = self.durationMins;
            
            if (mins > 0) {
                [text appendFormat:@"Walk %@ %@ ", [FormatDistance formatMiles:self.distanceMiles], [self direction:self.direction]];
            } else {
                [text appendFormat:@"Walk %@ ",  [self direction:self.direction]];
            }
            
            if (mins == 1) {
                [text appendString:@"for 1 min "];
            } else if (mins > 1) {
                [text appendFormat:@"for %ld mins", (long)mins];
            }
        }
    }
    
    while ([text replaceOccurrencesOfString:@"  "
                                 withString:@" "
                                    options:NSLiteralSearch
                                      range:NSMakeRange(0, text.length)] > 0) {
        ;
    }
    
    if (text.length != 0) {
        if (type == TripTextTypeHTML) {
            [text appendString:@"<br><br>"];
        } else if (type == TripTextTypeClip) {
            [text appendString:@"\n"];
        }
    }
    
    switch (type) {
        case TripTextTypeClip:
        case TripTextTypeHTML:
            break;
            
        case TripTextTypeMap:
            
            if (text.length != 0) {
                self.from.mapText = text;
            }
            
            break;
            
        case TripTextTypeUI:
            
            if (text.length != 0) {
                self.from.displayText = text;
            }
            
            break;
    }
    return text;
}



- (NSString *)createToText:(bool)last textType:(TripTextType)type; {
    NSMutableString *text = [NSMutableString string];
    
    if (self.to != nil) {
        if ([self.mode isEqualToString:kModeWalk]) {
            if (type == TripTextTypeMap) {
                if (last) {
                    [text appendFormat:@"Destination"];
                }
            } else { // type is not map
                if (type == TripTextTypeUI) {
                    self.to.displayModeText = self.mode;
                    self.to.leftColor = [UIColor modeAwarePurple];
                }
                
                NSInteger mins = self.durationMins;
                
                if (mins > 0) {
                    if (type == TripTextTypeUI) {
                        [text appendFormat:@"#bWalk#b %@ %@ ", [FormatDistance formatMiles:self.distanceMiles], [self direction:self.direction]];
                    } else {
                        [text appendFormat:@"Walk %@ %@ ", [FormatDistance formatMiles:self.distanceMiles], [self direction:self.direction]];
                    }
                } else { // multiple mins
                    [text appendFormat:@"Walk %@ ",  [self direction:self.direction]];
                    self.to.displayModeText = @"Short\nWalk";
                }
                
                if (mins == 1) {
                    if (type == TripTextTypeUI) {
                        self.to.displayTimeText = @"1 min";
                    } else {
                        [text appendFormat:@"for 1 minute "];
                    }
                } else if (mins > 1) {
                    if (type == TripTextTypeUI) {
                        self.to.displayTimeText = [NSString stringWithFormat:@"%ld mins", (long)mins];
                    } else {
                        [text appendFormat:@"for %ld minutes ", (long)mins];
                    }
                }
                
                [text appendFormat:@"%@%@",
                 @"to ",
                 [self mapLink:self.to.desc loc:self.to.loc textType:type]];
            }
        } else { // mode is not to walk
            switch (type) {
                case TripTextTypeMap:
                    
                    if (last) {
                        [text appendFormat:@"%@ get off at %@", self.endTimeFormatted, self.to.desc];
                    }
                    
                    break;
                    
                case TripTextTypeHTML:
                case TripTextTypeClip:
                    
                    if (self.to.thruRoute) {
                        [text appendFormat:@"%@ stay on board at %@", self.endTimeFormatted, [self mapLink:self.to.desc loc:self.to.loc textType:type]];
                    } else {
                        [text appendFormat:@"%@ get off at %@", self.endTimeFormatted, [self mapLink:self.to.desc loc:self.to.loc textType:type]];
                    }
                    
                    break;
                    
                case TripTextTypeUI:
                    self.to.displayTimeText = self.endTimeFormatted;
                    
                    if (!self.to.thruRoute) {
                        self.to.displayModeText = @"Deboard";
                        self.to.leftColor = [UIColor redColor];
                        [text appendFormat:@"#bGet off#b at %@", self.to.desc];
                    }
                    
                    break;
            }
        }
        
        if (self.to.strStopId != nil) {
            switch (type) {
                case TripTextTypeMap:
                    break;
                    
                case TripTextTypeUI:
                case TripTextTypeClip:
                    [text appendFormat:@" (Stop ID %@)", [self.to stopId]];
                    break;
                    
                case TripTextTypeHTML:
                    [text appendFormat:@" (Stop ID <a href=\"pdxbus://%@?%@/\">%@</a>)",
                     self.to.desc.fullyPercentEncodeString,
                     [self.to stopId], [self.to stopId]];
                    break;
            }
        }
    }
    
    switch (type) {
        case TripTextTypeHTML:
            
            if (!self.to.thruRoute) {
                [text appendFormat:@"<br><br>"];
            } else {
                text = [NSMutableString string];
            }
            
            break;
            
        case TripTextTypeMap:
            
            if (text.length != 0) {
                self.to.mapText = text;
            }
            
            break;
            
        case TripTextTypeClip:
            [text appendFormat:@"\n"];
            
        case TripTextTypeUI:
            
            if (!self.to.thruRoute) {
                self.to.displayText = text;
            }
            
            break;
    }
    return text;
}

@end
