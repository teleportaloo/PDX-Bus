//
//  AlarmViewMinutes.h
//  PDX Bus
//
//  Created by Andrew Wallace on 1/30/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TableViewControllerWithToolbar.h"
#import "XMLDepartures.h"
#import <Foundation/Foundation.h>

@interface AlarmViewMinutes
    : TableViewControllerWithToolbar <UIPickerViewDelegate,
                                      UIPickerViewDataSource>

@property(nonatomic, strong) Departure *dep;

@end
