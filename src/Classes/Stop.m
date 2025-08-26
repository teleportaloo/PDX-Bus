//
//  Stop.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Stop.h"
#import "NSString+Core.h"
#import "TriMetXML.h"
#import "TriMetXMLSelectors.h"
#import "NSDictionary+Types.h"
#import "CLLocation+Helper.h"


@implementation Stop

- (void)dealloc {
}

- (NSComparisonResult)compareUsingIndex:(Stop *)inStop {
    if (self.index < inStop.index) {
        return NSOrderedAscending;
    }

    if (self.index > inStop.index) {
        return NSOrderedDescending;
    }

    return NSOrderedSame;
}

- (NSComparisonResult)compareUsingStopName:(Stop *)inStop {
    return [self.desc compare:inStop.desc
                      options:(NSNumericSearch | NSCaseInsensitiveSearch)];
}

- (NSString *)stringToFilter {
    return self.desc;
}

+ (Stop *)fromAttributeDict:(NSDictionary *)XML_ATR_DICT {
    Stop *stop = [Stop new];
    stop.stopId = XML_NON_NULL_ATR_STR(@"locid");
    stop.desc = XML_NON_NULL_ATR_STR(@"desc");
    stop.timePoint = XML_ATR_BOOL_DEFAULT_FALSE(@"tp");
    stop.location = XML_ATR_LOCATION(@"lat", @"lng");
    stop.dir = XML_NON_NULL_ATR_STR(@"dir");
    return stop;
}

@end
