//
//  Icons.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/6/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define ICONS_IMPL

#import "Icons.h"
#import "BoxedIcon.h"
#import "IconNames.h"
#import "NSString+MoreMarkup.h"
#import "TaskDispatch.h"
#import "UIColor+MoreDarkMode.h"
#import "UIFont+Utility.h"

#define DEBUG_LEVEL_FOR_FILE LogUI

@interface Icons ()

@end

@implementation Icons

+ (void)load {
    [NSString
        setSystemImageAlternatives:^UIImage *(NSString *name, UIImageSymbolConfiguration *config) {
          UIImage *image = [UIImage systemImageNamed:name withConfiguration:config];

          if (image == nil) {
              name = [Icons alternatives:name];

              if (name) {
                  image = [UIImage systemImageNamed:name withConfiguration:config];
              }
          }
          return image;
        }];
}

+ (BoxedIcon *)assetOrSystemBoxedIcon:(NSString *)name {
    if (name) {
        if (name.length > 1 && name.firstUnichar == '!') {
            return [BoxedSystemIcon withName:[name substringFromIndex:1]];
        } else {
            return [BoxedNamedIcon withName:name];
        }
    }

    return nil;
}

static inline UIImage *placeholderIcon(CGFloat pointSize) {
    CGSize size = CGSizeMake(pointSize, pointSize);
    UIGraphicsImageRendererFormat *fmt = [UIGraphicsImageRendererFormat defaultFormat];
    fmt.opaque = NO;
    fmt.scale = UIScreen.mainScreen.scale; // correct pixels for the device

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size
                                                                               format:fmt];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull ctx) {
      [[UIColor clearColor] setFill];
      UIRectFill((CGRect){.origin = CGPointZero, .size = size});
    }];
}

+ (UIImage *)placeholder {
    static UIImage *blank = nil;

    DO_ONCE(^{
      blank = placeholderIcon(22.0);
    });

    return blank;
}

+ (UIImage *)assetIcon:(NSString *)name {
    UIImage *icon = [UIImage imageNamed:name];

    if (icon == nil) {
        icon = [UIImage imageNamed:kIconAppIconActionName];
    }

    icon.accessibilityHint = nil;
    icon.accessibilityLabel = nil;
    return icon;
}

+ (UIImage *)characterIcon:(NSString *)text fg:(UIColor *)fg {
    const CGFloat kTileWidth = 24;
    const CGFloat kTileHeight = 24;
    UIImage *icon;

    UIColor *bg = [UIColor clearColor];

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(kTileWidth, kTileHeight), NO, 0);
    CGRect rect = CGRectMake(0, 0, kTileWidth, kTileHeight);

    if (bg != nil) {
        [bg set];
        UIRectFill(rect);
    }

    UIFont *font = nil;

    if ([text characterAtIndex:0] < 128) {
        font = [UIFont monospacedDigitSystemFontOfSize:26];
    } else {
        font = [UIFont monospacedDigitSystemFontOfSize:22];
    }

    NSMutableParagraphStyle *paragraphStyle =
        [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = NSTextAlignmentCenter;

    NSDictionary *attributes = @{
        NSFontAttributeName : font,
        NSForegroundColorAttributeName : fg,
        NSParagraphStyleAttributeName : paragraphStyle
    };
    CGSize textSize = [text sizeWithAttributes:attributes];
    CGRect textRect = CGRectMake((kTileWidth - textSize.width) / 2,
                                 (kTileHeight - textSize.height) / 2,
                                 textSize.width,
                                 textSize.height);
    [text drawInRect:textRect withAttributes:attributes];

    icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return icon;
}

+ (UIImage *)characterIcon:(NSString *)text {
    return [Icons characterIcon:text placeholder:nil];
}

+ (UIImage *)characterIcon:(NSString *)text placeholder:(UIImage *)placeholder {
    UIColor *fg = [UIColor modeAwareBlue];

    UIImage *icon = [Icons characterIcon:text fg:fg];

    if (placeholder != nil) {
        // Check for the default Emoji - which is a kind of ?
        // If so then switch to the placeholder
        UIImage *defImage = [Icons characterIcon:@"\u1fff" placeholder:nil];

        if ([UIImagePNGRepresentation(defImage) isEqual:UIImagePNGRepresentation(icon)]) {
            icon = placeholder;
        }
    }

    if (icon == nil) {
        icon = [UIImage imageNamed:kIconAppIconActionName];
    }

    return icon;
}

+ (NSString *)alternatives:(NSString *)name {
    static dispatch_once_t onceToken;
    static NSDictionary<NSString *, NSString *> *alternatives;

    dispatch_once(&onceToken, ^{
      alternatives = @{

#define ICON(X, S)
#define SF_ICON(X, S)
#define SF_ICON_ALT(X, S, A) X##Name : A,
#define SF_ICON_TINT(X, S, C)
#define SF_ICON_ALT_TINT(X, S, A, C) SF_ICON_ALT(X, S, A)

#include "IconNames.def"

#undef ICON
#undef SF_ICON
#undef SF_ICON_ALT
#undef SF_ICON_TINT
#undef SF_ICON_ALT_TINT

      };
      DEBUG_LOG_long(alternatives.count);
    });

    return alternatives[name];
}

+ (UIImage *)safeSystemIcon:(NSString *)name {
    static NSCache<NSString *, UIImage *> *iconCache;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      iconCache = [[NSCache alloc] init];
    });

    UIImage *image = [iconCache objectForKey:name];

    if (!image) {
        image = [UIImage systemImageNamed:name];

        if (!image) {
            image = [UIImage systemImageNamed:[Icons alternatives:name]];
        }

        if (image) {
            [iconCache setObject:image forKey:name];
        }
    }

    return image;
}

@end
