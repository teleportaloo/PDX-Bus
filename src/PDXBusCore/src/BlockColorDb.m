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


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "BlockColorDb.h"
#import "BlockColorInfo.h"
#import "DebugLogging.h"
#import "PDXBusCore.h"
#import "TaskDispatch.h"
#import "UserState.h"
#import <CoreGraphics/CoreGraphics.h>

@interface BlockColorDb ()

@property(nonatomic, strong) NSMutableDictionary *colorCache;
@property(nonatomic, strong) SharedFile *file;

@end

@implementation BlockColorDb

#define blockFile @"blockcolors.plist"

- (instancetype)init {
    if ((self = [super init])) {
        _colorMap = [NSMutableDictionary dictionary];

        _file = [SharedFile fileWithName:blockFile initFromBundle:NO sync:self];

        [MemoryCaches addCache:self];

        [self readFromFile];

        _colorCache = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)dealloc {
    @synchronized(self) {
        [MemoryCaches removeCache:self];
    }
}

- (void)writeToFile {
    [self.file writeDictionaryBinary:self.colorMap];
}

- (void)forceFileRead {
    @synchronized(self) {
        _colorMap = nil;
    }
}

- (void)openFile {
    @synchronized(self) {
        if (_colorMap == nil) {
            [self readFromFile];
            self.colorCache = [NSMutableDictionary dictionary];
        }
    }
}

- (void)memoryWarning {
    @synchronized(self) {
        DEBUG_LOG(@"Releasing color map %p\n", (id)_colorMap);
        self.colorMap = nil;
        self.colorCache = [NSMutableDictionary dictionary];
    }
}

- (void)readFromFile {
    @synchronized(self) {
        if (self.file.urlToSharedFile != nil) {
            NSPropertyListFormat format;

            self.colorMap = [self.file readFromFile:&format];

            if (self.colorMap && format != NSPropertyListBinaryFormat_v1_0) {
                [self writeToFile];
            };
        }

        if (self.colorMap == nil) {
            self.colorMap = [NSMutableDictionary dictionary];
        }
    }
}

- (void)clearAll {
    @synchronized(self) {
        self.colorCache = [NSMutableDictionary dictionary];
        self.colorMap = [NSMutableDictionary dictionary];

        [self writeToFile];
        UserState.sharedInstance.favesChanged = YES;
    }
}

+ (BlockColorDb *)sharedInstance {
    static BlockColorDb *singleton = nil;

    DoOnce(^{
      singleton = [[BlockColorDb alloc] init];
    });

    return singleton;
}

- (UIColor *)colorForBlock:(NSString *)block {
    @synchronized(self) {
        [self openFile];

        if (block == nil) {
            return [UIColor clearColor];
        }

        UIColor *col = _colorCache[block];

        if (col != nil) {
            return col;
        } else {
            NSDictionary *dict = _colorMap[block];

            if (dict == nil) {
                return nil;
            }

            col = dict.blockColorInfo.color;
            [_colorCache setObject:col forKey:block];
        }

        return col;
    }
}

- (void)addColor:(UIColor *)color
        forBlock:(NSString *)block
     description:(NSString *)desc {
    @synchronized(self) {
        [self openFile];

        if (color == nil) {
            [_colorMap removeObjectForKey:block];
            [_colorCache removeObjectForKey:block];
            [self writeToFile];
            return;
        }

        MutableBlockColorInfo *info = MutableBlockColorInfo.new;

        info.color = color;
        info.valDesc = desc;
        info.valTime = [NSDate date].timeIntervalSinceReferenceDate;

        while (_colorMap.count > 50) {
            // Find the oldest item
            __block double oldestTime = MAXFLOAT;
            __block NSString *oldestKey = nil;
            __block NSTimeInterval time;

            [_colorMap enumerateKeysAndObjectsUsingBlock:^void(
                           NSString *key, NSDictionary *color, BOOL *stop) {
              time = color.blockColorInfo.valTime;
              if (time <= oldestTime) {
                  oldestTime = time;
                  oldestKey = key;
              }
            }];

            if (oldestKey == nil) {
                // bad!
                break;
            }

            [_colorMap removeObjectForKey:oldestKey];
            [_colorCache removeObjectForKey:oldestKey];
        }

        _colorMap[block] = info.dictionary;
        _colorCache[block] = color;

        [self writeToFile];

        UserState.sharedInstance.favesChanged = YES;
    }
}

- (NSArray *)keys {
    @synchronized(self) {
        [self openFile];
        return _colorMap.allKeys;
    }
}

- (NSString *)descForBlock:(NSString *)block {
    @synchronized(self) {
        [self openFile];

        NSDictionary *item = _colorMap[block];

        if (item == nil) {
            return nil;
        }

        return item.blockColorInfo.valDesc;
    }
}

- (NSDictionary *)db {
    @synchronized(self) {
        [self openFile];
        return _colorMap;
    }
}

- (void)setDb:(NSDictionary *)db {
    @synchronized(self) {
        [self openFile];

        self.colorMap = [NSMutableDictionary dictionaryWithDictionary:db];
        self.colorCache = [NSMutableDictionary dictionary];

        [self writeToFile];
    }
}

- (NSDate *)timeForBlock:(NSString *)block {
    @synchronized(self) {
        [self openFile];

        NSDictionary *item = _colorMap[block];

        if (item == nil) {
            return nil;
        }

        return [NSDate
            dateWithTimeIntervalSinceReferenceDate:item.blockColorInfo.valTime];
    }
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
