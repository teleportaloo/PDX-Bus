//
//  "ProcessQRCodeString.m"
//  PDX Bus
//
//  Created by Andrew Wallace on 7/17/12.
//  Copyright (c) 2012 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogNet

#import "ProcessQRCodeString.h"

@interface ProcessQRCodeString ()

@property(nonatomic, copy) NSString *stopId;

@end

@implementation ProcessQRCodeString

// check that this is a good URL - the original URL may be completely different
// we have to deal with a redirect.
// http://trimet.org/qr/08225

#define URL_PROTOCOL @"http://"
#define URL_TRIMET @"trimet.org/qr/"
#define URL_BEFORE_ID (URL_PROTOCOL URL_TRIMET)

- (NSString *)extractStopId:(NSString *)originalURL {
    if ([originalURL hasPrefix:URL_PROTOCOL]) {
        [self checkURL:originalURL];

        if (!self.stopId) {
            [self fetchDataByPolling:originalURL
                         cachePolicy:NSURLRequestReloadIgnoringCacheData];
        }
    }

    return self.stopId;
}

- (void)URLSession:(NSURLSession *)session
              dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveResponse:(NSURLResponse *)response
     completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))
                           completionHandler {

    // We got data - time to stop this now - we don't want the data we just
    // wanted to catch the redirect if there was any
    self.rawData = nil;
    [self cancel];

    dispatch_semaphore_signal(self.fetchDone);

    completionHandler(NSURLSessionResponseCancel);
}

- (void)checkURL:(NSString *)str {
    NSString *stopId = nil;

    self.stopId = nil;

    DEBUG_LOG_NSString(str);

    if (str.length < URL_BEFORE_ID.length || ![str hasPrefix:URL_BEFORE_ID]) {
        return;
    } else {
        NSScanner *scanner = [NSScanner scannerWithString:str];

        if (![scanner scanUpToString:URL_TRIMET intoString:nil]) {
            return;
        } else if (scanner.atEnd) {
            return;
        } else {
            NSCharacterSet *slash =
                [NSCharacterSet characterSetWithCharactersInString:@"/"];
            scanner.scanLocation = scanner.scanLocation + URL_TRIMET.length;

            while ([str characterAtIndex:scanner.scanLocation] == '0') {
                scanner.scanLocation++;
            }

            [scanner scanUpToCharactersFromSet:slash intoString:&stopId];

            self.stopId = stopId;

            // Check that the stop id is a number - if not ABORT
            for (int i = 0; i < stopId.length; i++) {
                if (!isdigit([stopId characterAtIndex:i])) {
                    self.stopId = nil;
                }
            }
        }
    }
}

- (void)URLSession:(NSURLSession *)session
                          task:(NSURLSessionTask *)task
    willPerformHTTPRedirection:(NSHTTPURLResponse *)response
                    newRequest:(NSURLRequest *)request
             completionHandler:
                 (void (^)(NSURLRequest *_Nullable))completionHandler {
    DEBUG_LOG_NSString(request.URL.absoluteString);

    [self checkURL:request.URL.absoluteString];

    if (self.stopId != nil) {
        [self cancel];

        completionHandler(nil);
    } else {
        completionHandler(request);
    }
}

@end
