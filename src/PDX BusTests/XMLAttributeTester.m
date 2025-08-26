//
//  XMLAttributeTester.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 10/3/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLAttributeTester.h"
#import "../PDXBusCore/src/CLLocation+Helper.h"
#import "../PDXBusCore/src/NSDictionary+Types.h"
#import "../PDXBusCore/src/TriMetXMLSelectors.h"

@implementation XMLAttributeTester

- (NSString *)fullAddressForQuery:(NSString *)query {
    return query;
}

XML_START_ELEMENT(action) { self.action(XML_ATR_DICT, self); }

XML_START_ELEMENT(resultSet) {
    [self initItems];
    _hasData = YES;

    self.queryTime = XML_ATR_DATE(@"queryTime");
}

- (id)nextItem {
    if (self.itemPos < self.items.count) {
        return self.items[self.itemPos++];
    }
    return nil;
}

@end
