//
//  TintedImageCache.m
//  PDX Bus
//
//  Created by Andrew Wallace on 8/11/19.
//  Copyright © 2019 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TintedImageCache.h"
#import "MemoryCaches.h"
#import "ViewControllerBase.h"
#import "UIColor+DarkMode.h"
#import "UIImage+Tint.h"

@implementation TintedImageCache


- (instancetype)init
{
    if ((self = [super init]))
    {
        self.cache = [[NSMutableDictionary alloc] init];
        [MemoryCaches addCache:self];
    }
    return self;
}

- (void)memoryWarning
{
    [self.cache removeAllObjects];
}

- (void)dealloc
{
    [MemoryCaches removeCache:self];
}

+ (TintedImageCache *)sharedInstance
{
    static TintedImageCache *singleton = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[TintedImageCache alloc] init];
        
    });
    return singleton;
}

- (UIImage*)icon:(NSString *)name color:(UIColor*)tint designation:(NSString*)designation
{
    NSString *key = [NSString stringWithFormat:@"%@/%@", designation, name];
    
    UIImage *image = self.cache[key];
    
    if (image == nil)
    {
        image = [ViewControllerBase getIcon:name];
        image = [image tintImageWithColor:tint];
        [self.cache setObject:image forKey:key];
    }
    
    return image;
}

- (UIImage*)modeAwareLightenedIcon:(NSString *)name
{
    if (@available(iOS 13.0, *))
    {
        if (IOS_DARK_MODE)
        {
            return [self icon:name color:[UIColor whiteColor] designation:TINT_FOR_IOS_DARK_MODE];
        }

    }
    return [ViewControllerBase getIcon:name];
}


- (UIImage*)modeAwareBlueIcon:(NSString *)name
{
    // These colors are based in the "information icon" (i) color
    if (@available(iOS 13.0, *))
    {
        if (IOS_DARK_MODE)
        {
            return [self icon:name color:HTML_COLOR(0x0099FF) designation:TINT_FOR_DARK_BLUE];
        }
    }
    return [self icon:name color:HTML_COLOR(0x0066FF) designation:TINT_FOR_BLUE];
}

- (void)userInterfaceStyleChanged:(NSInteger)style
{
    if (style != self.style)
    {
        [self.cache removeAllObjects];
        self.style = style;
    }
}

@end
