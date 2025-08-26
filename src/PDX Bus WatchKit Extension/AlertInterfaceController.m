//
//  AlertInterfaceController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/7/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AlertInterfaceController.h"

@implementation AlertInterfaceController

- (IBAction)okButtonTapped {
    [self popController];
}

- (IBAction)menuItemHome {
    [self popToRootController];
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    self.alertLabel.attributedText = (NSAttributedString *)context;
}

@end
