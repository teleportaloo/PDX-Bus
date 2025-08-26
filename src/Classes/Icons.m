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


#import "Icons.h"
#import "TaskDispatch.h"
#import "UIColor+MoreDarkMode.h"
#import "UIFont+Utility.h"

#define DEBUG_LEVEL_FOR_FILE LogUI

@interface Icons ()

@property NSCache<NSString *, UIImage *> *cache;

@end

@implementation Icons

- (instancetype)init {
    if ((self = [super init])) {
        _cache = [NSCache new];
    }

    return self;
}

+ (Icons *)sharedInstance {
    static Icons *singleton = nil;
    DoOnce(^{
      singleton = [[Icons alloc] init];
    });
    return singleton;
}

+ (void)getDelayedIcon:(NSString *)name
            completion:(void (^)(UIImage *image))completion {

    if (name == nil) {
        completion(nil);
        return;
    }

    UIImage *cachedImage = [Icons.sharedInstance.cache objectForKey:name];

    if (cachedImage != nil) {
        completion(cachedImage);
    } else {
        MainTask(^{
          // Try again to see if it got in the cache while we
          // were waiting for the cache to be available. This can
          // happen when multiple icons are being requested at
          // once.
          UIImage *icon = [Icons.sharedInstance.cache objectForKey:name];

          if (icon == nil) {

              DEBUG_LOG(@"Fetching icon %@", name)

              icon = [Icons getIcon:name];

              if (icon != nil) {
                  [Icons.sharedInstance.cache setObject:icon forKey:name];
              }
          } else {
              DEBUG_LOG(@"Not Fetching icon %@", name)
          }

          completion(icon);
        });
    }
}

+ (UIImage *)getIcon:(NSString *)name {
    UIImage *icon = [UIImage imageNamed:name];

    if (icon == nil) {
        icon = [UIImage imageNamed:kIconAppIconAction];
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

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(kTileWidth, kTileHeight),
                                           NO, 0);
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
                                 textSize.width, textSize.height);
    [text drawInRect:textRect withAttributes:attributes];

    icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return icon;
}

+ (UIImage *)characterIcon:(NSString *)text {
    return [Icons characterIcon:text placeholder:nil];
}

+ (UIImage *)characterIcon:(NSString *)text placeholder:(UIImage *)placeholder {
    UIColor *fg = [UIColor modeAwareText];

    NSString *key = [NSString stringWithFormat:@"!%@ %@", text, fg.string];

    UIImage *icon = [Icons.sharedInstance.cache objectForKey:key];

    if (icon == nil) {
        icon = [Icons characterIcon:text fg:fg];

        if (placeholder != nil) {
            // Check for the default Emoji - which is a kind of ?
            // If so then switch to the placeholder
            UIImage *defImage = [Icons characterIcon:@"\u1fff" placeholder:nil];

            if ([UIImagePNGRepresentation(defImage)
                    isEqual:UIImagePNGRepresentation(icon)]) {
                icon = placeholder;
            }
        }

        if (icon == nil) {
            icon = [UIImage imageNamed:kIconAppIconAction];
        }

        [Icons.sharedInstance.cache setObject:icon forKey:key];
    }

    return icon;
}

@end
