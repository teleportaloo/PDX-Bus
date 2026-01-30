//
//  BoxedIcon.m
//  PDX Bus
//
//  Created by Andy Wallace on 9/16/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//

#import "BoxedIcon.h"
#import "IconNames.h"
#import "Icons.h"
#import "TaskDispatch.h"

// Define the pointers to icons

#define ICON(X, S) BoxedNamedIcon *X;
#define SF_ICON(X, S) BoxedSystemIcon *X;
#define SF_ICON_ALT(X, S, A) SF_ICON(X, S)
#define SF_ICON_TINT(X, S, C) BoxedIconSystemTinted *X;
#define SF_ICON_ALT_TINT(X, S, A, C) SF_ICON_TINT(X, S, C)

#include "IconNames.def"

#undef ICON
#undef SF_ICON
#undef SF_ICON_ALT
#undef SF_ICON_TINT
#undef SF_ICON_ALT_TINT

@interface BoxedIcon ()

@property (nonatomic, copy) NSString *name;

@end

@implementation BoxedIcon

- (instancetype)initWithName:(NSString *)name {
    if (self = [super init]) {
        self.name = name;
    }
    return self;
}

+ (instancetype)withName:(NSString *)name {
    return [[self.class alloc] initWithName:name];
}

- (UIImage *__nullable)image {
    return nil;
}

- (UIColor *__nullable)tint {
    return nil;
}

- (NSString *)markup {
    return @"";
}

+ (void)initializeIcons {
#define ICON(X, S) X = [BoxedNamedIcon withName:(X##Name)];
#define SF_ICON(X, S) X = [BoxedSystemIcon withName:(X##Name)];
#define SF_ICON_ALT(X, S, A) SF_ICON(X, S)
#define SF_ICON_TINT(X, S, C) X = [BoxedIconSystemTinted withName:(X##Name) tint:(C)];
#define SF_ICON_ALT_TINT(X, S, A, C) SF_ICON_TINT(X, S, C)

#include "IconNames.def"

#undef ICON
#undef SF_ICON
#undef SF_ICON_ALT
#undef SF_ICON_TINT
#undef SF_ICON_ALT_TINT
}

@end

@implementation BoxedSystemIcon

- (UIImage *__nullable)image {
    return [Icons safeSystemIcon:self.name];
}

- (NSString *)markup {
    return [@"#S" stringByAppendingString:self.name];
}

@end

@interface BoxedIconSystemTinted ()

@property (nonatomic, retain) UIColor *internalTint;

@end

@implementation BoxedIconSystemTinted

- (instancetype)initWithName:(NSString *)name tint:(UIColor *)color {
    if (self = [super initWithName:name]) {
        self.internalTint = color;
    }
    return self;
}

+ (instancetype)withName:(NSString *)name tint:(UIColor *)color {
    return [[[self class] alloc] initWithName:name tint:color];
}

- (UIImage *__nullable)image {
    return [Icons safeSystemIcon:self.name];
}

- (UIColor *__nullable)tint {
    return _internalTint;
}

@end

@implementation BoxedNamedIcon

- (UIImage *__nullable)image {
    return [Icons assetIcon:self.name];
}

- (NSString *)markup {
    return [@"#F" stringByAppendingString:self.name];
}

@end

@implementation BoxedCharacterIcon

- (UIImage *__nullable)image {
    return [Icons characterIcon:self.name];
}

- (NSString *)markup {
    return self.name;
}

@end

@interface BoxedImageIcon ()

@property (nonatomic, retain) UIImage *internalImage;

@end

@implementation BoxedImageIcon

+ (instancetype)withImage:(UIImage *)image {
    return [[[self class] alloc] initWithImage:image];
}

- (instancetype)initWithImage:(UIImage *)image {
    if (self = [super initWithName:@""]) {
        self.internalImage = image;
    }
    return self;
}

- (UIImage *__nullable)image {
    return _internalImage;
}

@end
