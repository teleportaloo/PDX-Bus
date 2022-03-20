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
#import "RoutePolyline.h"
#import "TriMetInfo.h"
#import "UIColor+DarkMode.h"

#define kKeyRoute    @"r"
#define kKeySegments @"s"
#define kKeyDirect   @"d"
#define kKeyDesc     @"i"
#define kKeyDirDesc  @"e"

@implementation ShapeRoutePath

- (instancetype)init {
    if (self = [super init]) {
        self.segments = [NSMutableArray array];
    }
    
    return self;
}

- (NSMutableArray<RoutePolyline *> *)addPolylines:(NSMutableArray<RoutePolyline *> *)lines {
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
            color = [UIColor modeAwareBusColor];
            dashPatternId = 1;
            dashPhase = 0;
        } else {
            color = [TriMetInfo cachedColor:info->html_color];
            dashPatternId = info->dash_pattern;
            dashPhase = info->dash_phase * kPolyLineSegLength;
        }
    }
    
    if (self.direct) {
        dashPatternId = kPolyLinePatternDirect;
    }
    
    for (id<ShapeSegment> seg in self.segments) {
        [lines addObject:[seg polyline:color dashPatternId:dashPatternId dashPhase:dashPhase path:self]];
    }
    
    return lines;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (self.segments) {
        [aCoder encodeObject:self.dirDesc forKey:kKeyDirDesc];
        [aCoder encodeObject:self.desc forKey:kKeyDesc];
        [aCoder encodeInteger:self.route forKey:kKeyRoute];
        [aCoder encodeObject:self.segments forKey:kKeySegments];
        [aCoder encodeBool:self.direct forKey:kKeyDirect];
    }
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        self.segments = [aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[ [NSMutableArray class], [ShapeCompactSegment class] ]] forKey:kKeySegments];
        
        if (self.segments == nil) {
            self.segments = [NSMutableArray array];
        }
        
        self.dirDesc = [aDecoder decodeObjectOfClass:[NSString class] forKey:kKeyDirDesc];
        self.desc = [aDecoder decodeObjectOfClass:[NSString class] forKey:kKeyDesc];
        self.route = [aDecoder decodeIntegerForKey:kKeyRoute];
        self.direct = [aDecoder decodeBoolForKey:kKeyDirect];
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end
