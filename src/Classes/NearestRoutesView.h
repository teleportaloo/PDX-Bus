//
//  NearestRoutesView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 1/9/11.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import "XMLLocateStops+iOSUI.h"

@interface NearestRoutesView : TableViewWithToolbar {
	XMLLocateStops *            _routeData;
	NSMutableArray<NSNumber*> * _checked;
}

@property (nonatomic, retain) XMLLocateStops *routeData;
@property (nonatomic, retain) NSMutableArray<NSNumber*> *checked;

- (void)showArrivalsAction:(id)sender;
- (void)fetchNearestRoutesAsync:(id<BackgroundTaskProgress>)background location:(CLLocation *)here maxToFind:(int)max minDistance:(double)min mode:(TripMode)mode;



@end
