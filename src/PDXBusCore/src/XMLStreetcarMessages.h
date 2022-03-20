//
//  XMLStreetcarMessages.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/29/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "NextBusXML.h"
#import "Detour.h"
#import "XMLDepartures.h"

@interface XMLStreetcarMessages : NextBusXML<Detour*>

@property (nonatomic, strong) AllTriMetRoutes* allRoutes;
@property (nonatomic, strong) NSMutableArray<Route *> *allStreetcarRoutes;
@property (nonatomic, strong) Route * currentRoute;
@property (nonatomic, strong) Detour *curentDetour;
@property (nonatomic, copy) NSString * copyright;
@property (nonatomic, strong) NSDate * queryTime;
@property (nonatomic) bool currentAllRoutes;

- (void)insertDetoursIntoDepartureArray:(XMLDepartures *)departures;
- (void)alwaysGetMessages;
- (bool)needToGetMessages;
- (void)getMessages;

+ (XMLStreetcarMessages*)sharedInstance;

@end
