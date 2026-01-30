//
//  BoxedIcon.h
//  PDX Bus
//
//  Created by Andy Wallace on 9/16/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//
// This is a simple system where all icons can be passed around using the same class, a boxed icon.
// This is so we can pass along a system icon, a named icom from a file or even a character icon and
// fetch it asynchronously if needed.  The image for the icon is provided as a completion to
// the fetch method.
//
// If the placeholder is non-nil then the fetch is asynchronous.

#import "Icons.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((swift_attr("@MainActor")))
@interface BoxedIcon : NSObject

+ (instancetype)withName:(NSString *)name;
- (instancetype)initWithName:(NSString *)name;
- (UIImage *__nullable)image;
- (UIColor *__nullable)tint;
- (NSString *)markup;

+ (void)initializeIcons;

@end

@interface BoxedIconSystemTinted : BoxedIcon

- (instancetype)initWithName:(NSString *)name tint:(UIColor *)color;
+ (instancetype)withName:(NSString *)name tint:(UIColor *)color;

@end

@interface BoxedSystemIcon : BoxedIcon

@end

@interface BoxedNamedIcon : BoxedIcon

@end

@interface BoxedCharacterIcon : BoxedIcon

@end

@interface BoxedImageIcon : BoxedIcon

+ (instancetype)withImage:(UIImage *)image;
- (instancetype)initWithImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END

// The icons now are created with an extern BoxedIcon
#define ICON(X, S) extern BoxedNamedIcon *X;
#define SF_ICON(X, S) extern BoxedSystemIcon *X;
#define SF_ICON_ALT(X, S, A) SF_ICON(X, S);
#define SF_ICON_TINT(X, S, C) extern BoxedIconSystemTinted *X;
#define SF_ICON_ALT_TINT(X, S, A, C) SF_ICON_TINT(X, S, C)

#include "IconNames.def"

#undef ICON
#undef SF_ICON
#undef SF_ICON_ALT
#undef SF_ICON_TINT
#undef SF_ICON_ALT_TINT
