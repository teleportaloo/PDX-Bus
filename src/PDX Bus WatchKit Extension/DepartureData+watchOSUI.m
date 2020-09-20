//
//  WatchDepartureUI.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/12/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureData+watchOSUI.h"
#import "TriMetInfo.h"
#import "BlockColorDb.h"
#import "MapAnnotationImageFactory.h"
#import "NSString+Helper.h"
#import "ArrivalColors.h"

@implementation Departure (watchOSUI)

@dynamic blockImageColor;
@dynamic stale;


- (UIColor *)fontColor {
    int mins = self.minsToArrival;
    UIColor *timeColor = nil;
    
    if (self.status == kStatusScheduled) {
        timeColor = ArrivalColorScheduled;
    } else if (self.actuallyLate) {
        timeColor = ArrivalColorLate;
    } else if (mins < 6 || self.status == kStatusCancelled) {
        timeColor = ArrivalColorSoon;
    } else {
        timeColor = ArrivalColorOK;
    }
    
    return timeColor;
}

- (UIImage *)routeColorImage {
    static NSMutableDictionary *imageCache = nil;
    
    UIImage *image = nil;
    
    if (imageCache == nil) {
        imageCache = [[NSMutableDictionary alloc] init];
    }
    
    PC_ROUTE_INFO raw = [TriMetInfo infoForRoute:self.route];
    
    if (raw != NULL) {
        image = imageCache[self.route];
        
        if (image == nil) {
            PC_ROUTE_INFO raw = [TriMetInfo infoForRoute:self.route];
            
            CGRect rect = CGRectMake(0.0f, 0.0f, 20.0f, 20.0f);
            
            /* Note:  This is a graphics context block */
            UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
            
            CGMutablePathRef fillPath = CGPathCreateMutable();
            CGRect outerSquare;
            CGFloat width = fmin(CGRectGetWidth(rect), CGRectGetHeight(rect));
            outerSquare.origin.x = CGRectGetMidX(rect) - width / 2;
            outerSquare.origin.y = CGRectGetMidY(rect) - width / 2;
            outerSquare.size.width = width;
            outerSquare.size.height = width;
            
            if (raw->streetcar) {
                CGRect innerSquare = CGRectInset(outerSquare, 1, 1);
                CGPathAddRect(fillPath, NULL, innerSquare);
            } else {
                CGPathAddEllipseInRect(fillPath, NULL, outerSquare);
            }
            
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetRGBFillColor(context, COL_HTML_R(raw->html_color), COL_HTML_G(raw->html_color), COL_HTML_B(raw->html_color), 1.0);
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

- (UIImage *)blockImageColor {
    BlockColorDb *db = [BlockColorDb sharedInstance];
    
    db.colorMap = nil;
    
    UIColor *color = [db colorForBlock:self.block];
    
    if (color == nil) {
        return nil;
    }
    
    static NSMutableDictionary *imageCache = nil;
    
    if (imageCache == nil) {
        imageCache = [[NSMutableDictionary alloc] init];
    }
    
    UIImage *image = imageCache[color];
    
    if (image == nil) {
        CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
        
        /* Note:  This is a graphics context block */
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

- (NSString *)formattedMinsToArrival {
    if (self.status == kStatusCancelled) {
        return @"❌";
    } else if (self.minsToArrival < 0 || self.invalidated) {
        return @"-";
    } else if (self.minsToArrival < 1) {
        return @"Due";
    } else if (self.minsToArrival < 60) {
        return [NSString stringWithFormat:@"%d", self.minsToArrival];
    } else {
        ArrivalWindow arrivalWindow;
        NSDateFormatter *dateFormatter = [self dateAndTimeFormatterWithPossibleLongDateStyle:kLongDateFormat arrivalWindow:&arrivalWindow];
        
        switch (arrivalWindow) {
            case ArrivalSoon:
                dateFormatter.dateFormat = @"a";
                return [dateFormatter stringFromDate:self.departureTime];
                
            case ArrivalThisWeek:
                dateFormatter.dateFormat = @"E";
                return [dateFormatter stringFromDate:self.departureTime];
                
            case ArrivalNextWeek:
            default:
                return @"::";
        }
        
        return @"::";
    }
}

- (bool)hasRouteColor {
    return [TriMetInfo infoForRoute:self.route] != nil;
}

- (NSAttributedString *)headingWithStatus {
    NSMutableAttributedString *string = @"".mutableAttributedString;
    
    UIColor *statusColor = [UIColor blackColor];
    
    if (self.status == kStatusCancelled) {
        statusColor = [UIColor orangeColor];
    } else if (self.detour) {
        statusColor = [UIColor orangeColor];
    } else if (self.status == kStatusScheduled) {
        statusColor = [UIColor grayColor];
    }
    
    if (self.shortSign != nil) {
        NSAttributedString *subString = [self.shortSign attributedStringWithAttributes:@{ NSForegroundColorAttributeName: statusColor }];
        [string appendAttributedString:subString];
    }
    
    return string;
}

- (bool)stale {
    return (self.timeAdjustment > kStaleTime && !self.invalidated);
}

- (NSString *)exception {
    NSMutableString *result = @"".mutableCopy;
    
    bool needsNewl = NO;
    
    
    if (self.detour) {
        if (needsNewl) {
            [result appendString:@"\n"];
            needsNewl = NO;
        }
        
        [result appendString:@"⚠️"];
    }
    
    if (self.status == kStatusScheduled) {
        if (needsNewl) {
            [result appendString:@"\n"];
        }
        
        [result appendString:@"🕔"];
    }
    
    return result;
}

- (WKInterfaceMapPinColor)pinColor {
    return WKInterfaceMapPinColorRed;
}

- (UIColor *)pinTint {
    UIColor *ret = [TriMetInfo colorForRoute:self.route];
    
    if (ret == nil) {
        ret = [UIColor modeAwareBusColor];
    }
    
    return ret;
}

- (bool)hasBearing {
    return self.blockPositionHeading != nil;
}

- (double)doubleBearing {
    return self.blockPositionHeading.doubleValue;
}

- (CLLocationCoordinate2D)coord {
    return self.blockPosition.coordinate;
}

- (bool)hasCoord {
    return self.hasBlock && self.blockPosition.coordinate.latitude != 0;
}

@end
