//
//  PickerCell.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/17/19.
//  Copyright © 2019 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "PickerCell.h"

@interface PickerCell ()

@end

@implementation PickerCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

+ (UINib *)nib {
    return [UINib nibWithNibName:@"PickerCell" bundle:nil];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
