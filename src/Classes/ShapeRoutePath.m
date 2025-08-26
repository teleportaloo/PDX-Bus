//
//  ShapeRoutePath.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/12/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ShapeRoutePath.h"
#import "DebugLogging.h"
#import "RouteMultiPolyline.h"
#import "TriMetInfo+UI.h"
#import "UIColor+HTML.h"

#define kKeyRoute @"r"
#define kKeySegments @"s"
#define kKeyDirect @"d"
#define kKeyDesc @"i"
#define kKeyDirDesc @"e"
#define kKeyFreq @"f"

#define DEBUG_LEVEL_FOR_FILE LogXML

@implementation ShapeRoutePath

- (instancetype)init {
    if (self = [super init]) {
        self.segments = [NSMutableArray array];
    }

    return self;
}

- (NSMutableArray<RouteMultiPolyline *> *)addPolylines:
    (NSMutableArray<RouteMultiPolyline *> *)lines {
    UIColor *color;
    CGFloat dashPhase;
    int dashPatternId;

    if (self.route == kShapeNoRoute) {
        color = [UIColor cyanColor];
        dashPhase = 0;
        dashPatternId = kPolyLinePatternBus;
    } else {
        PtrConstRouteInfo info = [TriMetInfo infoForRouteNum:self.route];

        if (info == nil) {
            color = self.frequent ? [UIColor modeAwareFrequentBusColor]
                                  : [UIColor modeAwareBusColor];
            dashPatternId = 1;
            dashPhase = 0;
        } else {
            color = HTML_COLOR(info->html_color);
            dashPatternId = info->dash_pattern;
            dashPhase = info->dash_phase * kPolyLineSegLength;
        }
    }

    if (self.direct) {
        dashPatternId = kPolyLinePatternDirect;
    }

    NSMutableArray<MKPolyline *> *polys = NSMutableArray.array;

    for (id<ShapeSegment> seg in self.segments) {

        [polys addObject:seg.simplePolyline];
    }
    
    DEBUG_LOG_NSString(self.desc);
    DEBUG_LOG_long(polys.count);

    RouteMultiPolyline *line =
        [[RouteMultiPolyline alloc] initWithPolylines:polys];

    line.color = color;
    line.dashPatternId = dashPatternId;
    line.dashPhase = dashPhase;
    line.desc = self.desc;

    if (self.route != kShapeNoRoute) {
        line.route = self.routeStr;
        line.dir = self.dirDesc;
    }

    [lines addObject:line];

    return lines;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (self.segments) {
        [aCoder encodeObject:self.dirDesc forKey:kKeyDirDesc];
        [aCoder encodeObject:self.desc forKey:kKeyDesc];
        [aCoder encodeInteger:self.route forKey:kKeyRoute];
        [aCoder encodeObject:self.segments forKey:kKeySegments];
        [aCoder encodeBool:self.direct forKey:kKeyDirect];
        [aCoder encodeBool:self.frequent forKey:kKeyFreq];
    }
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        self.segments =
            [aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[
                          [NSMutableArray class], [ShapeCompactSegment class]
                      ]]
                                     forKey:kKeySegments];

        if (self.segments == nil) {
            self.segments = [NSMutableArray array];
        }

        self.dirDesc = [aDecoder decodeObjectOfClass:[NSString class]
                                              forKey:kKeyDirDesc];
        self.desc = [aDecoder decodeObjectOfClass:[NSString class]
                                           forKey:kKeyDesc];
        self.route = [aDecoder decodeIntegerForKey:kKeyRoute];
        self.direct = [aDecoder decodeBoolForKey:kKeyDirect];

        if ([aDecoder containsValueForKey:kKeyFreq]) {
            self.frequent = [aDecoder decodeBoolForKey:kKeyFreq];
            DEBUG_LOG(@"Freq %ld %d", self.route, self.frequent);
        } else {
            self.frequent = false;
        }
    }

    return self;
}

- (void)setRoute:(NSInteger)route {
    if (self.route != kShapeNoRoute) {
        self.routeStr =
            [NSString stringWithFormat:@"%lu", (unsigned long)route];
    }
    _route = route;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end
