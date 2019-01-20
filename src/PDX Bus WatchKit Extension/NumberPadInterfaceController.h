//
//  NumberPadInterfaceController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 3/20/16.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface NumberPadInterfaceController : WKInterfaceController

@property (strong, nonatomic) IBOutlet WKInterfaceButton *buttonStopId;
@property (nonatomic, strong) NSMutableString *stopId;
- (IBAction)button1;
- (IBAction)button2;
- (IBAction)button3;
- (IBAction)button4;
- (IBAction)button5;
- (IBAction)button6;
- (IBAction)button7;
- (IBAction)button8;
- (IBAction)button9;
- (IBAction)button0;
- (IBAction)buttonBack;
- (IBAction)buttonGo;
- (IBAction)menuClear;
- (IBAction)sayStopId;

@end
