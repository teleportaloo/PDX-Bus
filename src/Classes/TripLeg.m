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


@implementation TripLeg


#define ROW_HEIGHT kDepartureCellHeight

- (NSString *)direction:(NSString *)dir
{
    static NSDictionary *strmap = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        strmap = @{ @"n" : @"north",
                    @"s" : @"south" ,
                    @"e" : @"east"  ,
                    @"w" : @"west"  ,
                    @"ne": @"northeast",
                    @"se": @"southeast",
                    @"sw": @"southwest",
                    @"nw": @"northwest"};
    });
    
    NSString *ret = strmap[dir];
    
    if (ret == nil)
    {
        ret = dir;
    }
    
    return ret;
}

- (NSString*)mapLink:(NSString *)desc loc:(CLLocation*)loc textType:(TripTextType)type
{
    if (loc == nil || type != TripTextTypeHTML)
    {
        return desc;
    }
    return [NSString stringWithFormat:@"<a href=\"http://map.google.com/?q=location@%f,%f\">%@</a>",
            loc.coordinate.latitude, loc.coordinate.longitude, desc];
}



- (NSString*)createFromText:(bool)first textType:(TripTextType)type;
{
    NSMutableString * text  = [NSMutableString string];
    
    if (self.from !=nil)
    {
        if (![self.mode isEqualToString:kModeWalk])
        {
            if (type == TripTextTypeUI)
            {
                
                self.from.displayTimeText = self.xstartTime;
                self.from.leftColor = [UIColor modeAwareBlue];
                
                // Bug in response can give streetcar data as MAX Mode.
                
                if ([self.mode isEqualToString:kModeBus])
                {
                    self.from.displayModeText = [NSString stringWithFormat:@"Bus %@", self.xnumber];
                }
                else if ([self.mode isEqualToString:kModeMax])
                {
                    self.from.displayModeText = @"MAX";
                }
                else if ([self.mode isEqualToString:kModeSc])
                {
                    self.from.displayModeText = @"Streetcar";
                }
                else
                {
                    self.from.displayModeText = self.xnumber;
                }
                
                if (self.from.thruRoute)
                {
                    self.from.displayModeText = @"Stay on board";
                    self.from.leftColor = [UIColor modeAwareText];
                    
                    [text appendFormat:    @"#bStay on board#b at %@, route changes to '%@'", self.from.xdescription, self.xname];
                }
                else
                {
                    [text appendFormat:                @"#bBoard#b %@",self.xname];
                }
            }
            else
            {
                if (self.from.thruRoute)
                {
                    [text appendFormat:                @"%@ Stay on board %@,  route changes to '%@'", self.xstartTime,    self.from.xdescription, self.xname];
                }
                else
                {
                    [text appendFormat:                @"%@ Board %@",            self.xstartTime, self.xname];
                }
            }
        }
        else if (type == TripTextTypeMap)
        {
            int mins = self.xduration.intValue;
            
            if (mins > 0)
            {
                [text appendFormat:@"Walk %@ %@ ", [FormatDistance formatMiles:self.xdistance.doubleValue], [self direction:self.xdirection]];
            }
            else
            {
                [text appendFormat:@"Walk %@ ",  [self direction:self.xdirection]];
            }
            
            if (mins == 1)
            {
                [text appendString:@"for 1 min "];
            }
            else if (mins > 1)
            {
                [text appendFormat:@"for %d mins", mins];
            }
        }
    }
    
    while ([text replaceOccurrencesOfString:@"  "
                                 withString:@" "
                                    options:NSLiteralSearch
                                      range:NSMakeRange(0, text.length)] > 0)
    {
        ;
    }
    
    if (text.length !=0)
    {
        if (type == TripTextTypeHTML)
        {
            [text appendString:@"<br><br>"];
        }
        else if (type == TripTextTypeClip)
        {
            [text appendString:@"\n"];
        }
    }
    
    switch (type)
    {
        case TripTextTypeClip:
        case TripTextTypeHTML:
            break;
        case TripTextTypeMap:
            if (text.length != 0)
            {
                self.from.mapText = text;
            }
            break;
        case TripTextTypeUI:
            if (text.length != 0)
            {
                self.from.displayText = text;
            }
            break;
    }
    return text;
}



