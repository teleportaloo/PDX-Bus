//
//  LocationServicesDebugViewController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 1/31/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AlarmTask.h"
#import "TableViewControllerWithToolbar.h"
#import <Foundation/Foundation.h>

#ifdef DEBUG_ALARMS

@interface LocationServicesDebugViewController : TableViewWithToolbar

@property(nonatomic, strong) AlarmTask *data;

@end

#endif
