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


#import "WatchDepartureUI.h"
#import "TriMetRouteColors.h"
#import "BlockColorDb.h"
#import "MapAnnotationImage.h"

@implementation WatchDepartureUI

+ (WatchDepartureUI*) createFromData:(DepartureData *)data
{
    WatchDepartureUI *item = [[[WatchDepartureUI alloc] initWithData:data] autorelease];
    
    return item;
}

- (void)dealloc
{
    self.data = nil;
    
    [super dealloc];
}

- (id)initWithData:(DepartureData *)data
{
    if ((self = [super init]))
    {
        self.data = data;
    }
    return self;
}

- (UIColor*)getFontColor
{
    int mins = _data.minsToArrival;
    UIColor *timeColor = nil;
    
    if (self.data.status == kStatusScheduled)
    {
        timeColor = [UIColor grayColor];
    }
    else if (mins < 6 || self.data.status == kStatusCancelled)
    {
        timeColor = [UIColor redColor];
    }
    else
    {
        timeColor = [UIColor blueColor];
    }
    
    return timeColor;
}

#define min(X,Y) ((X)<(Y)?(X):(Y))

- (UIImage *)getRouteColorImage
{
    static NSMutableDictionary *imageCache = nil;
    
    UIImage *image = nil;
    
    if (imageCache == nil)
    {
        imageCache = [[NSMutableDictionary alloc] init];
    }
    
    ROUTE_COL *raw =  [TriMetRouteColors rawColorForRoute:self.data.route];
    
    if (raw != NULL)
    {
        image = [imageCache objectForKey:self.data.route];
        
        if (image == nil)
        {
            ROUTE_COL *raw =  [TriMetRouteColors rawColorForRoute:self.data.route];
            
            CGRect rect = CGRectMake(0.0f, 0.0f, 20.0f, 20.0f);
            UIGraphicsBeginImageContext(rect.size);
            
            // Drawing code
            
            CGMutablePathRef fillPath = CGPathCreateMutable();
            
            CGRect outerSquare;
            
            CGFloat width = min(CGRectGetWidth(rect), CGRectGetHeight(rect));
            
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
            
            
            [imageCache setObject:image forKey:self.data.route];
        }
    }
    
    return image;
}

- (UIImage*)getBlockImageColor
{
    BlockColorDb *db = [BlockColorDb getSingleton];
    db.colorMap = nil;
    
    UIColor *color = [db colorForBlock:self.data.block];
    
    if (color == nil)
    {
        return nil;
    }
    
    static NSMutableDictionary *imageCache = nil;
    
    if (imageCache == nil)
    {
        imageCache = [[NSMutableDictionary alloc] init];
    }
    
    UIImage *image = [imageCache objectForKey:color];
    
    if (image == nil)
    {
        CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
        UIGraphicsBeginImageContext(rect.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSetFillColorWithColor(context, [color CGColor]);
        CGContextFillRect(context, rect);
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [imageCache setObject:image forKey:color];
    }
        
    return image;
}

- (NSString*)minsToArrival
{
    if (self.data.status == kStatusCancelled)
    {
        return @"❌";
    }
    else if (self.data.minsToArrival < 0 || self.data.invalidated)
    {
        return @"-";
    }
    else if (self.data.minsToArrival < 1)
    {
        return @"Due";
    }
    else if (self.data.minsToArrival < 100)
    {
        return [NSString stringWithFormat:@"%d", self.data.minsToArrival];
    }
    else
    {
        return @"::";
    }
}
- (bool)hasRouteColor
{
    return [TriMetRouteColors rawColorForRoute:self.data.route] != nil;
}

- (NSAttributedString *)headingWithStatus
{
    NSMutableAttributedString * string = [[[NSMutableAttributedString alloc] initWithString:@""] autorelease];
    
    UIColor *statusColor = [UIColor blackColor];
    
    if (self.data.status == kStatusCancelled)
    {
        statusColor = [UIColor orangeColor];
    }
    else if (self.data.detour)
    {
        statusColor = [UIColor orangeColor];
    }
    else if (self.data.status == kStatusScheduled)
    {
         statusColor = [UIColor grayColor];
    }
    
    if (self.data.routeName!=nil)
    {
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:statusColor forKey:NSForegroundColorAttributeName];
        NSAttributedString *subString = [[[NSAttributedString alloc] initWithString:self.data.routeName attributes:attributes] autorelease];
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

- (NSString *)exception
{
    NSString *result = nil;
    if (self.data.detour)
    {
        result = @"⚠️";
    }
    else if (self.data.status == kStatusScheduled)
    {
        result = @"🕔";
    }
    
    return result;
}


- (WKInterfaceMapPinColor)getPinColor
{
    return WKInterfaceMapPinColorRed;
}
- (UIColor*)getPinTint
{
    UIColor *ret = [TriMetRouteColors colorForRoute:self.data.route];
    
    if (ret == nil)
    {
        ret = kMapAnnotationBusColor;
    }
    return ret;
}
- (bool)hasBearing
{
    return self.data.blockPositionHeading!=nil;
}
- (double)bearing
{
    return self.data.blockPositionHeading.doubleValue;
}

- (CLLocationCoordinate2D)coord
{
    return self.data.blockPosition.coordinate;
}

@end