- (NSString *)createToText:(bool)last textType:(TripTextType)type;
{
    NSMutableString * text  = [NSMutableString string];
    if (self.to!=nil)
    {
        if ([self.mode isEqualToString:kModeWalk])
        {
            if (type == TripTextTypeMap)
            {
                if (last)
                {
                    [text appendFormat:    @"Destination"];
                }
            }
            else  // type is not map
            {
                if (type == TripTextTypeUI)
                {
                    self.to.displayModeText = self.mode;
                    self.to.leftColor = [UIColor modeAwarePurple];
                }
                int mins = self.xduration.intValue;
                
                if (mins > 0)
                {
                    if (type == TripTextTypeUI)
                    {
                        [text appendFormat:@"#bWalk#b %@ %@ ", [FormatDistance formatMiles:self.xdistance.doubleValue], [self direction:self.xdirection]];
                    }
                    else
                    {
                        [text appendFormat:@"Walk %@ %@ ", [FormatDistance formatMiles:self.xdistance.doubleValue], [self direction:self.xdirection]];
                    }
                }
                else // multiple mins
                {
                    [text appendFormat:@"Walk %@ ",  [self direction:self.xdirection]];
                    self.to.displayModeText = @"Short\nWalk";
                }
                
                
                if (mins == 1)
                {
                    if (type == TripTextTypeUI)
                    {
                        self.to.displayTimeText = @"1 min";
                    }
                    else
                    {
                        [text appendFormat:@"for 1 minute "];
                    }
                }
                else if (mins > 1)
                {
                    if (type == TripTextTypeUI)
                    {
                        self.to.displayTimeText = [NSString stringWithFormat:@"%d mins", mins];
                    }
                    else
                    {
                        [text appendFormat:@"for %d minutes ", mins];
                    }
                }
                
                
                [text appendFormat:@"%@%@",
                 @"to ",
                 [self mapLink:self.to.xdescription loc:self.to.loc textType:type]];
            }
            
        }
        else // mode is not to walk
        {
            switch (type)
            {
                case TripTextTypeMap:
                    if (last)
                    {
                        [text appendFormat:    @"%@ get off at %@", self.xendTime, self.to.xdescription];
                    }
                    break;
                case TripTextTypeHTML:
                case TripTextTypeClip:
                    if (self.to.thruRoute)
                    {
                        [text appendFormat:    @"%@ stay on board at %@", self.xendTime, [self mapLink:self.to.xdescription loc:self.to.loc textType:type]];
                    }
                    else
                    {
                        [text appendFormat:    @"%@ get off at %@", self.xendTime, [self mapLink:self.to.xdescription loc:self.to.loc textType:type]];
                    }
                    break;
                case TripTextTypeUI:
                    self.to.displayTimeText = self.xendTime;
                    if (!self.to.thruRoute)
                    {
                        self.to.displayModeText = @"Deboard";
                        self.to.leftColor = [UIColor redColor];
                        [text appendFormat:    @"#bGet off#b at %@", self.to.xdescription];
                    }
                    break;
            }
        }
        
        
        if (self.to.xstopId != nil)
        {
            switch (type)
            {
                case TripTextTypeMap:
                    break;
                case TripTextTypeUI:
                case TripTextTypeClip:
                    [text appendFormat:@" (Stop ID %@)", [self.to stopId]];
                    break;
                case TripTextTypeHTML:
                    [text appendFormat:@" (Stop ID <a href=\"pdxbus://%@?%@/\">%@</a>)",
                     [self.to.xdescription stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                     [self.to stopId], [self.to stopId]];
                    break;
            }
        }
    }
    
    
    switch (type)
    {
        case TripTextTypeHTML:
            if (!self.to.thruRoute)
            {
                [text appendFormat:                @"<br><br>"];

            }
            else
            {
                text = [NSMutableString string];
            }
            break;
        case TripTextTypeMap:
            if (text.length != 0)
            {
                self.to.mapText = text;
            }
            break;
        
        case TripTextTypeClip:
            [text appendFormat:                @"\n"];
        case TripTextTypeUI:
            if (!self.to.thruRoute)
            {
                self.to.displayText = text;
            }
            break;
    }
    return text;
}

@end
