//
//  DetourTableViewCell.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/5/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DetourTableViewCell.h"
#import "Detour+iOSUI.h"
#include "Icons.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "Settings.h"
#include "ViewControllerBase.h"

@implementation DetourTableViewCell

+ (UINib *)nib {
    return [UINib nibWithNibName:@"DetourTableViewCell" bundle:nil];
}

- (void)awakeFromNib {
    [super awakeFromNib];

    self.textView.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)detourButtonAction:(UIButton *)button {
    if (self.buttonCallback) {
        self.buttonCallback(self, button.tag);
    }
}

- (void)addDetourButtons:(Detour *)detour
         routeDisclosure:(bool)routeDisclosure {
    UIButton *button = nil;
    NSMutableArray *buttons = [NSMutableArray array];

    bool hidden = detour.systemWide &&
                  [Settings isHiddenSystemWideDetour:detour.detourId];
    CGFloat next = 0;

#define AB_GAP 10
#define SMALL_BUTTON_SIDE 10
#define NEXT_RECT(F, SZ)                                                       \
    F = CGRectMake(next, (DETOUR_ACCESSORY_BUTTON_SIZE - SZ) / 2, SZ, SZ);     \
    next += SZ
#define NEXT_GAP next += AB_GAP
#define FINAL_RECT CGRectMake(0, 0, next, DETOUR_ACCESSORY_BUTTON_SIZE)

    if (detour.systemWide) {
        NEXT_GAP;
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        NEXT_RECT(button.frame, DETOUR_ACCESSORY_BUTTON_SIZE);

        NSString *icon;

        if (hidden) {
            icon = kSFIconChevronUp;
        } else {
            icon = kSFIconChevronDown;
        }
        
        [button setImage:[UIImage systemImageNamed:icon] forState:UIControlStateNormal];

    
        button.accessibilityLabel = @"Hide or show detour";
        button.tag = DETOUR_BUTTON_COLLAPSE;
        [button addTarget:self
                      action:@selector(detourButtonAction:)
            forControlEvents:UIControlEventTouchUpInside];
        [buttons addObject:button];
    }

    if (routeDisclosure && detour.routes && detour.routes.count > 0 &&
        !hidden && !detour.systemWide) {
        NEXT_GAP;
        button = [UIButton buttonWithType:UIButtonTypeCustom];

        NEXT_RECT(button.frame, SMALL_BUTTON_SIDE);
        
        [button setImage:[UIImage systemImageNamed:kSFIconWebForward] forState:UIControlStateNormal];
    
        // width += (buttons.count > 0 ? AB_WGAP + AB_WIDTH  : 0);
        button.userInteractionEnabled = NO;

        [buttons addObject:button];
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
    } else {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    UIView *accessoryView = [[UIView alloc] initWithFrame:FINAL_RECT];

    for (UIButton *button in buttons) {
        [accessoryView addSubview:button];
    }

    self.backgroundColor = [UIColor clearColor];
    self.accessoryView = accessoryView;
}

- (NSString *)routeLink:(NSString *)route {
    if (route) {
        return
            [NSString stringWithFormat:@"\n#Lroute:%@ See route info#T", route];
    }
    return nil;
}

- (void)populateCell:(Detour *)detour route:(NSString *)route {
    [self resetForReuse];
    if (detour.systemWide &&
        [Settings isHiddenSystemWideDetour:detour.detourId]) {
        self.textView.attributedText =
            detour.markedUpHeader.smallAttributedStringFromMarkUp;
    } else {
        NSString *routeLink = [self routeLink:route];

        if (detour.systemWide) {
            routeLink = nil;
        }

        if (self.includeHeaderInDescription) {
            self.textView.attributedText =
                [detour markedUpDescriptionWithHeader:routeLink]
                    .smallAttributedStringFromMarkUp;
        } else {
            self.textView.attributedText =
                [detour markedUpDescription:routeLink]
                    .smallAttributedStringFromMarkUp;
        }
    }

    self.textLabel.accessibilityLabel =
        [detour markedUpDescription:[self routeLink:route]]
            .removeMarkUp.phonetic;

    self.selectionStyle = UITableViewCellSelectionStyleNone;

    [self addDetourButtons:detour routeDisclosure:NO];

    self.detour = detour;
}

- (BOOL)textView:(UITextView *)textView
    shouldInteractWithURL:(NSURL *)URL
                  inRange:(NSRange)characterRange
              interaction:(UITextItemInteraction)interaction {
    if (self.urlCallback) {
        return self.urlCallback(self, URL.absoluteString);
    }

    return TRUE;
}

@end
