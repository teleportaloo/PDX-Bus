//
//  TripPlannerLocatingView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/4/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "LocatingView.h"
#import "XMLTrips.h"


@interface TripPlannerLocatingView : LocatingView <LocatingViewDelegate> {
	XMLTrips *                  _tripQuery;
	TripEndPoint  *             _currentEndPoint;
	UINavigationController *    _backgroundTaskController;
	bool                        _backgroundTaskForceResults;
	UIInterfaceOrientation      _cachedOrientation;
	bool                        _useCachedOrientation;
    bool                        _appeared;
    bool                        _waitingForGeocoder;
}

@property (nonatomic, retain) XMLTrips *tripQuery;
@property (nonatomic, retain) TripEndPoint  *currentEndPoint;
@property (nonatomic, retain) UINavigationController *backgroundTaskController;
@property (nonatomic) bool backgroundTaskForceResults;
@property (atomic) bool waitingForGeocoder;

-(void)nextScreen:(UINavigationController *)controller forceResults:(bool)forceResults postQuery:(bool)postQuery 
	  orientation:(UIInterfaceOrientation)orientation
	taskContainer:(BackgroundTaskContainer *)taskContainer;
-(void)fetchAndDisplay:(UINavigationController *)controller forceResults:(bool)forceResults
		 taskContainer:(BackgroundTaskContainer *)taskContainer;


@end
