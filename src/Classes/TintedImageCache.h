//
//  TintedImageCache.h
//  PDX Bus
//
//  Created by Andrew Wallace on 8/11/19.
//  Copyright © 2019 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "MemoryCaches.h"

NS_ASSUME_NONNULL_BEGIN

#define TINT_FOR_IOS_DARK_MODE @"D"
#define TINT_FOR_BLUE          @"B"
#define TINT_FOR_DARK_BLUE     @"L"

@interface TintedImageCache : NSObject<ClearableCache>

+ (instancetype)sharedInstance;
- (UIImage *)icon:(NSString *)name color:(UIColor *)tint designation:(NSString *)designation;
- (UIImage *)modeAwareLightenedIcon:(NSString *)name;
- (UIImage *)modeAwareBlueIcon:(NSString *)name;
- (void)userInterfaceStyleChanged:(NSInteger)style;

@end

NS_ASSUME_NONNULL_END
