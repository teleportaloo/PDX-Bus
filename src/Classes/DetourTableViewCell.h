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
#import "SelectableTextViewCell.h"


#define DETOUR_ACCESSORY_BUTTON_SIZE     35
#define DETOUR_BUTTON_COLLAPSE    1
#define DETOUR_BUTTON_MAP         2

@class DetourTableViewCell;

typedef void (^ButtonAction) (DetourTableViewCell *cell,  NSInteger tag);
typedef bool (^DetourUrlAction) (DetourTableViewCell *cell,  NSString *url);

NS_ASSUME_NONNULL_BEGIN

@interface DetourTableViewCell : SelectableTextViewCell <UITextViewDelegate, UIGestureRecognizerDelegate>
@property (strong, nonatomic) IBOutlet LinkResponsiveTextView *textView;
@property (nonatomic, copy) ButtonAction buttonCallback;
@property (nonatomic, copy) DetourUrlAction urlCallback;

@property (nonatomic, strong) Detour *detour;
@property (nonatomic) bool includeHeaderInDescription;

- (void)populateCell:(Detour *)detour route:(NSString * _Nullable)route;

+ (UINib *)nib;


@end

NS_ASSUME_NONNULL_END
