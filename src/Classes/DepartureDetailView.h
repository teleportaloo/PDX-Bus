//
//  ArrivalDetail.h
//  TriMetTimes
//

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

#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
@class XMLDetour;
@class Departure;


@interface DepartureDetailView : TableViewWithToolbar <UIActionSheetDelegate>  {
	int detourSection;
	int locationSection;
	int webSection;
	int tripSection;
	int disclaimerSection;
	int destinationSection;
	int alertSection;
	int sections;
	Departure *_departure;
	NSArray *_allDepartures;
	XMLDetour *_detourData;
	NSString *_stops;
}

@property (nonatomic, retain) Departure *departure;
@property (nonatomic, retain) XMLDetour *detourData;
@property (nonatomic, retain) NSString *stops;
@property (nonatomic, retain) NSArray *allDepartures;

- (void)fetchDepartureInBackground:(id<BackgroundTaskProgress>) callback dep:(Departure *)dep allDepartures:(NSArray*)deps allowDestination:(BOOL)allowDest;
// - (void)fetchDetourForRouteInBackground:(id<BackgroundTaskProgress> callback route:(NSString*) route;
- (void)showMap:(id)sender;


@end
