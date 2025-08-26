//
//  NSString+DocPath.m
//  PDX Bus
//
//  Created by Andy Wallace on 5/3/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "NSString+DocPath.h"
#import "TaskDispatch.h"

@implementation NSString (DocPath)

- (NSString *)fullDocPath {
    NSString *full = [NSString.docFolder stringByAppendingPathComponent:self];
    return full;
}

+ (NSString *)docFolder {
    static NSString *docFolder;

    DoOnce(^{
      NSArray *paths = NSSearchPathForDirectoriesInDomains(
          NSDocumentDirectory, NSUserDomainMask, YES);

      docFolder = paths.firstObject;
    });

    return docFolder;
}

@end
