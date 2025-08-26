//
//  TriMetXML+TestData.m
//  PDX Bus
//
//  Created by Andy Wallace on 8/23/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetXML.h"
#import "XMLDetours.h"
#import "XMLMultipleDepartures.h"
#import "XMLStreetcarMessages.h"

@interface TriMetXML (TestData)

@end

@implementation TriMetXML (TestData)

#if 0

#define LOG_QUERY(STR) ERROR_LOG(@"**** Using test data: %@", STR)
#define CLASS_2_STR(X) NSStringFromClass([X class])
#define STR_2_BLOCK(STR)                                                       \
    ^(TriMetXML * xml, NSString * query) {                                     \
      NSString *str = STR;                                                     \
      LOG_QUERY(str);                                                          \
      return str;                                                              \
    }
#define CLASS_QUERY(C, STR) CLASS_2_STR(C) : STR_2_BLOCK(STR)

#define CLASS_STOPS_2_STR(C, S, STR)                                           \
    CLASS_2_STR(C)                                                             \
        : ^(TriMetXML * xml, NSString * query) {                               \
            if (stringContains(query, S)) {                                    \
                NSString *str = STR;                                           \
                LOG_QUERY(str);                                                \
                return str;                                                    \
            }                                                                  \
            return [xml fullAddressForQuery:query];                            \
          }

static bool stringContains(NSString *haystack, NSArray<NSString *> *needles) {
    for (NSString *needle in needles) {
        if ([haystack containsString:needle]) {
            return YES;
        }
    }
    return NO;
}

+ (void)load {
    static NSDictionary<NSString *, XMLQueryTransformer> *tx;

    tx = @{
        // Detours with a system wide detour.
        CLASS_QUERY(XMLDetours,
                    @"https://raw.githubusercontent.com/teleportaloo/"
                    @"TriMetTestData/refs/heads/master/alertsv2.xml"),

        // Actual streercar alarts
        CLASS_QUERY(XMLStreetcarMessages, @"https://raw.githubusercontent.com/"
                                          @"teleportaloo/"
                                          @"TriMetTestData/refs/heads/master/"
                                          @"Streetcar-messages.xml"),

        // Departure with a system wide detour
        CLASS_STOPS_2_STR(XMLMultipleDepartures,
                          (@[ @"9818", @"365", @"9837" ]),
                          @"https://raw.githubusercontent.com/teleportaloo/"
                          @"TriMetTestData/refs/heads/master/"
                          @"arrivals-multiple.xml")};

    ERROR_LOG(@"******** TEST DATA ********");
    self.globalQueryTransformer = ^(TriMetXML *xml, NSString *query) {
      XMLQueryTransformer transform = tx[CLASS_2_STR(xml)];
      if (transform) {
          return transform(xml, query);
      } else {
          return [xml fullAddressForQuery:query];
      }
    };
}

#else

+ (void)load {
    self.globalQueryTransformer = ^(TriMetXML *xml, NSString *query) {
      return [xml fullAddressForQuery:query];
    };
};

#endif

@end
