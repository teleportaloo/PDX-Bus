//
//  AlarmCell.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/20/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "ScreenConstants.h"

@interface AlarmCell : UITableViewCell {
    bool _fired;
    UITableViewCellStateMask _state;
    CGFloat _originalTextWidth;
}

- (void)willTransitionToState:(UITableViewCellStateMask)state;
+ (AlarmCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier width:(ScreenWidth)width height:(CGFloat)height;
- (void)populateCellLine1:(NSString *)line1 line2:(NSString *)line2 line2col:(UIColor *)col;
+ (CGFloat)rowHeight:(ScreenWidth)width;
- (void)resetState;

@property (nonatomic) bool fired;

@end
