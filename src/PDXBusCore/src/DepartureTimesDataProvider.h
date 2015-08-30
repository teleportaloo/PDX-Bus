


/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetTypes.h"
#import "MapPinColor.h"

@class DepartureData;
@class DepartureUI;
@class StopDistance;

@protocol DepartureTimesDataProvider <NSObject>

- (DepartureData *)DTDataGetDeparture:(NSInteger)i;
- (NSInteger)DTDataGetSafeItemCount;
- (NSString *)DTDataGetSectionHeader;
- (NSString *)DTDataGetSectionTitle;
- (void)DTDataPopulateCell:(DepartureUI *)dd cell:(UITableViewCell *)cell decorate:(BOOL)decorate big:(BOOL)big wide:(BOOL)wide;
- (NSString *)DTDataStaticText;
- (NSString *)DTDataDir;
- (StopDistance*)DTDataDistance;
- (TriMetTime) DTDataQueryTime;
- (NSString *)DTDataLocLat;
- (NSString *)DTDataLocLng;
- (NSString *)DTDataLocDesc;
- (NSString *)DTDataLocID;
- (id<MapPinColor>)DTDatagetPin;
- (BOOL) DTDataHasDetails;
- (BOOL) DTDataNetworkError;
- (NSString *)DTDataNetworkErrorMsg;
- (NSData *)DTDataHtmlError;

@optional

- (id)DTDataXML;

@end
