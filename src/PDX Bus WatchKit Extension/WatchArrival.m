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

-(void)displayDepature:(WatchDepartureUI *)dep
{
    if (dep.data.errorMessage)
    {
        [self.heading setText:dep.data.errorMessage];
        self.exception.hidden = YES;
        self.blockColor.image = nil;
        [self.mins setText:nil];
    }
    else
    {
        [self.heading setAttributedText:[dep headingWithStatus]];

        [self.mins    setText:dep.minsToArrival];
        [self.mins    setTextColor:[dep getFontColor]];
        [self.lineColor setImage:[dep getRouteColorImage]];

        self.blockColor.image = [dep getBlockImageColor];
    
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
    }
}

@end
