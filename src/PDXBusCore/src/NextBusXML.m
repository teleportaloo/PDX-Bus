//
//  NextBusXML.m
//  PDX Bus
//
//  Created by Andrew Wallace on 3/28/10.
//
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "NextBusXML.h"

@implementation NextBusXML

- (NSString *)fullAddressForQuery:(NSString *)query {
    return [NSString stringWithFormat:@"http://webservices.nextbus.com/service/publicXMLFeed?command=%@", query];
}

@end
