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

#pragma mark ShapeCoord

@implementation ShapeCoord

@dynamic longitude;
@dynamic latitude;

+ (instancetype) coordWithLat:(CLLocationDegrees)lat lng:(CLLocationDegrees)lng
{
    ShapeCoord *coord = [[[self class] alloc] init];
    
    coord.latitude = lat;
    coord.longitude = lng;
    
    return coord;
}

- (CLLocationDegrees)latitude
{
    return _coord.latitude;
}

- (CLLocationDegrees)longitude
{
    return _coord.longitude;
}

- (void)setLatitude:(CLLocationDegrees)val
{
    _coord.latitude = val;
}

- (void)setLongitude:(CLLocationDegrees)val
{
    _coord.longitude = val;
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        
    }
    return self;
}

@end

#pragma mark ShapeSegment

@implementation ShapeSegment

@dynamic count;

-  (ShapeCompactSegment *) compact
{
    return nil;
}

- (RoutePolyline*) polyline
{
    return nil;
}

- (bool)isEqual:(ShapeSegment*)seg
{
    return NO;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super init]))
    {
        
    }
    return self;
}

- (NSInteger)count
{
    return 0;
}

- (void)setCount:(NSInteger)count
{
    
}

@end

#pragma mark ShapeCompactSegment

@implementation ShapeCompactSegment

@synthesize count = _count;

- (void) dealloc
{
    free (_coords);
}

- (instancetype)init
{
    if (self = [super init])
    {
        
    }
    return self;
}

-  (ShapeCompactSegment *)compact
{
    return self;
}

- (bool)isEqual:(ShapeSegment*)seg
{
    if (seg)
    {
        if (self.count == seg.count)
        {
            ShapeCompactSegment *compact = seg.compact;
        
            if (compact && compact.coords && self.coords)
            {
                return memcmp(self.coords, compact.coords, _count * sizeof(_coords[0])) == 0;
            }
        }
    }
    return NO;
}

- (RoutePolyline*)polyline:(UIColor *)color dashPatternId:(int)dashPatternId dashPhase:(CGFloat)dashPhase path:(ShapeRoutePath *)path
{
    RoutePolyline *polyLine =[RoutePolyline polylineWithCoordinates:self.coords count:self.count];
    polyLine.color = color;
    polyLine.dashPatternId = dashPatternId;
    polyLine.dashPhase = dashPhase;
    polyLine.desc = path.desc;
    
    if (path.route!= kShapeNoRoute)
    {
        polyLine.route = [NSString stringWithFormat:@"%lu", (unsigned long)path.route];
        polyLine.dir = path.dirDesc;
    }
    return polyLine;
}



#define kKeyRoute         @"r"
#define kKeyCoords        @"c"
#define kKeySegments      @"s"
#define kKeyDirect        @"d"
#define kKeyDesc          @"i"
#define kKeyDirDesc       @"e"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    
    if (_coords && _count > 0)
    {
        [aCoder encodeBytes:(uint8_t *)_coords length:sizeof(_coords[0])*_count forKey:kKeyCoords];
    }
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        NSUInteger length=0;
        const uint8_t* bytes = [aDecoder decodeBytesForKey:kKeyCoords returnedLength:&length];
        
        // check size
        if (length % sizeof(CLLocationCoordinate2D)==0)
        {
            _count = length / sizeof(CLLocationCoordinate2D);
            _coords = (CLLocationCoordinate2D*) malloc(length);
            memcpy(_coords, bytes, length);
        }
    }
    return self;
}

@end

#pragma mark ShapeMutableSegment

@implementation ShapeMutableSegment


- (instancetype)init
{
    if (self = [super init])
    {
        self.coords = [NSMutableArray array];
    }
    return self;
}

-  (ShapeCompactSegment *) compact
{
    ShapeCompactSegment *compact = [ShapeCompactSegment data];
    
    if (self.coords && self.coords.count > 0)
    {
        CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * self.coords.count);
        CLLocationCoordinate2D *p = coords;
        
        for (ShapeCoord *c in self.coords)
        {
            *p = c.coord;
            p++;
        }
        
        compact.coords = coords;
        compact.count = self.coords.count;
    }
    
    return compact;
}

- (NSInteger)count
{
    return self.coords.count;
}

@end

#pragma mark ShapeRoutePath

@implementation ShapeRoutePath


- (instancetype)init
{
    if (self = [super init])
    {
        self.segments = [NSMutableArray array];
    }
    
    return self;
}

- (NSMutableArray<RoutePolyline*>*) addPolylines:(NSMutableArray<RoutePolyline*>*)lines
{
    UIColor *color;
    CGFloat dashPhase;
    int dashPatternId;
    
    if (self.route == kShapeNoRoute)
    {
        color = [UIColor cyanColor];
        dashPhase = 0;
        dashPatternId = kPolyLinePatternBus;
    }
    else
    {
        PC_ROUTE_INFO info = [TriMetInfo infoForRouteNum:self.route];
        
        if (info == nil)
        {
            color = [UIColor modeAwareBusColor];
            dashPatternId = 1;
            dashPhase = 0;
        }
        else
        {
            color = [TriMetInfo cachedColor:info->html_color];
            dashPatternId = info->dash_pattern;
            dashPhase = info->dash_phase * kPolyLineSegLength;
        }
    }
    
    if (self.direct)
    {
        dashPatternId = kPolyLinePatternDirect;
    }
    
    for (ShapeSegment *seg in self.segments)
    {
        [lines addObject:[seg.compact polyline:color dashPatternId:dashPatternId dashPhase:dashPhase path:self]];
    }
    
    return lines;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if (self.segments)
    {
        [aCoder encodeObject:self.dirDesc   forKey:kKeyDirDesc];
        [aCoder encodeObject:self.desc      forKey:kKeyDesc];
        [aCoder encodeInteger:self.route    forKey:kKeyRoute];
        [aCoder encodeObject:self.segments  forKey:kKeySegments];
        [aCoder encodeBool:self.direct      forKey:kKeyDirect];
    }
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super init]))
    {
        self.segments = [aDecoder decodeObjectForKey:kKeySegments];
        
        if (self.segments==nil)
        {
            self.segments = [NSMutableArray array];
        }
        
        self.dirDesc =  [aDecoder decodeObjectForKey:   kKeyDirDesc];
        self.desc =     [aDecoder decodeObjectForKey:   kKeyDesc];
        self.route =    [aDecoder decodeIntegerForKey:  kKeyRoute];
        self.direct =   [aDecoder decodeBoolForKey:     kKeyDirect];
    }
    return self;
}

@end
