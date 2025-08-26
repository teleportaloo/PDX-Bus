//
//  AlarmCell.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/20/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AlarmCell.h"
#import "DebugLogging.h"
#import "UIColor+MoreDarkMode.h"
#import "ViewControllerBase.h"
#import "UIApplication+Compat.h"

// #define ALARM_NAME_TAG    1
/// #define ALARM_TOGO_TAG    2

@interface AlarmCell () {
    bool _fired;
    UITableViewCellStateMask _state;
}

@end

@implementation AlarmCell

@dynamic fired;

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:reuseIdentifier];

    if (self) {
        // Initialization code.
        self.fired = false;
        _state = 0;
    }

    return self;
}

- (bool)fired {
    return _fired;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state.
}

- (void)setFired:(_Bool)fired {
    _fired = fired;
}

- (void)setUpViews {
    self.detailTextLabel.font = self.textLabel.font;
}

+ (AlarmCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier {
    AlarmCell *cell =
        [[AlarmCell alloc] initWithStyle:UITableViewCellStyleDefault
                         reuseIdentifier:identifier];

    [cell setUpViews];

    return cell;
}

- (void)populateCellLine1:(NSString *)line1
                    line2:(NSString *)line2
                 line2col:(UIColor *)col {
    self.textLabel.text = line1;
    self.textLabel.adjustsFontSizeToFitWidth = YES;
    self.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;

    self.detailTextLabel.text = line2;
    self.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    self.detailTextLabel.textColor = col;

    if (_fired) {
        self.textLabel.textColor = [UIColor blackColor];
    } else {
        self.textLabel.textColor = [UIColor modeAwareText];
    }
}

+ (CGFloat)rowHeight {
    if (SMALL_SCREEN) {
        return 45.0 * 1.4;
    }

    return 55.0 * 1.4;
}

- (void)layoutSubviews {
    [self setUpViews];
    [super layoutSubviews];
}

@end
