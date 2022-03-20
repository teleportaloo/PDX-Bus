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

@property (nonatomic, strong) NSMutableString *stopId;

@property (strong, nonatomic) IBOutlet WKInterfaceButton *buttonStopId;

- (IBAction)buttonAction1;
- (IBAction)buttonAction2;
- (IBAction)buttonAction3;
- (IBAction)buttonAction4;
- (IBAction)buttonAction5;
- (IBAction)buttonAction6;
- (IBAction)buttonAction7;
- (IBAction)buttonAction8;
- (IBAction)buttonAction9;
- (IBAction)buttonAction0;
- (IBAction)buttonBackAction;
- (IBAction)buttonGoAction;
- (IBAction)menuClearAction;
- (IBAction)sayStopIdAction;

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *goButton;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *backButton;

@end
