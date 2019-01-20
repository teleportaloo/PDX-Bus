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



@class XMLDetours;
@class DepartureData;
@class XMLDepartures;
@class XMLLocateVehicles;
@class ShapeRoutePath;

@protocol DepartureDetailDelegate

- (void)detailsChanged;

@end

@interface DepartureDetailView : TableViewControllerWithRefresh <InfColorPickerControllerDelegate,ReturnStop>  {
    NSInteger                       _firstDetourRow;
}

@property (nonatomic, strong) DepartureData *departure;
@property (nonatomic, copy)   NSString *stops;
@property (nonatomic, strong) NSArray *allDepartures;
@property (nonatomic, weak) id<DepartureDetailDelegate> delegate;
@property (nonatomic, assign) bool allowBrowseForDestination;
@property (nonatomic) CLLocationDirection previousHeading;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, copy)   NSIndexPath *indexPathOfLocationCell;
@property (nonatomic, strong) NSMutableArray<ShapeRoutePath*> *shape;

- (void)fetchDepartureAsync:(id<BackgroundTaskController>)task dep:(DepartureData *)dep allDepartures:(NSArray*)deps backgroundRefresh:(bool)backgroundRefresh;
- (void)fetchDepartureAsync:(id<BackgroundTaskController>)task location:(NSString *)loc block:(NSString *)block backgroundRefresh:(bool)backgroundRefresh;
- (void)showMap:(id)sender;
- (void)colorPickerControllerDidFinish: (InfColorPickerController*) controller;
- (void)refreshAction:(id)unused;
- (void)updateSections;

@end
