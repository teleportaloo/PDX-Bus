//
//  CatchHtmlRedirect.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/17/12.
//  Copyright (c) 2012 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ProcessQRCodeString.h"

@implementation ProcessQRCodeString



// check that this is a good URL - the original URL may be completely different
// we have to deal with a redirect.
// http://trimet.org/qr/08225

#define URL_PROTOCOL @"http://"
#define URL_TRIMET   @"trimet.org/qr/"
#define URL_BEFORE_ID (URL_PROTOCOL URL_TRIMET)


- (NSString *)extractStopId:(NSString *)originalURL
{
    if (originalURL.length >=URL_PROTOCOL.length && [[originalURL substringToIndex:URL_PROTOCOL.length] isEqualToString:URL_PROTOCOL])
    {
        [self checkURL:originalURL];
        
        if (!self.stopId)
        {
            [self fetchDataByPolling:originalURL];
        }
    }
    return self.stopId;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // We got data - time to stop this now - we don't want the data we just wanted to
    // catch the redirect if there was any
    self.rawData = nil;
    [self.connection cancel];
    self.dataComplete = YES;
}

- (void)checkURL:(NSString *)str
{
    NSString *stopId = nil;
    self.stopId = nil;
    if (str.length < URL_BEFORE_ID.length || ![[str substringToIndex:URL_BEFORE_ID.length] isEqualToString:URL_BEFORE_ID])
    {
        return;
    }
    else 
    {
        NSScanner *scanner = [NSScanner scannerWithString:str];
        
        if (![scanner scanUpToString:URL_TRIMET intoString:nil])
        {
            return;
        }
        else if (scanner.atEnd)
        {
            return;
        }
        else
        {
            NSCharacterSet *slash = [NSCharacterSet characterSetWithCharactersInString:@"/"];
            scanner.scanLocation = scanner.scanLocation+URL_TRIMET.length;
            
            while ([str characterAtIndex:scanner.scanLocation]=='0')
            {
                scanner.scanLocation++;
            }
            
            [scanner scanUpToCharactersFromSet:slash intoString:&stopId];
            
            self.stopId = stopId;
            
            // Check that the stop id is a number - if not ABORT
            for (int i=0; i<stopId.length; i++)
            {
                if (!isdigit([stopId characterAtIndex:i]))
                {
                    self.stopId = nil;
                }
            }
            
        }
    }
}

- (NSURLRequest *)connection:(NSURLConnection *)connection 
             willSendRequest:(NSURLRequest *)request 
            redirectResponse:(NSURLResponse *)response
{    
    // We are looking for a TriMet URL. We can stop there if we find one, otherwise
    // the QR Code may be a URL that redirects to a TriMet URL.
    
    [self checkURL:request.URL.absoluteString];
    
    if (self.stopId != nil)
    {
        [self.connection cancel];
        return nil;
    }    
    
    return request;
}




@end
