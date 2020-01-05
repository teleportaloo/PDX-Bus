//
//  DatePickerCell.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/14/19.
//  Copyright © 2019 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DatePickerCell.h"

@implementation DatePickerCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (UINib*)nib
{
    return [UINib nibWithNibName:@"DatePickerCell" bundle:nil];
}

@end
