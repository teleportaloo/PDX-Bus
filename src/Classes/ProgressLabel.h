//
//  ProgressLabel.h
//  iOS Core Lib
//
//  Created by Andy Wallace on 9/29/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//
// ProgressLabel.h
#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface ProgressLabel : UILabel

/// Progress (0.0 … 1.0)
@property (nonatomic) IBInspectable CGFloat progress;

/// Fill color behind text
@property (nonatomic, strong) IBInspectable UIColor *fillColor;

/// Padding for fill bar (vertical only, horizontal will match border)
@property (nonatomic) IBInspectable CGFloat verticalPadding;

/// Border width and color
@property (nonatomic) IBInspectable CGFloat borderWidth;
@property (nonatomic, strong) IBInspectable UIColor *borderColor;

@end
