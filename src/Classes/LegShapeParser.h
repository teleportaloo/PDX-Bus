//
//  LegShapeParser.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/31/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "StoppableFetcher.h"
#import "TriMetInfo.h"
#import "ShapeMutableSegment.h"

@class LegShapeParser;

typedef NSString * _Nonnull (^ReplacementForShapeQueryBlock) (LegShapeParser *_Nonnull xml, NSString * _Nonnull query);

@interface LegShapeParser : StoppableFetcher

@property (nonatomic, strong) ShapeMutableSegment *segment;
@property (nonatomic, copy)   NSString *lineURL;
@property (nonatomic, copy)   ReplacementForShapeQueryBlock replaceQueryBlock;

- (void)fetchCoords;

@end
