//
//  WatchTrainArrival.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/16/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchArrival.h"
#import "WatchArrivalsContext.h"

@implementation WatchArrival


+ (NSString *)identifier
{
    return @"Arrival";
}

- (void)populate:(XMLDepartures *)xml departures:(NSArray<DepartureData*>*)deps
{
    DepartureData *dep = deps[self.index.integerValue];

    if (dep.errorMessage)
    {
        [self.heading setText:dep.errorMessage];
        self.exception.hidden = YES;
        self.stale.hidden = YES;
        self.blockColor.image = nil;
        [self.mins setText:nil];
    }
    else
    {
        [self.heading setAttributedText:dep.headingWithStatus];
        [self.mins    setText:dep.formattedMinsToArrival];
        [self.mins    setTextColor:dep.fontColor];
        [self.lineColor setImage:dep.routeColorImage];

        self.blockColor.image = dep.blockImageColor;
    
        NSString *exception = dep.exception;
    
        if (exception)
        {
            self.exception.text = exception;
            self.exception.hidden = NO;
        }
        else
        {
            self.exception.hidden = YES;
        }
        
        self.stale.hidden = !dep.stale;
        
    }
}

- (bool)select:(XMLDepartures *)xml from:(WKInterfaceController *)from context:(WatchArrivalsContext*)context
{
    WatchArrivalsContext *detailContext = [context clone];
    
    if (detailContext == nil)
    {
        detailContext = [[WatchArrivalsContext alloc] init];
    }
    DepartureData *data = xml[self.index.integerValue];
    
    detailContext.detailBlock   = data.block;
    detailContext.locid         = context.locid;
    detailContext.stopDesc      = context.stopDesc;
    detailContext.navText       = context.navText;
    detailContext.departures    = xml;
    
    [detailContext pushFrom:from];
    
    
    return YES;
}

@end
