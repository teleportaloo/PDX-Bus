//
//  TripPlannerDateView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/2/09.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

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
