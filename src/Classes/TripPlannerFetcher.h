//
//  TripPlannerFetcher.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/4/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BackgroundTaskContainer.h"
#import "XMLTrips.h"
#import <UIKit/UIKit.h>

@interface TripPlannerFetcher : NSObject

@property(nonatomic, strong) XMLTrips *tripQuery;
@property(nonatomic, strong) TripEndPoint *currentEndPoint;

- (void)nextScreen:(UINavigationController *)controller
      forceResults:(bool)forceResults
         postQuery:(bool)postQuery
     taskContainer:(BackgroundTaskContainer *)taskContainer;

@end
