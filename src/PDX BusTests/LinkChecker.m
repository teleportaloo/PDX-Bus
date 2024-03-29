//
//  LinkChecker.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 5/9/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "LinkChecker.h"
#import "../PDXBusCore/src/DebugLogging.h"
#import <XCTest/XCTest.h>

#define DEBUG_LEVEL_FOR_FILE kLogTests

@interface LinkChecker () {
}


#define LOG_RESULT(s, ...)  [self.log addObject:[NSString stringWithFormat:(s), ## __VA_ARGS__]]

@property (atomic, strong) NSURLSession *session;
@property (atomic, strong)   NSMutableDictionary<NSNumber *, NSString *> *urlsToFind;
@property (atomic)  NSInteger maxLinks;
@property (atomic, strong)  NSMutableArray<NSString *> *log;
@property (atomic, strong)  NSMutableSet<NSString*> *ignoreSet;

@end

@implementation LinkChecker

+ (instancetype)withContext:(NSString *)context {
    return [[[self class] alloc] initWithContext:context];
}

- (instancetype)initWithContext:(NSString *)context {
    if ((self = [super init])) {
        self.urlsToFind = [NSMutableDictionary dictionary];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        self.maxLinks = 0;
        self.log = [NSMutableArray array];
        self.ignoreSet = [NSMutableSet set];
        self.context = context;
    }

    return self;
}

- (void)      URLSession:(NSURLSession *)session
                    task:(NSURLSessionTask *)task
    didCompleteWithError:(NSError *)error {
    if (error != nil) {
        NSString *url = self.urlsToFind[@(task.taskIdentifier)];

        if (url != nil) {
            switch (error.code)
            {
                case NSURLErrorAppTransportSecurityRequiresSecureConnection: {
                    LOG_RESULT(@"LINK %@ *** INSECURE  %@ - non-secure link requires manual check for %@", self.context, url,task.currentRequest.URL.absoluteString );
                    XCTFail(@"%@ cannot check link  %@ %@", self.context, url,task.currentRequest.URL.absoluteString);
                    break;
                }
                case NSURLErrorTimedOut: {
                    LOG_RESULT(@"LINK %@ *** TIMED OUT %@ - timed-out link requires manual check", self.context, url);
                    break;
                }
                default:
                    LOG_RESULT(@"LINK %@ *** FAIL      %@", self.context, url);
                    XCTFail(@"Link not found:  %@ %@", url, error.description);
                    break;
            }

            [self.urlsToFind removeObjectForKey:@(task.taskIdentifier)];
        }
    }
}

- (void)    URLSession:(NSURLSession *)session
              dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveResponse:(NSURLResponse *)response
     completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    bool ok = YES;


    if ([response respondsToSelector:@selector(statusCode)]) {
        NSInteger statusCode = [((NSHTTPURLResponse *)response) statusCode];

        if (statusCode != 200) {
            LOG_RESULT(@"LINK %@ *** %03d       %@ error code", self.context, (int)statusCode, self.urlsToFind[@(dataTask.taskIdentifier)]);
            XCTFail(@"Link not found:  %@ %d", self.urlsToFind[@(dataTask.taskIdentifier)], (int)statusCode);
            ok = NO;
        }
    }

    if (ok) {
#if 1
        NSString * url = self.urlsToFind[@(dataTask.taskIdentifier)];
        LOG_RESULT(@"LINK %@     FOUND     %@", self.context, url);
#endif
    }

    [self.urlsToFind removeObjectForKey:@(dataTask.taskIdentifier)];
    completionHandler(NSURLSessionResponseCancel);
}

- (void)checkWikiLink:(NSString *)wiki {
    if (wiki) {
        [self checkLink:[NSString stringWithFormat:@"https://en.m.wikipedia.org/wiki/%@", wiki]];
    }
}

- (void)checkLinksInAttributedString:(NSAttributedString *)string {
    
    for (NSInteger i=0; i<string.length; i++) {
        NSDictionary *attrs = [string attributesAtIndex:i effectiveRange:nil];
        
        NSObject *linkObj = attrs[NSLinkAttributeName];
        
        if (linkObj == nil) {
            continue;
        } else if ([linkObj isKindOfClass:[NSString class]]) {
            NSString *link = (NSString*)linkObj;
            [self checkLink:link];
        } else if ([linkObj isKindOfClass:[NSURL class]]) {
            NSURL *link =  (NSURL*)linkObj;
            [self checkLink:link.absoluteString];
        }
    }
}

- (void)checkLink:(NSString *)link {
    if (link != nil) {
        if (![self.ignoreSet containsObject:link]) {
            self.maxLinks++;
            NSURLSessionTask *task = [self.session dataTaskWithURL:[NSURL URLWithString:link]];
            self.urlsToFind[@(task.taskIdentifier)] = link;
            [self.ignoreSet addObject:link];
            [task resume];
        } 
    }
}

- (bool)done {
    return self.urlsToFind.count == 0;
}

- (void)waitUntilDone {
    NSInteger todo = 0;
    
    while (self.urlsToFind.count != 0) {
        if (todo != self.urlsToFind.count)
        {
            todo = self.urlsToFind.count;
            DEBUG_LOG_RAW(@"LINK %@     WAITING   Waiting for %d link(s)", self.context, (int)todo);
        }
        [NSThread sleepForTimeInterval:0.25];
    }
    
#ifdef DEBUGLOGGING
    for(NSString *item in self.log)
    {
        DEBUG_LOG_RAW(@"%@", item);
    }
#endif
    
    DEBUG_LOG_RAW(@"LINK %@     DONE      %d checked", self.context, (int)self.maxLinks);
}

@end
