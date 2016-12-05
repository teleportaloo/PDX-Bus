//
//  WatchDepartureUI.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/12/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureData+watchOSUI.h"
#import "TriMetRouteColors.h"
#import "BlockColorDb.h"
#import "MapAnnotationImage.h"
#import "StringHelper.h"

@implementation DepartureData (watchOSUI)

@dynamic blockImageColor;
@dynamic stale;


- (UIColor*)getFontColor
{
    int mins = self.minsToArrival;
    UIColor *timeColor = nil;
    
    if (self.status == kStatusScheduled)
    {
        timeColor = [UIColor grayColor];
    }
    else if (mins < 6 || self.status == kStatusCancelled)
    {
        timeColor = [UIColor redColor];
    }
    else
    {
        timeColor = [UIColor blueColor];
    }
    
    return timeColor;
}

- (UIImage *)getRouteColorImage
{
    static NSMutableDictionary *imageCache = nil;
    
    UIImage *image = nil;
    
    if (imageCache == nil)
    {
        imageCache = [[NSMutableDictionary alloc] init];
    }
    
    const ROUTE_COL *raw =  [TriMetRouteColors rawColorForRoute:self.route];
    
    if (raw != NULL)
    {
        image = imageCache[self.route];
        
        if (image == nil)
        {
            const ROUTE_COL *raw =  [TriMetRouteColors rawColorForRoute:self.route];
            
            CGRect rect = CGRectMake(0.0f, 0.0f, 20.0f, 20.0f);
            UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
            
            // Drawing code
            
            CGMutablePathRef fillPath = CGPathCreateMutable();
            
            CGRect outerSquare;
            
            CGFloat width = fmin(CGRectGetWidth(rect), CGRectGetHeight(rect));
            
            outerSquare.origin.x = CGRectGetMidX(rect) - width/2;
            outerSquare.origin.y = CGRectGetMidY(rect) - width/2;
            outerSquare.size.width = width;
            outerSquare.size.height = width;
            
            if (raw->square)
            {
                CGRect innerSquare = CGRectInset(outerSquare, 1, 1);
                CGPathAddRect(fillPath, NULL, innerSquare);
            }
            else
            {
                CGPathAddEllipseInRect(fillPath, NULL, outerSquare);
            }
            
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetRGBFillColor(context, raw->r , raw->g, raw->b, 1.0);
            CGContextAddPath(context, fillPath);
            CGContextFillPath(context);
            
            CGPathRelease(fillPath);
            
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            
            imageCache[self.route] = image;
        }
    }
    
    return image;
}

- (UIImage*)blockImageColor
{
    BlockColorDb *db = [BlockColorDb singleton];
    db.colorMap = nil;
    
    UIColor *color = [db colorForBlock:self.block];
    
    if (color == nil)
    {
        return nil;
    }
    
    static NSMutableDictionary *imageCache = nil;
    
    if (imageCache == nil)
    {
        imageCache = [[NSMutableDictionary alloc] init];
    }
    
    UIImage *image = imageCache[color];
    
    if (image == nil)
    {
        CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillRect(context, rect);
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        imageCache[color] = image;
    }
        
    return image;
}

- (NSString*)formattedMinsToArrival
{
    if (self.status == kStatusCancelled)
    {
        return @"❌";
    }
    else if (self.minsToArrival < 0 || self.invalidated)
    {
        return @"-";
    }
    else if (self.minsToArrival < 1)
    {
        return @"Due";
    }
    else if (self.minsToArrival < 100)
    {
        return [NSString stringWithFormat:@"%d", self.minsToArrival];
    }
    else
    {
        return @"::";
    }
}
- (bool)hasRouteColor
{
    return [TriMetRouteColors rawColorForRoute:self.route] != nil;
}

- (NSAttributedString *)headingWithStatus
{
    NSMutableAttributedString * string = @"".mutableAttributedString;
    
    UIColor *statusColor = [UIColor blackColor];
    
    if (self.status == kStatusCancelled)
    {
        statusColor = [UIColor orangeColor];
    }
    else if (self.detour)
    {
        statusColor = [UIColor orangeColor];
    }
    else if (self.status == kStatusScheduled)
    {
         statusColor = [UIColor grayColor];
    }
    
    if (self.routeName!=nil)
    {
        NSAttributedString *subString = [[NSAttributedString alloc] initWithString:self.routeName
                                                                        attributes:@{NSForegroundColorAttributeName:statusColor}].autorelease;
        [string appendAttributedString:subString];
    }

/*
    if (self.data.status == kStatusCancelled)
    {
        attributes = [NSDictionary dictionaryWithObject:[UIColor redColor] forKey:NSForegroundColorAttributeName];
        subString = [[[NSAttributedString alloc] initWithString:@"\n❌cancelled" attributes:attributes] autorelease];
        [string appendAttributedString:subString];
    }
    else if (self.data.detour)
    {
        attributes = [NSDictionary dictionaryWithObject:[UIColor orangeColor] forKey:NSForegroundColorAttributeName];
        subString = [[[NSAttributedString alloc] initWithString:@"\n⚠️detour" attributes:attributes] autorelease];
        [string appendAttributedString:subString];
    }
    
    if (self.data.status == kStatusScheduled)
    {
        attributes = [NSDictionary dictionaryWithObject:[UIColor grayColor] forKey:NSForegroundColorAttributeName];
        subString = [[[NSAttributedString alloc] initWithString:@"\n🕔scheduled" attributes:attributes] autorelease];
        [string appendAttributedString:subString];
    }
*/
    return string;
}

- (bool)stale
{
    return (self.timeAdjustment > kStaleTime && !self.invalidated);
}

- (NSString *)exception
{
    NSMutableString *result = [@"".mutableCopy autorelease];
    
    bool needsNewl = NO;
    
    
    if (self.detour)
    {
        if (needsNewl)
        {
            [result appendString:@"\n"];
            needsNewl = NO;
        }
        [result appendString:@"⚠️"];
    }
    
    if (self.status == kStatusScheduled)
    {
        if (needsNewl)
        {
            [result appendString:@"\n"];
        }
        [result appendString:@"🕔"];
    }
    
    return result;
}


- (WKInterfaceMapPinColor)pinColor
{
    return WKInterfaceMapPinColorRed;
}
- (UIColor*)pinTint
{
    UIColor *ret = [TriMetRouteColors colorForRoute:self.route];
    
    if (ret == nil)
    {
        ret = kMapAnnotationBusColor;
    }
    return ret;
}
- (bool)hasBearing
{
    return self.blockPositionHeading!=nil;
}
- (double)doubleBearing
{
    return self.blockPositionHeading.doubleValue;
}

- (CLLocationCoordinate2D)coord
{
    return self.blockPosition.coordinate;
}

@end
