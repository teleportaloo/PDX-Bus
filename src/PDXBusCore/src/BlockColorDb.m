//
//  BlockColorDb.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/25/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BlockColorDb.h"
#import "DebugLogging.h"
#import <CoreGraphics/CoreGraphics.h>
#import "UserFaves.h"


@implementation BlockColorDb

@synthesize colorMap = _colorMap;
@synthesize file     = _file;

#define kKeyR   @"r"
#define kKeyG   @"g"
#define kKeyB   @"b"
#define kKeyA   @"a"
#define kKeyT   @"time"
#define kKeyD   @"desc"

#define blockFile @"blockcolors.plist"

- (void)writeToFile
{
    [self.file writeDictionary:self.colorMap];
}

- (void)openFile
{
    if (_colorMap == nil)
    {
        [self readFromFile];
    }
}

- (void)memoryWarning
{
    DEBUG_LOG(@"Releasing color map %p\n", (id)_colorMap);
    [_colorMap release];
    _colorMap = nil;
}

- (void)readFromFile
{
    if (self.file.urlToSharedFile !=nil)
    {
        self.colorMap = [NSMutableDictionary dictionaryWithContentsOfURL:self.file.urlToSharedFile];
    }
    
    if (self.colorMap == nil)
    {
        self.colorMap = [NSMutableDictionary dictionary];
    }
}

- (instancetype)init {
	if ((self = [super init]))
	{
        self.colorMap = [NSMutableDictionary dictionary];
        
        self.file = [[[SharedFile alloc] initWithFileName:blockFile initFromBundle:NO] autorelease];
        
        [MemoryCaches addCache:self];

        [self readFromFile];
    }
    return self;
}

- (void)clearAll
{
    [_colorMap release];
     _colorMap = [[NSMutableDictionary alloc] init];
    
    [self writeToFile];
    [SafeUserData singleton].favesChanged = YES;
}

- (void)dealloc
{
    self.colorMap = nil;
    self.file     = nil;
    
    [MemoryCaches removeCache:self];
    
    [super dealloc];
}

+ (BlockColorDb *)singleton
{
    static BlockColorDb *singleton = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[BlockColorDb alloc] init];
    });
    
    return [[singleton retain] autorelease];
}

- (CGFloat)getComponent:(NSString*)key fromDict:(NSDictionary *)dict
{
    return (CGFloat)((NSNumber*)dict[key]).floatValue;
}

- (UIColor *) colorForBlock:(NSString *)block
{
    [self openFile];
    
    if (block == nil)
    {
        return [UIColor clearColor];
    }
    
    NSDictionary *item =_colorMap[block];
    
    if (item == nil)
    {
        return nil;
    }
    
    return [UIColor colorWithRed:[self getComponent:kKeyR fromDict:item]
                           green:[self getComponent:kKeyG fromDict:item]
                            blue:[self getComponent:kKeyB fromDict:item]
                           alpha:[self getComponent:kKeyA fromDict:item]];
}

- (void)addColor:(UIColor *)color forBlock:(NSString *)block description:(NSString*)desc
{
    [self openFile];
    
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    
    
    if (color == nil)
    {
        [_colorMap removeObjectForKey:block];
        [self writeToFile];
        return;
    }
    
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:@{kKeyR : @(red),
                                                                                kKeyG : @(green),
                                                                                kKeyB : @(blue),
                                                                                kKeyA : @(alpha),
                                                                                kKeyD : desc }];
    
    NSMutableDictionary *oldItem = _colorMap[block];
    
    if (oldItem == nil)
    {
        
        item[kKeyT] = @([NSDate date].timeIntervalSinceReferenceDate);
    }
    else
    {
        item[kKeyT] = oldItem[kKeyT];
    }
    
    
    while (_colorMap.count > 40)
    {
        // Find the oldest item
        __block double oldestTime = MAXFLOAT;
        __block NSString *oldestKey = nil;
        __block double time;
        
        [_colorMap enumerateKeysAndObjectsUsingBlock: ^void (NSString* key, NSDictionary* color, BOOL *stop)
         {
             time = ((NSNumber*)color[kKeyT]).doubleValue;
             
             if (time <= oldestTime)
             {
                 oldestTime = time;
                 oldestKey  = key;
             }
         }];
        
        if (oldestKey == nil)
        {
            // bad!
            break;
        }
        
        [_colorMap removeObjectForKey:oldestKey];
    }
    
    
    _colorMap[block] = item;
    
    
    [self writeToFile];
    
    [SafeUserData singleton].favesChanged = YES;
}

- (NSArray *)keys
{
    [self openFile];
    
    return _colorMap.allKeys;
}

- (NSString *)descForBlock:(NSString *)block
{
    [self openFile];
    
    NSDictionary *item = _colorMap[block];
    
    if (item==nil)
    {
        return nil;
    }
    
    return item[kKeyD];
}


- (NSDictionary*)getDB
{
    [self openFile];
    
    return _colorMap;
}

- (void)setDB:(NSDictionary*)db
{
    [self openFile];
    
    self.colorMap = [NSMutableDictionary dictionaryWithDictionary:db];
    
    [self writeToFile];
}

- (NSDate *)timeForBlock:(NSString *)block
{
    [self openFile];
    
    NSDictionary *item = _colorMap[block];
    
    if (item==nil)
    {
        return nil;
    }
    
    NSNumber *time = item[kKeyT];
    
    return [NSDate dateWithTimeIntervalSinceReferenceDate:time.floatValue];

}

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 20.0f, 20.0f);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


@end
