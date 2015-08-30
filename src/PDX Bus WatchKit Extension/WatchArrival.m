//
//  WatchTrainArrival.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/16/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

/* INSERT_LICENSE */

#import "WatchArrival.h"

@implementation WatchArrival

-(void)displayDepature:(WatchDepartureUI *)dep
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

@end
