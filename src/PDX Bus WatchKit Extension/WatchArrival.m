//
//  WatchTrainArrival.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/16/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchArrival.h"

@implementation WatchArrival

- (void)dealloc
{
    self.lineColor  = nil;
    self.blockColor = nil;
    self.exception  = nil;
    self.heading    = nil;
    self.mins       = nil;
    self.stale      = nil;
    
    [super dealloc];
}

-(void)displayDeparture:(DepartureData *)dep
{
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
        [self.mins    setTextColor:dep.getFontColor];
        [self.lineColor setImage:dep.getRouteColorImage];

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

@end
