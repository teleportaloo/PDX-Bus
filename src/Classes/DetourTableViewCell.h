//
//  DetourTableViewCell.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/5/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "Detour.h"
#import "LinkResponsiveTextView.h"


#define DETOUR_ACCESSORY_BUTTON_SIZE     35
#define DETOUR_BUTTON_COLLAPSE    1
#define DETOUR_BUTTON_MAP         2

@class DetourTableViewCell;

typedef void (^buttonAction) (DetourTableViewCell *cell,  NSInteger tag);
typedef bool (^detourUrlAction) (DetourTableViewCell *cell,  NSString *url);

NS_ASSUME_NONNULL_BEGIN

@interface DetourTableViewCell : UITableViewCell <UITextViewDelegate, UIGestureRecognizerDelegate>
@property (strong, nonatomic) IBOutlet LinkResponsiveTextView *textView;
@property (nonatomic, copy) buttonAction buttonCallback;
@property (nonatomic, copy) detourUrlAction urlCallback;

@property (nonatomic, retain) Detour *detour;
@property (nonatomic) bool includeHeaderInDescription;

- (void)populateCell:(Detour *)detour font:(UIFont *)font route:(NSString * _Nullable)route;

+ (UINib *)nib;


@end

NS_ASSUME_NONNULL_END
