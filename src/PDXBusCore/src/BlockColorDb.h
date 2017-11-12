//
//  BlockColorDb.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/25/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
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
{
    NSMutableDictionary *_colorMap;
    SharedFile          *_file;
}

@property (nonatomic, retain) SharedFile *file;
@property (nonatomic, retain) NSMutableDictionary *colorMap;

+ (BlockColorDb *)sharedInstance;
- (UIColor *) colorForBlock:(NSString *)block;
- (void)addColor:(UIColor *)color forBlock:(NSString *)block description:(NSString*)desc;
- (void)clearAll;
@property (nonatomic, readonly, copy) NSArray *keys;
- (NSString *)descForBlock:(NSString *)block;
- (NSDate *)timeForBlock:(NSString *)block;
+ (UIImage *)imageWithColor:(UIColor *)color;
- (void)openFile;
- (void)memoryWarning;
@property (nonatomic, getter=getDB, copy) NSDictionary *DB;

@end
