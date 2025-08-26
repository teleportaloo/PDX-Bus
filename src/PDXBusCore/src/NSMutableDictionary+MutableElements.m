//
//  NSMutableDictionary+MutableElements.m
//  PDXBusCore
//
//  Created by Andrew Wallace on 1/7/17.
//  Copyright © 2017 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DebugLogging.h"
#import "NSMutableDictionary+MutableElements.h"

@implementation NSMutableDictionary (MutableElements)

+ (NSMutableDictionary *)mutableContainersWithContentsOfURL:(NSURL *)url {
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (!data)
        return nil;

    NSError *error = nil;
    id plist = [NSPropertyListSerialization
        propertyListWithData:data
                     options:NSPropertyListMutableContainers
                      format:NULL
                       error:&error];
    LOG_NSError(error);
    
    if (!plist || ![plist isKindOfClass:[NSMutableDictionary class]]) {
        return nil;
    }

    LOG_NSError(error);
    
    NSMutableDictionary *dict = (NSMutableDictionary *)plist;

    return dict;
}

@end
