//
//  NSHTTPURLResponse+Headers.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/11/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "NSHTTPURLResponse+Headers.h"
#import "DebugLogging.h"

#define DEBUG_LEVEL_FOR_FILE kLogNetworking


#define HTTP_CACHE_CONTROL   @"Cache-Control"
#define HTTP_MAX_AGE         @"max-age="

@implementation NSHTTPURLResponse (Headers)

- (NSHTTPURLResponse *)withMaxAge:(NSTimeInterval)duration {
    NSDictionary *headers = self.allHeaderFields;
    NSMutableDictionary *newHeaders = [headers mutableCopy];
    
    newHeaders[HTTP_CACHE_CONTROL] = [NSString stringWithFormat:@"%@%ld", HTTP_MAX_AGE, (long)duration];
    [newHeaders removeObjectForKey:@"Expires"];
    [newHeaders removeObjectForKey:@"s-maxage"];
    
    NSHTTPURLResponse *newResponse = [[NSHTTPURLResponse alloc] initWithURL:self.URL
                                                                 statusCode:self.statusCode
                                                                HTTPVersion:@"HTTP/1.1"
                                                               headerFields:newHeaders];
    
#ifdef DEBUGLOGGING
    [newResponse maxAgeDate];
#endif
    
    return newResponse;
}

- (NSDate *)headerDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"];
    return [dateFormatter dateFromString:self.allHeaderFields[@"Date"]];
}

- (NSTimeInterval)headerMaxAge {
    NSString *cacheControl = self.allHeaderFields[HTTP_CACHE_CONTROL];
    NSTimeInterval maxAge = HTTP_NO_AGE;
    
    if ([cacheControl hasPrefix:HTTP_MAX_AGE]) {
        maxAge = [cacheControl substringFromIndex:HTTP_MAX_AGE.length].longLongValue;
    }
    
    return maxAge;
}

- (bool)olderThanMaxAge {
    return self.hasMaxAge && [self.maxAgeDate timeIntervalSinceNow] <= 0;
}

- (NSDate *)maxAgeDate {
    NSTimeInterval duration = self.headerMaxAge;
    
    if (duration == HTTP_NO_AGE) {
        return nil;
    }
    
    NSDate *expiration = [self.headerDate dateByAddingTimeInterval:duration];
    
    DEBUG_LOGF(duration);
    DEBUG_LOGDATE(expiration);
    
    return expiration;
}

- (bool)hasMaxAge {
    return self.allHeaderFields[HTTP_CACHE_CONTROL] != nil;
}

@end
