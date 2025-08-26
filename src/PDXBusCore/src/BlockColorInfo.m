//
//  BlockColorInfo.m
//  PDX Bus
//
//  Created by Andy Wallace on 2/24/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BlockColorInfo.h"
#import "DebugLogging.h"
#import "PlistMacros.h"

#define DEBUG_LEVEL_FOR_FILE LogUI

#define kKeyR @"r"
#define kKeyG @"g"
#define kKeyB @"b"
#define kKeyA @"a"
#define kKeyT @"time"
#define kKeyD @"desc"

@interface BlockColorInfo ()

// Tell compiler to generate setter and getter, but setter is protected
@property(nonatomic) CGFloat valR;
@property(nonatomic) CGFloat valG;
@property(nonatomic) CGFloat valB;
@property(nonatomic) CGFloat valA;
@property(nonatomic) NSTimeInterval valTime;
@property(nonatomic, copy) NSString *valDesc;

@property(nonatomic, copy) UIColor *color;

// Redeclared from parent so we can access
@property(nonatomic, retain) NSMutableDictionary *mDict;

@end

@implementation BlockColorInfo

PROP_CGFloat(R, kKeyR, 0);
PROP_CGFloat(G, kKeyG, 0);
PROP_CGFloat(B, kKeyB, 0);
PROP_CGFloat(A, kKeyA, 0);
PROP_NSNumber(Time, kKeyT, NSTimeInterval, doubleValue, 0);
PROP_NSString(Desc, kKeyD, @"");

- (UIColor *)color {
    return [UIColor colorWithRed:self.valR
                           green:self.valG
                            blue:self.valB
                           alpha:self.valA];
}

- (void)setColor:(UIColor *)col {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;

    [col getRed:&red green:&green blue:&blue alpha:&alpha];

    self.valR = red;
    self.valG = green;
    self.valB = blue;
    self.valA = alpha;
}

// Tell compiler to use the existing parent's accessor
@dynamic mDict;

@end

@implementation MutableBlockColorInfo

// Tells the compiler to use the protected setters above
@dynamic valR;
@dynamic valG;
@dynamic valB;
@dynamic valA;
@dynamic valTime;
@dynamic valDesc;
@dynamic color;

- (NSMutableDictionary *)mutableDictionary {
    return self.mDict;
}

- (instancetype)init {
    return [super initMutable];
}

@end

@implementation NSDictionary (BlockColorInfo)

- (BlockColorInfo *)blockColorInfo {
    return [BlockColorInfo make:self];
}

@end

@implementation NSMutableDictionary (MutableBlockColorInfo)

- (MutableBlockColorInfo *)mutableBlockColorInfo {
    return [MutableBlockColorInfo makeMutable:self];
}

@end
