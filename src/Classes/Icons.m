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
#import "UIColor+DarkMode.h"
#import "TintedImageCache.h"

@implementation Icons

+ (UIImage *)getIcon:(NSString *)name {
    UIImage *icon = [UIImage imageNamed:name];
    
    if (icon == nil) {
        icon = [UIImage imageNamed:kIconAppIconAction];
    }
    
    icon.accessibilityHint = nil;
    icon.accessibilityLabel = nil;
    return icon;
}

+ (UIImage *)getToolbarIcon:(NSString *)name {
    UIImage *icon = [UIImage imageNamed:name];
    
    icon.accessibilityHint = nil;
    icon.accessibilityLabel = nil;
    return icon;
}

+ (UIImage *)characterIcon:(NSString *)text fg:(UIColor *)fg
{
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
        font = [UIFont systemFontOfSize:26];
    } else {
        font = [UIFont systemFontOfSize:22];
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{ NSFontAttributeName: font, NSForegroundColorAttributeName: fg, NSParagraphStyleAttributeName: paragraphStyle };
    CGSize textSize = [text sizeWithAttributes:attributes];
    CGRect textRect = CGRectMake((kTileWidth - textSize.width) / 2, (kTileHeight - textSize.height) / 2, textSize.width, textSize.height);
    [text drawInRect:textRect withAttributes:attributes];
    
    
    icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return icon;
}

+ (UIImage *)characterIcon:(NSString *)text
{
    return [Icons characterIcon:text placeholder:nil];
}

+ (UIImage *)characterIcon:(NSString *)text placeholder:(UIImage *)placeholder
{
    static NSMutableDictionary<NSString *, UIImage *> *cache;
    
    static dispatch_once_t onceToken;
    
    UIColor *fg = [UIColor modeAwareText];
    
    dispatch_once(&onceToken, ^{
        cache = [NSMutableDictionary dictionary];
        
    });
    
    NSString *key = [NSString stringWithFormat:@"%@ %@", text, fg.string];
    
    UIImage *icon = cache[key];
    
    if (icon == nil) {
        icon = [Icons characterIcon:text fg:fg];
        
        if (placeholder != nil)
        {
            // Check for the default Emoji - which is a kind of ?
            // If so then switch to the placeholder
            UIImage *defImage = [Icons characterIcon:@"\u1fff" placeholder:nil];
            
            if ([UIImagePNGRepresentation(defImage) isEqual:UIImagePNGRepresentation(icon)]) {
                icon = placeholder;
            }
        }
        
        if (icon == nil)
        {
            icon = [UIImage imageNamed:kIconAppIconAction];
        }
        
        cache[key] = icon;
    }
    
    return icon;
}

+ (UIImage *)getModeAwareIcon:(NSString *)name {
    return [[TintedImageCache sharedInstance] modeAwareLightenedIcon:name];
}



@end
