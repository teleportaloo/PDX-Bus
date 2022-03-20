//
//  WatchContext.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface WatchContext : NSObject

@property (nonatomic, copy)   NSString *sceneName;

+ (instancetype)contextWithSceneName:(NSString *)sceneName;
- (instancetype)initWithSceneName:(NSString *)sceneName;
- (void)pushFrom:(WKInterfaceController *)parent;
- (void)delayedPushFrom:(WKInterfaceController *)parent completion:(void (^)(void))completion;

@end
