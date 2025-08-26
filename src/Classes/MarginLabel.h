//
//  MarginLabel.h
//  PDX Bus
//
//  Created by Andy Wallace on 9/11/22.
//  Copyright © 2022 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MarginLabel : UILabel

@property(nonatomic) CGFloat topInset;
@property(nonatomic) CGFloat bottomInset;
@property(nonatomic) CGFloat leftInset;
@property(nonatomic) CGFloat rightInset;

@end

NS_ASSUME_NONNULL_END
