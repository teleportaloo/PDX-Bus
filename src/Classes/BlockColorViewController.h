//
//  BlockColorViewController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/26/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import "BlockColorDb.h"
#import "../InfColorPicker/InfColorPicker.h"

@interface BlockColorViewController : TableViewWithToolbar <InfColorPickerControllerDelegate> {
    NSArray *           _keys;
    BlockColorDb *      _db;
    NSString *          _changingColor;
    NSString *          _helpText;
}

- (void) colorPickerControllerDidFinish: (InfColorPickerController*) controller;


@end
