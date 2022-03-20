//
//  BlockColorDb.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/25/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogUserInterface

#import "BlockColorDb.h"
#import "DebugLogging.h"
#import <CoreGraphics/CoreGraphics.h>
#import "UserState.h"
#import "PDXBusCore.h"

@interface BlockColorDb ()

@property (nonatomic, strong) NSMutableDictionary *colorCache;
@property (nonatomic, strong) SharedFile *file;

@end

@implementation BlockColorDb

#define kKeyR     @"r"
#define kKeyG     @"g"
#define kKeyB     @"b"
#define kKeyA     @"a"
#define kKeyT     @"time"
#define kKeyD     @"desc"

#define blockFile @"blockcolors.plist"

- (void)writeToFile {
    [self.file writeDictionaryBinary:self.colorMap];
}

- (void)forceFileRead {
    _colorMap = nil;
}

- (void)openFile {
    if (_colorMap == nil) {
        [self readFromFile];
        self.colorCache = [NSMutableDictionary dictionary];
    }
}

- (void)memoryWarning {
    DEBUG_LOG(@"Releasing color map %p\n", (id)_colorMap);
    self.colorMap = nil;
    self.colorCache = [NSMutableDictionary dictionary];
}

- (void)readFromFile {
    if (self.file.urlToSharedFile != nil) {
        NSPropertyListFormat format;
        
        self.colorMap = [self.file readFromFile:&format];
        
        if (self.colorMap && format != NSPropertyListBinaryFormat_v1_0) {
            [self writeToFile];
        }
        
        ;
    }
    
    if (self.colorMap == nil) {
        self.colorMap = [NSMutableDictionary dictionary];
    }
}

- (instancetype)init {
    if ((self = [super init])) {
        self.colorMap = [NSMutableDictionary dictionary];
        
        self.file = [SharedFile fileWithName:blockFile initFromBundle:NO];
        
        [MemoryCaches addCache:self];
        
        [self readFromFile];
        
        self.colorCache = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)clearAll {
    self.colorCache = [NSMutableDictionary dictionary];
    self.colorMap = [NSMutableDictionary dictionary];
    
    [self writeToFile];
    UserState.sharedInstance.favesChanged = YES;
}

- (void)dealloc {
    [MemoryCaches removeCache:self];
}

+ (BlockColorDb *)sharedInstance {
    static BlockColorDb *singleton = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        singleton = [[BlockColorDb alloc] init];
    });
    
    return singleton;
}

#define GET_COMPONENT(key, dict) ((CGFloat)((NSNumber *)dict[key]).floatValue)

- (UIColor *)colorForBlock:(NSString *)block {
    [self openFile];
    
    if (block == nil) {
        return [UIColor clearColor];
    }
    
    UIColor *col = _colorCache[block];
    
    if (col != nil) {
        return col;
    } else {
        NSDictionary *item = _colorMap[block];
        
        if (item == nil) {
            return nil;
        }
        
        col = [UIColor colorWithRed:GET_COMPONENT(kKeyR, item)
                              green:GET_COMPONENT(kKeyG, item)
                               blue:GET_COMPONENT(kKeyB, item)
                              alpha:GET_COMPONENT(kKeyA, item)];
        [_colorCache setObject:col forKey:block];
    }
    
    return col;
}

- (void)addColor:(UIColor *)color forBlock:(NSString *)block description:(NSString *)desc {
    [self openFile];
    
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    
    if (color == nil) {
        [_colorMap removeObjectForKey:block];
        [_colorCache removeObjectForKey:block];
        [self writeToFile];
        return;
    }
    
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:@{ kKeyR: @(red),
                                                                                 kKeyG: @(green),
                                                                                 kKeyB: @(blue),
                                                                                 kKeyA: @(alpha),
                                                                                 kKeyD: desc }];
    
    item[kKeyT] = @([NSDate date].timeIntervalSinceReferenceDate);
    
    while (_colorMap.count > 50) {
        // Find the oldest item
        __block double oldestTime = MAXFLOAT;
        __block NSString *oldestKey = nil;
        __block double time;
        
        [_colorMap enumerateKeysAndObjectsUsingBlock: ^void (NSString *key, NSDictionary *color, BOOL *stop)
         {
            time = ((NSNumber *)color[kKeyT]).doubleValue;
            
            if (time <= oldestTime) {
                oldestTime = time;
                oldestKey  = key;
            }
        }];
        
        if (oldestKey == nil) {
            // bad!
            break;
        }
        
        [_colorMap removeObjectForKey:oldestKey];
        [_colorCache removeObjectForKey:oldestKey];
    }
    
    _colorMap[block] = item;
    _colorCache[block] = color;
    
    [self writeToFile];
    
    UserState.sharedInstance.favesChanged = YES;
}

- (NSArray *)keys {
    [self openFile];
    
    return _colorMap.allKeys;
}

- (NSString *)descForBlock:(NSString *)block {
    [self openFile];
    
    NSDictionary *item = _colorMap[block];
    
    if (item == nil) {
        return nil;
    }
    
    return item[kKeyD];
}

- (NSDictionary *)db {
    [self openFile];
    
    return _colorMap;
}

- (void)setDb:(NSDictionary *)db {
    [self openFile];
    
    self.colorMap = [NSMutableDictionary dictionaryWithDictionary:db];
    self.colorCache = [NSMutableDictionary dictionary];
    
    [self writeToFile];
}

- (NSDate *)timeForBlock:(NSString *)block {
    [self openFile];
    
    NSDictionary *item = _colorMap[block];
    
    if (item == nil) {
        return nil;
    }
    
    NSNumber *time = item[kKeyT];
    
    return [NSDate dateWithTimeIntervalSinceReferenceDate:time.floatValue];
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 24.0f, 24.0f);
    
    /* Note:  This is a graphics context block */
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

@end
