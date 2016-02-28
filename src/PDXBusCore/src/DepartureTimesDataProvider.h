


/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetTypes.h"

@class DepartureData;
@class DepartureUI;
@class StopDistanceData;
@class CLLocation;

@protocol DepartureTimesDataProvider <NSObject>

- (DepartureData *)DTDataGetDeparture:(NSInteger)i;
- (NSInteger)DTDataGetSafeItemCount;
- (NSString *)DTDataGetSectionHeader;
- (NSString *)DTDataGetSectionTitle;
- (void)DTDataPopulateCell:(DepartureUI *)dd cell:(UITableViewCell *)cell decorate:(BOOL)decorate wide:(BOOL)wide;
- (NSString *)DTDataStaticText;
- (NSString *)DTDataDir;
- (StopDistanceData*)DTDataDistance;
- (TriMetTime) DTDataQueryTime;
- (CLLocation *)DTDataLoc;
- (NSString *)DTDataLocDesc;
- (NSString *)DTDataLocID;
- (BOOL) DTDataHasDetails;
- (BOOL) DTDataNetworkError;
- (NSString *)DTDataNetworkErrorMsg;
- (NSData *)DTDataHtmlError;

@optional

- (id)DTDataXML;

@end
