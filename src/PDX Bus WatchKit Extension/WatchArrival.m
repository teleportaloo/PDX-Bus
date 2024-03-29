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


+ (NSString *)identifier {
    return @"Arrival";
}

- (void)populate:(XMLDepartures *)xml departures:(NSArray<Departure *> *)deps {
    Departure *dep = deps[self.index.integerValue];
    
    if (dep.errorMessage) {
        [self.heading setText:dep.errorMessage];
        self.exception.hidden = YES;
        self.stale.hidden = YES;
        self.blockColor.image = nil;
        [self.mins setText:nil];
    } else {
        if (deps.count == 1)
        {
            [self.heading setAttributedText:[dep headingWithStatusFullSign:YES]];
        } else {
            [self.heading setAttributedText:[dep headingWithStatusFullSign:NO]];
        }
        [self.mins setText:dep.formattedMinsToArrival];
        [self.mins setTextColor:dep.fontColor];
        [self.lineColor setImage:dep.routeColorImage];
        
        self.blockColor.image = dep.blockImageColor;
        
        NSString *exception = dep.exception;
        
        if (exception) {
            self.exception.text = exception;
            self.exception.hidden = NO;
        } else {
            self.exception.hidden = YES;
        }
        
        self.stale.hidden = !dep.stale;
    }
}

- (WatchSelectAction)select:(XMLDepartures *)xml from:(WKInterfaceController *)from context:(WatchArrivalsContext *)context canPush:(bool)push; {
    if (push) {
        WatchArrivalsContext *detailContext = [context clone];
        
        if (detailContext == nil) {
            detailContext = [[WatchArrivalsContext alloc] init];
        }
        
        Departure *data = xml[self.index.integerValue];
        
        detailContext.detailBlock = data.block;
        detailContext.detailDir = data.dir;
        detailContext.stopId = context.stopId;
        detailContext.stopDesc = context.stopDesc;
        detailContext.navText = context.navText;
        detailContext.departures = xml;
        
        [detailContext pushFrom:from];
    }
    
    return WatchSelectAction_RefreshData;
}

@end
