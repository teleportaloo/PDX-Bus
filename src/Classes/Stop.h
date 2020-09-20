//
//  Stop.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "MapPinColor.h"
#import "SearchFilter.h"
#import "DataFactory.h"


@protocol ReturnStop;
@protocol TaskController;

@interface Stop : DataFactory <MapPinColor, SearchFilter>

@property (nonatomic, copy)   NSString *stopId;
@property (nonatomic, copy)   NSString *desc;
@property (nonatomic, copy)   NSString *dir;
@property (nonatomic)         bool tp;
@property (nonatomic, copy)   NSString *lat;
@property (nonatomic, copy)   NSString *lng;
@property (nonatomic, strong) id<ReturnStop> callback;
@property (nonatomic)         int index;
@property (nonatomic)         MapPinColorValue pinColor;
@property (nonatomic, readonly) bool showActionMenu;
@property (nonatomic, readonly, copy) NSString *stringToFilter;

- (bool)mapTapped:(id<TaskController>)progress;

@end

@protocol ReturnStop

@property (nonatomic, readonly, copy) NSString *actionText;

- (void)chosenStop:(Stop *)stop progress:(id<TaskController>)progress;

@end
