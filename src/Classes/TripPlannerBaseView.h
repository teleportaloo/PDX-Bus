//
//  TripPlannerBaseView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/12/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TripReturnUserRequest.h"
#import "TableViewWithToolbar.h"

@interface TripPlannerBaseView : TableViewWithToolbar {
	XMLTrips *_tripQuery;
}

@property (nonatomic, retain) XMLTrips *tripQuery;


@end
