//
//  TripPlannerDateViewController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/2/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripPlannerBaseViewController.h"
#import <UIKit/UIKit.h>

@interface TripPlannerDateViewController : TripPlannerBaseViewController

@property(nonatomic, strong) NSArray<NSMutableDictionary *> *userFaves;
@property(nonatomic) bool popBack;

- (void)initializeFromBookmark:(TripUserRequest *)req;
- (void)nextScreen:(UINavigationController *)controller
     taskContainer:(BackgroundTaskContainer *)taskContainer;

@end
