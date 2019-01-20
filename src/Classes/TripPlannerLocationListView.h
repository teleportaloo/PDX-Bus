//
//  TripPlannerLocationListView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/29/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "XMLTrips.h"
#import "TableViewWithToolbar.h"

@interface TripPlannerLocationListView : TableViewWithToolbar <ReturnTripLegEndPoint> 

@property (nonatomic, strong) XMLTrips *tripQuery;
@property (nonatomic) bool from;
@property (nonatomic, strong) NSMutableArray *locList;

- (void)chosenEndpoint:(TripLegEndPoint*)endpoint;

@end
