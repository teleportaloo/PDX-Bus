//
//  Stop.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "MapPinColor.h"
#import "SearchFilter.h"
#import "DataFactory.h"


@protocol ReturnStop;
@protocol BackgroundTaskProgress;



@interface Stop : DataFactory <MapPinColor, SearchFilter> {
	NSString *      _locid;
	bool			_tp;
	NSString *      _desc;
	NSString *      _lat;
	NSString *      _lng;
	id<ReturnStop>  _callback;
	NSString *      _dir;
	int			    _index;
}

@property (nonatomic, copy)   NSString *locid;
@property (nonatomic, copy)   NSString *desc;
@property (nonatomic, copy)   NSString *dir;
@property (nonatomic)         bool tp;
@property (nonatomic, copy)   NSString *lat;
@property (nonatomic, copy)   NSString *lng;
@property (nonatomic, retain) id<ReturnStop> callback;
@property (nonatomic)         int index;

@property (nonatomic)           MKPinAnnotationColor pinColor;
@property (nonatomic, readonly) bool showActionMenu;
- (bool) mapTapped:(id<BackgroundTaskProgress>) progress;
@property (nonatomic, readonly, copy) NSString *stringToFilter;

@end

@protocol ReturnStop
- (void) chosenStop:(Stop *)stop progress:(id<BackgroundTaskProgress>) progress;
@property (nonatomic, readonly, copy) NSString *actionText;
@end

