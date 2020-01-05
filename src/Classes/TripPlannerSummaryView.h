//
//  TripPlannerSummaryView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/30/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TableViewWithToolbar.h"
#import "XMLTrips.h"
#import "TripPlannerBaseView.h"
#import "TripItemCell.h"


@interface TripPlannerSummaryView : TripPlannerBaseView
{
    NSUInteger _pickerRow;
    NSUInteger _pickerSection;
}

@property (nonatomic, strong) UIDatePicker *datePickerView;

-(void)initQuery;
-(void)makeSummaryRows;

@end
