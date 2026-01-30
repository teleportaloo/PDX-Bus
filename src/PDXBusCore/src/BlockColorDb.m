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

@interface BlockColorDb () {
    dispatch_queue_t _syncQueue;

    NSMutableDictionary<NSString *, NSDictionary *> *_rawColorMap;
    NSMutableDictionary<NSString *, UIColor *> *_rawColorCache;
}

@property (nonatomic, strong) SharedFile *file;

@end

@implementation BlockColorDb

#define blockFile @"blockcolors.plist"

- (instancetype)init {
    if ((self = [super init])) {
        _rawColorMap = [NSMutableDictionary dictionary];

        _file = [SharedFile fileWithName:blockFile initFromBundle:NO sync:self];

        _syncQueue =
            dispatch_queue_create("com.pdxbus.blockcolors.sync", DISPATCH_QUEUE_CONCURRENT);

        [MemoryCaches addCache:self];

        [self rawReadFromFile];

        _rawColorCache = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)dealloc {
    [MemoryCaches removeCache:self];
}

- (void)rawWriteToFile {
    [self.file writeDictionaryBinary:_rawColorMap];
}

- (void)forceFileRead {
    dispatch_barrier_async(_syncQueue, ^{
      self->_rawColorMap = nil;
    });
}

- (void)openFile {
    dispatch_barrier_async(_syncQueue, ^{
      [self rawOpenFile];
    });
}

- (void)rawOpenFile {
    if (self->_rawColorMap == nil) {
        [self rawReadFromFile];
        _rawColorCache = [NSMutableDictionary dictionary];
    }
}

- (void)memoryWarning {
    dispatch_barrier_sync(_syncQueue, ^{
      DEBUG_LOG(@"Releasing color map %p\n", (id)self->_rawColorMap);
      self->_rawColorMap = nil;
      self->_rawColorCache = [NSMutableDictionary dictionary];
    });
}

- (void)rawReadFromFile {
    if (self.file.urlToSharedFile != nil) {
        NSPropertyListFormat format;

        _rawColorMap = [self.file readFromFile:&format];

        if (_rawColorMap && format != NSPropertyListBinaryFormat_v1_0) {
            [self rawWriteToFile];
        };
    }

    if (_rawColorMap == nil) {
        _rawColorMap = [NSMutableDictionary dictionary];
    }
}

- (void)clearAll {
    dispatch_barrier_async(_syncQueue, ^{
      self->_rawColorMap = [NSMutableDictionary dictionary];
      self->_rawColorCache = [NSMutableDictionary dictionary];

      [self rawWriteToFile];
      UserState.sharedInstance.dirty = YES;
    });
}

+ (BlockColorDb *)sharedInstance {
    static BlockColorDb *singleton = nil;

    DO_ONCE(^{
      singleton = [[BlockColorDb alloc] init];
    });

    return singleton;
}

- (UIColor *)colorForBlock:(NSString *)block {
    __block UIColor *col = nil;
    dispatch_sync(_syncQueue, ^{
      [self rawOpenFile];

      if (block == nil) {
          col = [UIColor clearColor];
          return;
      }

      col = self->_rawColorCache[block];

      if (col == nil) {
          NSDictionary *dict = self->_rawColorMap[block];

          if (dict) {
              col = dict.blockColorInfo.color;
              [self->_rawColorCache setObject:col forKey:block];
          }
      }
    });
    return col;
}

- (void)addColor:(UIColor *)color forBlock:(NSString *)block description:(NSString *)desc {
    dispatch_barrier_async(_syncQueue, ^{
      [self rawOpenFile];

      if (color == nil) {
          [self->_rawColorMap removeObjectForKey:block];
          [self->_rawColorCache removeObjectForKey:block];
          dispatch_async(self->_syncQueue, ^{
            [self rawWriteToFile];
          });
          return;
      }

      MutableBlockColorInfo *info = MutableBlockColorInfo.new;

      info.color = color;
      info.valDesc = desc;
      info.valTime = [NSDate date].timeIntervalSinceReferenceDate;

      while (self->_rawColorMap.count > 128) {
          // Find the oldest item
          __block double oldestTime = MAXFLOAT;
          __block NSString *oldestKey = nil;
          __block NSTimeInterval time;

          [self->_rawColorMap enumerateKeysAndObjectsUsingBlock:^void(
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

          [self->_rawColorMap removeObjectForKey:oldestKey];
          [self->_rawColorCache removeObjectForKey:oldestKey];
      }

      self->_rawColorMap[block] = info.dictionary;
      self->_rawColorCache[block] = color;

      dispatch_async(self->_syncQueue, ^{
        [self rawWriteToFile];
      });

      UserState.sharedInstance.dirty = YES;
    });
}

- (NSArray *)keys {
    __block NSArray *result = nil;
    dispatch_sync(_syncQueue, ^{
      [self rawOpenFile];
      result = self->_rawColorMap.allKeys;
    });
    return result;
}

- (NSString *)descForBlock:(NSString *)block {
    __block NSString *result = nil;
    dispatch_sync(_syncQueue, ^{
      [self rawOpenFile];

      NSDictionary *item = _rawColorMap[block];

      if (item != nil) {
          result = item.blockColorInfo.valDesc;
      }
    });
    return result;
}

- (NSDictionary *)db {
    __block NSDictionary *result = nil;
    dispatch_sync(_syncQueue, ^{
      [self rawOpenFile];
      result = _rawColorMap;
    });
    return result;
}

- (void)setDb:(NSDictionary *)db {
    dispatch_barrier_async(_syncQueue, ^{
      [self rawOpenFile];

      self->_rawColorMap = [NSMutableDictionary dictionaryWithDictionary:db];
      self->_rawColorCache = [NSMutableDictionary dictionary];

      [self rawWriteToFile];
    });
}

- (NSDate *)timeForBlock:(NSString *)block {
    __block NSDate *result = nil;
    dispatch_sync(_syncQueue, ^{
      [self rawOpenFile];

      NSDictionary *item = _rawColorMap[block];

      if (item != nil) {
          result = [NSDate dateWithTimeIntervalSinceReferenceDate:item.blockColorInfo.valTime];
      }
    });
    return result;
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
