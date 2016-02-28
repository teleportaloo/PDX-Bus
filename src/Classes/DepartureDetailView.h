//
//  ArrivalDetail.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewControllerWithRefresh.h"
#import "../InfColorPicker/InfColorPicker.h"
#import "Stop.h"



@class XMLDetour;
@class DepartureData;

@protocol DepartureDetailDelegate

- (void)detailsChanged;

@end

@interface DepartureDetailView : TableViewControllerWithRefresh <UIActionSheetDelegate, InfColorPickerControllerDelegate,ReturnStop, MKMapViewDelegate>  {

    NSInteger firstDetourRow;
	DepartureData *_departure;
	NSArray *_allDepartures;
	XMLDetour *_detourData;
	NSString *_stops;
    id<DepartureDetailDelegate> _delegate;
    bool _allowBrowseForDestination;
    CLLocationDirection _previousHeading;
    CADisplayLink *_displayLink;
}

@property (nonatomic, retain) DepartureData *departure;
@property (nonatomic, retain) XMLDetour *detourData;
@property (nonatomic, retain) NSString *stops;
@property (nonatomic, retain) NSArray *allDepartures;
@property (nonatomic, assign) id<DepartureDetailDelegate> delegate;
@property (nonatomic, assign) bool allowBrowseForDestination;
@property (nonatomic) CLLocationDirection previousHeading;
@property (nonatomic, strong) CADisplayLink *displayLink;


- (void)fetchDepartureInBackground:(id<BackgroundTaskProgress>) callback dep:(DepartureData *)dep allDepartures:(NSArray*)deps;
- (void)fetchDepartureInBackground:(id<BackgroundTaskProgress>) callback location:(NSString *)loc block:(NSString *)block;
- (void)showMap:(id)sender;

- (void) colorPickerControllerDidFinish: (InfColorPickerController*) controller;

- (void)refreshAction:(id)arg;

- (void)updateSections;
@end
