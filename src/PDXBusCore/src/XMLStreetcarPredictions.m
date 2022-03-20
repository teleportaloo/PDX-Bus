//
//  XMLStreetcarPredictions.m
//  PDX Bus
//
//  Created by Andrew Wallace on 3/22/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLStreetcarPredictions.h"
#import "NSDictionary+Types.h"
#import "TriMetXMLSelectors.h"

@interface XMLStreetcarPredictions ()

@property (nonatomic, strong) Departure *currentDepartureObject;
@property (nonatomic, copy)   NSString *currentDirectionTitle;
@property (nonatomic, copy)   NSString *currentRouteTitle;

@end

@implementation XMLStreetcarPredictions


#pragma mark Initiate Parsing

- (BOOL)getDeparturesForStopId:(NSString *)stopId {
    NSString *location = [NSString stringWithFormat:@"predictions&a=portland-sc&stopId=%@", stopId];
    [self startParsing:location cacheAction:TriMetXMLUseShortTermCache];
    return true;
}

- (bool)cacheSelectors {
    return YES;
}

#pragma mark Parser Callbacks

XML_START_ELEMENT(body) {
    self.copyright = XML_NON_NULL_ATR_STR(@"copyright");
}

XML_START_ELEMENT(predictions) {
    self.currentRouteTitle = XML_NON_NULL_ATR_STR(@"routeTitle");
    
    self.currentDirectionTitle = XML_ZERO_LEN_ATR_STR(@"dirTitleBecauseNoPredictions");
    self.stopTitle = XML_ZERO_LEN_ATR_STR(@"stopTitle");
    
    if (self.currentDirectionTitle != nil && self.items == nil) {
        [self initItems];
        _hasData = YES;
    }
}

XML_START_ELEMENT(direction) {
    self.currentDirectionTitle = XML_NON_NULL_ATR_STR(@"title");
    
    if (!_hasData) {
        [self initItems];
        _hasData = YES;
    }
}

XML_START_ELEMENT(prediction) {
    // Note - the vehicle is the block - I put the block into the streetcar block!
    NSString *block = XML_NON_NULL_ATR_STR(@"block");
    
    if ((self.blockFilter == nil) || ([self.blockFilter isEqualToString:block])) {
        NSString *name = [NSString stringWithFormat:@"%@ %@", self.currentRouteTitle, self.currentDirectionTitle];
        
        // There are some bugs in the streetcar feed (e.g. Cl instead of CL)
        
        self.currentDepartureObject = [Departure new];
        self.currentDepartureObject.hasBlock = true;
        self.currentDepartureObject.route = nil;
        self.currentDepartureObject.fullSign = name;
        self.currentDepartureObject.shortSign = name;
        self.currentDepartureObject.block = block;
        self.currentDepartureObject.status = ArrivalStatusEstimated;
        self.currentDepartureObject.nextBusMins = XML_ATR_INT(@"minutes");
        self.currentDepartureObject.streetcar = true;
        self.currentDepartureObject.dir = nil;
        self.currentDepartureObject.copyright = self.copyright;
        self.currentDepartureObject.streetcarId = XML_NON_NULL_ATR_STR(@"vehicle");
                
        [self addItem:self.currentDepartureObject];
    } else {
        self.currentDepartureObject = nil;
    }
}

@end
