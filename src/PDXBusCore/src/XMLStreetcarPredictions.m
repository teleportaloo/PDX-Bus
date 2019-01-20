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

@implementation XMLStreetcarPredictions


#pragma mark Initiate Parsing

- (BOOL)getDeparturesForLocation:(NSString *)location;

{
    [self startParsing:location cacheAction:TriMetXMLUseShortTermCache];
    return true;
}

- (bool)cacheSelectors
{
    return YES;
}

#pragma mark Parser Callbacks

XML_START_ELEMENT(body)
{
   self.copyright = ATRSTR(copyright);
}

XML_START_ELEMENT(predictions)
{
    self.currentRouteTitle = ATRSTR(routeTitle);
    
    self.currentDirectionTitle = [attributeDict objectForCaseInsensitiveKey:@"dirTitleBecauseNoPredictions"];
#ifdef DEBUGLOGGING
    self.stopTitle = attributeDict[@"stopTitle"];
#endif
    
    if (self.currentDirectionTitle!=nil && self.items==nil)
    {
        [self initItems];
        _hasData = YES;
    }
}

XML_START_ELEMENT(direction)
{
    self.currentDirectionTitle = ATRSTR(title);
    
    if (!_hasData)
    {
        [self initItems];
        _hasData = YES;
    }
}

XML_START_ELEMENT(prediction)
{
    // Note - the vehicle is the block - I put the block into the streetcar block!
    NSString *block = ATRSTR(block);
    if ((self.blockFilter==nil) || ([self.blockFilter isEqualToString:block]))
    {
        NSString *name = [NSString stringWithFormat:@"%@ %@", self.currentRouteTitle, self.currentDirectionTitle];
        
        // There are some bugs in the streetcar feed (e.g. Cl instead of CL)
        
        self.currentDepartureObject = [DepartureData data];
        self.currentDepartureObject.hasBlock       = true;
        self.currentDepartureObject.route          = nil;
        self.currentDepartureObject.fullSign       = name;
        self.currentDepartureObject.shortSign      = name;
        self.currentDepartureObject.block          = block;
        self.currentDepartureObject.status         = kStatusEstimated;
        self.currentDepartureObject.nextBusMins    = ATRINT(minutes);
        self.currentDepartureObject.streetcar      = true;
        self.currentDepartureObject.dir            = nil;
        self.currentDepartureObject.copyright      = self.copyright;
        self.currentDepartureObject.streetcarId    = ATRSTR(vehicle);
        
        /*
         [ATRSTR(dirTag"] isEqualToString:@"t5"]
         ? @"1" : @"0";
         */
        
        /*
         self.currentDepartureObject.locationDesc =    self.locDesc;
         self.currentDepartureObject.locid         =  self.locid;
         self.currentDepartureObject.locationDir  =  self.locDir;
         */
        
        [self addItem:self.currentDepartureObject];
    }
    else
    {
        self.currentDepartureObject=nil;
    }
}

@end
