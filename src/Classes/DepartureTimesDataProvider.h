
/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import "TriMetTypes.h"
#import "MapPinColor.h"

@class Departure;
@class StopDistance;

@protocol DepartureTimesDataProvider <NSObject>

- (Departure *)DTDataGetDeparture:(int)i;
- (int)DTDataGetSafeItemCount;
- (NSString *)DTDataGetSectionHeader;
- (NSString *)DTDataGetSectionTitle;
- (void)DTDataPopulateCell:(Departure *)dd cell:(UITableViewCell *)cell decorate:(BOOL)decorate big:(BOOL)big wide:(BOOL)wide;
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
