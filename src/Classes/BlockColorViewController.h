//
//  BlockColorViewController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/26/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//

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
