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

@synthesize currentDepartureObject = _currentDepartureObject;
@synthesize directionTitle = _directionTitle;
@synthesize routeTitle = _routeTitle;
@synthesize blockFilter = _blockFilter;
@synthesize copyright = _copyright;
@synthesize nextBusRouteId = _nextBusRouteId;

- (void)dealloc
{
	self.currentDepartureObject = nil;
	self.directionTitle = nil;
	self.routeTitle = nil;
	self.blockFilter = nil;
	self.copyright = nil;
    self.nextBusRouteId = nil;
    self.stopTitle = nil;
	
	[super dealloc];
}

#pragma mark Initiate Parsing

- (BOOL)getDeparturesForLocation:(NSString *)location;

{	
   
	[self startParsing:location cacheAction:TriMetXMLUseShortTermCache];
	return true;
}

#pragma mark Parser Callbacks

START_ELEMENT(body)
{
   self.copyright = ATRVAL(copyright);
}

START_ELEMENT(predictions)
{
    self.routeTitle = ATRVAL(routeTitle);
    
    self.directionTitle = [attributeDict objectForCaseInsensitiveKey:@"dirTitleBecauseNoPredictions"];
#ifdef DEBUGLOGGING
    self.stopTitle = attributeDict[@"stopTitle"];
#endif
    
    if (self.directionTitle!=nil)
    {
        [self initArray];
        _hasData = YES;
    }
}

START_ELEMENT(direction)
{
    self.directionTitle = ATRVAL(title);
    
    if (!_hasData)
    {
        [self initArray];
        _hasData = YES;
    }
}

START_ELEMENT(prediction)
{
    // Note - the vehicle is the block - I put the block into the streetcar block!
    NSString *block = ATRVAL(block);
    if ((self.blockFilter==nil) || ([self.blockFilter isEqualToString:block]))
    {
        NSString *name = [NSString stringWithFormat:@"%@ %@", self.routeTitle, self.directionTitle];
        
        // There are some bugs in the streetcar feed (e.g. Cl instead of CL)
        
        self.currentDepartureObject = [DepartureData data];
        self.currentDepartureObject.hasBlock       = true;
        self.currentDepartureObject.route          = nil;
        self.currentDepartureObject.fullSign       = name;
        self.currentDepartureObject.routeName      = name;
        self.currentDepartureObject.block          = block;
        self.currentDepartureObject.status         = kStatusEstimated;
        self.currentDepartureObject.nextBus        = ATRTIM(minutes);
        self.currentDepartureObject.streetcar      = true;
        self.currentDepartureObject.dir            = nil;
        self.currentDepartureObject.copyright      = self.copyright;
        self.currentDepartureObject.streetcarId    = ATRVAL(vehicle);
        
        /*
         [ATRVAL(dirTag"] isEqualToString:@"t5"]
         ? @"1" : @"0";
         */
        
        /*
         self.currentDepartureObject.locationDesc =	self.locDesc;
         self.currentDepartureObject.locid		 =  self.locid;
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
