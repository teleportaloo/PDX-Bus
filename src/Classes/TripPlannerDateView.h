//
//  TripPlannerDateView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/2/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "CustomToolbar.h"
#import "ReturnStopId.h"
#import "TableViewWithToolbar.h"
#import "XMLTrips.h"
#import "TripPlannerBaseView.h"


@interface TripPlannerDateView : TripPlannerBaseView  {
	UIDatePicker *_datePickerView;
	UIPickerView *_pickerView;
	NSArray *_userFaves;
	bool _popBack;
	
}

@property (nonatomic, retain) NSArray *userFaves;
@property (nonatomic, retain) UIDatePicker *datePickerView;
@property (nonatomic, retain) UIPickerView *pickerView;
@property (nonatomic)		  bool popBack;

- (CGRect)pickerFrameWithSize:(CGSize)size;
- (void)initializeFromBookmark:(TripUserRequest *)req;

-(void)nextScreen:(UINavigationController *)controller taskContainer:(BackgroundTaskContainer*)taskContainer;


@end
