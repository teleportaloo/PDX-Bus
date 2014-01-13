
//
//  BlockColorDb.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/25/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlockColorDb : NSObject
{
    NSMutableDictionary *_colorMap;
    NSString *_fileName;
}

+ (BlockColorDb *)getSingleton;
- (UIColor *) colorForBlock:(NSString *)block;
- (void)addColor:(UIColor *)color forBlock:(NSString *)block description:(NSString*)desc;
- (void)clearAll;
- (NSArray *)keys;
- (NSString *)descForBlock:(NSString *)block;
- (NSDate *)timeForBlock:(NSString *)block;
+ (UIImage *)imageWithColor:(UIColor *)color;

@end
