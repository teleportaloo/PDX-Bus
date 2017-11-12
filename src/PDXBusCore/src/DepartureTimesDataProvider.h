


/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetTypes.h"


@class DepartureData;
@class StopDistanceData;
@class CLLocation;
@class DepartureCell;

@protocol DepartureTimesDataProvider <NSObject>

- (DepartureData *)DTDataGetDeparture:(NSInteger)i;
- (void)DTDataPopulateCell:(DepartureData *)dd cell:(DepartureCell *)cell decorate:(BOOL)decorate wide:(BOOL)wide;

@property (nonatomic, readonly) NSInteger DTDataGetSafeItemCount;
@property (nonatomic, readonly, copy) NSString *DTDataGetSectionHeader;
@property (nonatomic, readonly, copy) NSString *DTDataGetSectionTitle;
@property (nonatomic, readonly, copy) NSString *DTDataStaticText;
@property (nonatomic, readonly, copy) NSString *DTDataDir;
@property (nonatomic, readonly, strong) StopDistanceData *DTDataDistance;
@property (nonatomic, readonly) TriMetTime DTDataQueryTime;
@property (nonatomic, readonly, copy) CLLocation *DTDataLoc;
@property (nonatomic, readonly, copy) NSString *DTDataLocDesc;
@property (nonatomic, readonly, copy) NSString *DTDataLocID;
@property (nonatomic, readonly) BOOL DTDataHasDetails;
@property (nonatomic, readonly) BOOL DTDataNetworkError;
@property (nonatomic, readonly, copy) NSString *DTDataNetworkErrorMsg;
@property (nonatomic, readonly, copy) NSData *DTDataHtmlError;

@optional

@property (nonatomic, readonly, strong) id DTDataXML;

@end

