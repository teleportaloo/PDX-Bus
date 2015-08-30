//
//  ArrivalDetail.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import "../InfColorPicker/InfColorPicker.h"
#import "Stop.h"

@class XMLDetour;
@class DepartureData;

@protocol DepartureDetailDelegate

- (void)detailsChanged;

@end

@interface DepartureDetailView : TableViewWithToolbar <UIActionSheetDelegate, InfColorPickerControllerDelegate,ReturnStop>  {
	int detourSection;
	int locationSection;
	int webSection;
	int tripSection;
	int disclaimerSection;
	int destinationSection;
	int alertSection;
    int highlightSection;
	int sections;
	DepartureData *_departure;
	NSArray *_allDepartures;
	XMLDetour *_detourData;
	NSString *_stops;
    id<DepartureDetailDelegate> _delegate;
}

@property (nonatomic, retain) DepartureData *departure;
@property (nonatomic, retain) XMLDetour *detourData;
@property (nonatomic, retain) NSString *stops;
@property (nonatomic, retain) NSArray *allDepartures;
@property (nonatomic, assign) id<DepartureDetailDelegate> delegate;

- (void)fetchDepartureInBackground:(id<BackgroundTaskProgress>) callback dep:(DepartureData *)dep allDepartures:(NSArray*)deps allowDestination:(BOOL)allowDest;
// - (void)fetchDetourForRouteInBackground:(id<BackgroundTaskProgress> callback route:(NSString*) route;
- (void)showMap:(id)sender;

- (void) colorPickerControllerDidFinish: (InfColorPickerController*) controller;


@end
