//
//  NSMutableDictionary+MutableElements.m
//  PDXBusCore
//
//  Created by Andrew Wallace on 1/7/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//

#import "NSMutableDictionary+MutableElements.h"
#import "DebugLogging.h"

@implementation NSMutableDictionary (MutableElements)

+ (NSMutableDictionary *)mutableContainersWithContentsOfURL:(NSURL *)url
{
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    if (data)
    {
        NSError *error = nil;
        NSMutableDictionary * result = [NSPropertyListSerialization propertyListWithData:data
                                                                                 options:NSPropertyListMutableContainers
                                                                                  format:nil error:nil];
        
        LOG_NSERROR(error);
        
        
        if ([result isKindOfClass:[NSMutableDictionary class]])
        {
            return  result;
        }
    }
    
    return nil;
}

@end
