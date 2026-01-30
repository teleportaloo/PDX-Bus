//
//  Icons.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/6/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MemoryCaches.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BoxedIcon;

__attribute__((swift_attr("@MainActor")))
@interface Icons : NSObject

+ (UIImage *)characterIcon:(NSString *)text;
+ (UIImage *)characterIcon:(NSString *)text placeholder:(UIImage *_Nullable)placeholder;
+ (BoxedIcon *__nullable)assetOrSystemBoxedIcon:(NSString *__nullable)name;
+ (UIImage *)safeSystemIcon:(NSString *)name;
+ (UIImage *)assetIcon:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
