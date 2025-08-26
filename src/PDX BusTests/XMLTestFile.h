//
//  XMLTestFile.h
//  PDX BusTests
//
//  Created by Andrew Wallace on 10/3/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "../PDXBusCore/src/TriMetXML.h"
#import <Foundation/Foundation.h>

#define MS_EPOCH(X) ((X).timeIntervalSince1970 * 1000)

NS_ASSUME_NONNULL_BEGIN

@interface XMLTestFile : NSObject

@property(nonatomic, strong) NSMutableString *xml;

+ (XMLTestFile *)fileWithOneTag:(NSString *)tag
                     attributes:(NSArray<NSArray<NSString *> *> *)attributes;
- (void)addHeaderTag:(NSDate *)date;
- (void)startTagWithAttributes:(NSString *)tag
                    attributes:(NSArray<NSArray<NSString *> *> *)attributes;
- (void)closeTag:(NSString *)tag;
- (void)tagWithAtrributes:(NSString *)tag
               attributes:(NSArray<NSArray<NSString *> *> *)attributes;
- (void)closeHeaderTag;

- (NSString *)makeURLstring;

- (XMLQueryTransformer)queryBlock;
+ (XMLQueryTransformer)queryBlockWithFileForClass:
    (NSDictionary<NSString *, NSString *> *)filesPerClass;

@end

NS_ASSUME_NONNULL_END
