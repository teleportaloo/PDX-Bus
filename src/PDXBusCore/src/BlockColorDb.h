//
//  BlockColorDb.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/25/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "MemoryCaches.h"
#import "SharedFile.h"
#import <Foundation/Foundation.h>

@class UIColor;
@class UIImage;


@interface BlockColorDb : NSObject <ClearableCache>

@property (nonatomic, strong) NSMutableDictionary *colorCache;
@property (nonatomic, strong) NSMutableDictionary *colorMap;
@property (nonatomic, readonly, copy) NSArray *keys;
@property (nonatomic, strong) SharedFile *file;
@property (nonatomic, copy) NSDictionary *db;

- (void)addColor:(UIColor *)color forBlock:(NSString *)block description:(NSString*)desc;
- (UIColor *)colorForBlock:(NSString *)block;
- (NSString *)descForBlock:(NSString *)block;
- (NSDate *)timeForBlock:(NSString *)block;
- (void)memoryWarning;
- (void)clearAll;
- (void)openFile;

+ (BlockColorDb *)sharedInstance;
+ (UIImage *)imageWithColor:(UIColor *)color;

@end
