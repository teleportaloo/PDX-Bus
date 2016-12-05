//
//  SharedFile.h
//  PDXBusCore
//
//  Created by Andrew Wallace on 5/15/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import <Foundation/Foundation.h>

@interface SharedFile : NSObject
{
    NSURL * _urlToSharedFile;
}

@property (retain) NSURL *urlToSharedFile;

- (instancetype)initWithFileName:(NSString *)shortFileNamem initFromBundle:(bool)initFromBundle;
@property (nonatomic, readonly) bool canUseSharedFilePath;
- (void)writeDictionary:(NSDictionary *)dict;
- (void)deleteFile;



@end
