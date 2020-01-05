//
//  TripItinerary.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripItinerary.h"

@implementation TripItinerary


- (instancetype)init {
    if ((self = [super init]))
    {
        self.legs = [NSMutableArray array];
        
        
    }
    return self;
}

- (bool)hasFare
{
    return self.fare != nil && self.fare.length!=0;
}

- (TripLeg*) getLeg:(int)item
{
    return self.legs[item];
}

- (NSString *)shortTravelTime
{
    
    NSMutableString *strTime = [NSMutableString string];
    int t = self.xduration.intValue;
    int h = t/60;
    int m = t%60;
    
    [strTime appendFormat:NSLocalizedString(@"Travel time: %d:%02d", @"hours, mins"), h, m];
    return strTime;
}


- (NSString *)mins:(int)t
{
    if (t==1)
    {
        return @"1 min";
    }
    return [NSString stringWithFormat:NSLocalizedString(@"%d mins", @"minutes"), t];
}

- (NSString *)travelTime
{
    NSMutableString *strTime = [NSMutableString string];
    int t = self.xduration.intValue;
    
    [strTime appendString:[self mins:t]];
    
    bool inc = false;
    
    if (self.xwalkingTime != nil)
    {
        int walking = self.xwalkingTime.intValue;
        
        if (walking > 0)
        {
            [strTime appendFormat: NSLocalizedString(@", including %@ walking", @"time info, minutes"), [self mins:walking]];
            inc = true;
        }
    }
    
    if (self.xwaitingTime !=nil)
    {
        int waiting = self.xwaitingTime.intValue;
        
        if (waiting > 0)
        {
            if (!inc)
            {
                [strTime appendFormat: NSLocalizedString(@", including %@ waiting", @"time info, minutes"), [self mins:waiting]];
            }
            else
            {
                [strTime appendFormat: NSLocalizedString(@" and %@ waiting", @"time info, minutes"), [self mins:waiting]];
            }
        }
    }
    
    [strTime appendString: @"."];
    
    return strTime;
}

- (NSInteger)legCount
{
    if (self.legs)
    {
        return self.legs.count;
    }
    return 0;
}

- (NSString *)startPointText:(TripTextType)type
{
    NSMutableString * text  = [NSMutableString string];
    
    TripLeg * firstLeg = nil;
    TripLegEndPoint * firstPoint = nil;
    
    if (self.legs.count > 0)
    {
        firstLeg = self.legs.firstObject;
        firstPoint = firstLeg.from;
    }
    else
    {
        return nil;
    }
    
    if (self.startPoint == nil)
    {
        self.startPoint = [firstPoint copy];
    }
    
    if (firstPoint!=nil && type != TripTextTypeMap)
    {
        bool nearTo = [firstPoint.xdescription hasPrefix:kNearTo];
        
        if (type == TripTextTypeUI)
        {
            self.startPoint.displayModeText = @"Start";
            [text appendFormat:@"%@%@", nearTo ? @"" : @"#bStart at#b ", firstPoint.xdescription];
        }
        else if (type == TripTextTypeHTML && firstPoint.loc != nil)
        {
            [text appendFormat:@"%@<a href=\"http://map.google.com/?q=location@%f,%f\">%@</a>",
             nearTo ? @"Start " : @"Start at ",
             firstPoint.coordinate.latitude, firstPoint.coordinate.longitude,  firstPoint.xdescription];
        }
        else
        {
            [text appendFormat:@"%@%@", nearTo ? @"Starting " : @"Starting at ",firstPoint.xdescription];
        }
    }
    
    if (self.startPoint.xstopId !=nil)
    {
        if (type == TripTextTypeHTML)
        {
            [text appendFormat:@" (Stop ID <a href=\"pdxbus://%@?%@/\">%@</a>)",
             [self.startPoint.xdescription    stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
             [self.startPoint stopId], [firstPoint stopId]];
        }
        else
        {
            [text appendFormat:@" (Stop ID %@)", [self.startPoint stopId]];
        }
    }
    
    
    switch (type)
    {
        case TripTextTypeHTML:
            [text appendFormat:                @"<br><br>"];
            break;
        case TripTextTypeMap:
            if (text.length != 0)
            {
                self.startPoint.mapText = text;
            }
            break;
        case TripTextTypeClip:
            [text appendFormat:                @"\n"];
        case TripTextTypeUI:
            self.startPoint.displayText = text;
            break;
    }
    return text;
}

- (bool)hasBlocks
{
    for (TripLeg *leg in self.legs)
    {
        if (leg.xblock!=nil && leg.xblock.length!=0)
        {
            return YES;
        }
    }
    
    return NO;
}

@end


