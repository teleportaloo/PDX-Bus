//
//  DepartureTimesDataProvider.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetTypes.h"


@class Departure;
@class StopDistance;
@class CLLocation;
@class DepartureCell;
@class Detour;

@protocol DepartureTimesDataProvider <NSObject>

- (Departure *)depGetDeparture:(NSInteger)i;
- (void)depPopulateCell:(Departure *)dd cell:(DepartureCell *)cell decorate:(BOOL)decorate wide:(BOOL)wide;

@property (nonatomic, readonly)         NSInteger depGetSafeItemCount;
@property (nonatomic, readonly, copy)   NSString *depGetSectionHeader;
@property (nonatomic, readonly, copy)   NSString *depGetSectionTitle;
@property (nonatomic, readonly, copy)   NSString *depStaticText;
@property (nonatomic, readonly, copy)   NSString *depDir;
@property (nonatomic, readonly, strong) StopDistance *depDistance;
@property (nonatomic, readonly)         NSDate *depQueryTime;
@property (nonatomic, readonly, copy)   CLLocation *depLocation;
@property (nonatomic, readonly, copy)   NSString *depLocDesc;
@property (nonatomic, readonly, copy)   NSString *depStopId;
@property (nonatomic, readonly)         bool depHasDetails;
@property (nonatomic, readonly)         bool depNetworkError;
@property (nonatomic, readonly, copy)   NSString *depErrorMsg;
@property (nonatomic, readonly, copy)   NSData *depHtmlError;
@property (nonatomic, readonly)         Detour *depDetour;
@property (nonatomic, readonly)         NSOrderedSet<NSNumber*> *depDetoursPerSection;

@optional

@property (nonatomic, readonly, strong) id depXML;

@end
