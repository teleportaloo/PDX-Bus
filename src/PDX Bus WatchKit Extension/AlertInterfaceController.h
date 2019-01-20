//
//  AlertInterfaceController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/7/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <WatchKit/WatchKit.h>

#define  kAlertScene @"Alert"

@interface AlertInterfaceController : WKInterfaceController
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *alertLabel;
- (IBAction)okButtonTapped;
- (IBAction)menuItemHome;

@end
