//
//  DatePickerCell.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/14/19.
//  Copyright © 2019 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DatePickerCell : UITableViewCell
@property(strong, nonatomic) IBOutlet UIDatePicker *datePickerView;

+ (UINib *)nib;

@end

NS_ASSUME_NONNULL_END
