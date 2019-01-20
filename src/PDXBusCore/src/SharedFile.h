//
//  SharedFile.h
//  PDXBusCore
//
//  Created by Andrew Wallace on 5/15/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import <Foundation/Foundation.h>

@interface SharedFile : NSObject

@property (nonatomic, readonly) bool canUseSharedFilePath;
@property (strong) NSURL *urlToSharedFile;
@property (nonatomic, copy) NSString *shortName;

- (instancetype)initWithFileName:(NSString *)shortFileNamem initFromBundle:(bool)initFromBundle;
- (void)writeDictionary:(NSDictionary *)dict;
- (void)writeDictionaryBinary:(NSDictionary *)dict;
- (NSMutableDictionary*)readFromFile:(NSPropertyListFormat*)format;
- (void)deleteFile;

+ (instancetype)fileWithName:(NSString *)shortFileName initFromBundle:(bool)initFromBundle;

@end
