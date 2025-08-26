//
//  Detour.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Detour.h"
#import "DebugLogging.h"
#import "NSDictionary+Types.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "Route.h"
#import "TaskDispatch.h"
#import "TriMetXML.h"
#import "TriMetXMLSelectors.h"

#define DEBUG_LEVEL_FOR_FILE LogUI

@interface Detour ()

@property(nonatomic, copy) NSString *detourWithDetectedStopIds;

@end

@implementation Detour

- (instancetype)init {
    if (self = [super init]) {
        self.locations = [NSMutableArray array];
    }

    return self;
}

- (BOOL)isEqual:(id)anObject {
    return self.detourId.unsignedIntegerValue ==
           ((Detour *)anObject).detourId.unsignedIntegerValue;
    // If it's an object. Otherwise use a simple comparison like self.personId
    // == anObject.personId
}

- (NSUInteger)hash {
    return self.detourId.unsignedIntegerValue;
}

- (NSArray<NSString *> *)extractStops {
    if (self.embeddedStops == nil) {
        [self stopScanner];
    }

    return self.embeddedStops.allObjects;
}

- (NSString *)detectStops {
    if (self.detourWithDetectedStopIds == nil) {
        [self stopScanner];
    }

    return self.detourWithDetectedStopIds;
}

- (void)skipSpaces:(NSMutableString *)result
        scanString:(NSString *)scanString
           scanner:(NSScanner *)scanner {
    while (!scanner.isAtEnd &&
           [scanString characterAtIndex:scanner.scanLocation] == ' ') {
        [result appendString:@" "];
        scanner.scanLocation++;
    }
}

- (void)stopScanner {
    self.embeddedStops = [NSMutableSet set];

    static NSCharacterSet *numbersOrBrace;
    static NSCharacterSet *numbers;
    static NSArray<NSString *> *searchStrings;

    DoOnce((^{
      // An open or a close brace will end the search for stop Ids in a
      // sequence. An open brace is unexpected so stopping is the safest.
      numbersOrBrace =
          [NSCharacterSet characterSetWithCharactersInString:@"0123456789)("];
      numbers =
          [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];

      searchStrings =
          @[ @"(stop id", @"( stop id", @"#h" ]; // String is made lower case
    }));

    NSMutableString *result = self.detourDesc.safeEscapeForMarkUp.mutableCopy;
    NSString *segment = nil;
    NSString *scanString = nil;
    long long stop = 0;

    for (NSString *prefix in searchStrings) {
        scanString = result;
        result = [NSMutableString string];

        NSScanner *scanner = [NSScanner scannerWithString:scanString];
        scanner.caseSensitive = NO;
        scanner.scanLocation = 0;
        segment = nil;
        bool braces = [prefix characterAtIndex:0] == '(';

        while (!scanner.isAtEnd) {
            [scanner scanUpToString:prefix intoString:&segment];

            if (segment) {
                [result appendString:segment];
            }

            if (!scanner.isAtEnd &&
                scanner.scanLocation + prefix.length < scanString.length) {
                NSString *text = [scanString
                    substringWithRange:NSMakeRange(scanner.scanLocation,
                                                   prefix.length)];

                scanner.scanLocation += prefix.length;

                [result appendString:text];

                while (!scanner.isAtEnd) {
                    segment = nil;

                    // Oddly, spaces here will vanish
                    [self skipSpaces:result
                          scanString:scanString
                             scanner:scanner];

                    // If we have a # we do not tolerate junk between the # and
                    // the number
                    if (!scanner.isAtEnd && braces) {
                        [scanner scanUpToCharactersFromSet:numbersOrBrace
                                                intoString:&segment];

                        if (segment) {
                            [result appendString:segment];
                        }
                    }

                    if (!scanner.isAtEnd) {
                        // Any kind of brace will stop the scanning for IDs.
                        unichar charAtIndex =
                            [scanString characterAtIndex:scanner.scanLocation];
                        if (charAtIndex == ')' || charAtIndex == '(') {
                            break;
                        }

                        segment = nil;

                        if ([scanner scanCharactersFromSet:numbers
                                                intoString:&segment]) {
                            stop = segment.longLongValue;

                            if (stop > 0) {
                                [result appendFormat:@"#Lid:%lld %@#T", stop,
                                                     segment];
                                [self.embeddedStops
                                    addObject:[NSString
                                                  stringWithFormat:@"%lld",
                                                                   stop]];
                            } else if (segment) {
                                [result appendString:segment];
                            }
                        } else {
                            break;
                        }

                        [self skipSpaces:result
                              scanString:scanString
                                 scanner:scanner];

                        // If we have a # then stop after the first number
                        if (!braces) {
                            break;
                        }
                    }
                }
            } else if (!scanner.isAtEnd) {
                // There may be a malformed search string at the end.  This
                // ensures no characters are lost even the junk.
                NSString *text = [scanString
                    substringWithRange:NSMakeRange(scanner.scanLocation,
                                                   scanString.length -
                                                       scanner.scanLocation)];
                [result appendString:text];
                break;
            } else {
                break;
            }
            segment = nil;
        }
    }

    // This line is for debugging - it adds a stop to every detour so we can
    // test a stop with other detour combinations.

    // [self.embeddedStops addObject:[NSString stringWithFormat:@"%lld", (long
    // long)365]];

    self.detourWithDetectedStopIds = result;
}

- (NSComparisonResult)compare:(Detour *)other {

    if (self.systemWide == other.systemWide) {
        NSInteger t1 = self.detourId.integerValue & DETOUR_ID_TAG_MASK;
        NSInteger t2 = other.detourId.integerValue & DETOUR_ID_TAG_MASK;

        return (t1 == t2) ? [self.detourId compare:other.detourId] : t1 - t2;
    }

    if (self.systemWide) {
        return NSOrderedAscending;
    }

    // other.systemWide must be true

    return NSOrderedDescending;
}

+ (bool)goodUrlOrNil:(NSString *)url {
    if (url != nil) {
        NSURL *candidateURL = [NSURL URLWithString:url];
        // WARNING > "test" is an URL according to RFCs, being just a path
        // so you still should check scheme and all other NSURL attributes you
        // need
        if (candidateURL && candidateURL.scheme && candidateURL.host) {
            // candidate is a well-formed url with:
            //  - a scheme (like http://)
            //  - a host (like stackoverflow.com)
            return YES;
        }
    } else {
        return YES;
    }

    return NO;
}

+ (Detour *)fromAttributeDict:(NSDictionary *)attributeDict
                    allRoutes:(AllTriMetRoutes *)allRoutes
                     addEmoji:(bool)addEmoji {
    Detour *result = [Detour new];

    NSNumber *detourId = @(TRIMET_DETOUR_ID(XML_ATR_INT(@"id")));

    result.detourDesc =
        [TriMetXML replaceXMLcodes:XML_NON_NULL_ATR_STR(@"desc")]
            .stringByTrimmingWhitespace;
    result.headerText =
        [TriMetXML replaceXMLcodes:XML_NON_NULL_ATR_STR(@"header_text")]
            .stringByTrimmingWhitespace;
    // result.infoLinkUrl =

    NSString *url = XML_NULLABLE_ATR_STR(@"info_link_url");

    if ([Detour goodUrlOrNil:url]) {
        result.infoLinkUrl = url;
    }

    if ([url containsString:@" "]) {
        NSArray<NSString *> *prefixes = @[ @" https:", @" http:" ];

        for (NSString *prefix in prefixes) {
            // There might be several URLs here.  Take the last one.
            NSRange lastURL =
                [url rangeOfString:prefix
                           options:NSCaseInsensitiveSearch | NSBackwardsSearch];

            if (lastURL.length > 0) {
                url = [url substringFromIndex:lastURL.location + 1];

                if ([Detour goodUrlOrNil:url]) {
                    result.infoLinkUrl = url;
                    break;
                }
            }
        }
    }

    result.detourId = detourId;
    result.systemWide = XML_ATR_BOOL_DEFAULT_FALSE(@"system_wide_flag");
    result.endDate = XML_ATR_DATE(@"end");
    result.beginDate = XML_ATR_DATE(@"begin");
    result.routes = [NSMutableOrderedSet orderedSet];

    if (result.systemWide) {
        if (result.headerText == nil || result.headerText.length == 0) {
            result.headerText = kSystemWideDetour;
        }

        if (addEmoji) {
            static NSDictionary<NSString *, NSString *> *prefixes = nil;

            DoOnce(^{
              prefixes = [[NSDictionary alloc]
                  initWithContentsOfFile:[[NSBundle mainBundle]
                                             pathForResource:@"DetourEmoji"
                                                      ofType:@"plist"]];
            });

            __block NSString *symbol = @"⚠️";

            [prefixes enumerateKeysAndObjectsUsingBlock:^(
                          NSString *_Nonnull key, NSString *_Nonnull obj,
                          BOOL *_Nonnull stop) {
              if ([result.headerText hasCaseInsensitiveSubstring:key]) {
                  symbol = obj;
                  *stop = YES;
              }
            }];

            result.headerText =
                [NSString stringWithFormat:@"%@ %@", symbol, result.headerText];
        }

        Route *route = [Route systemWide:detourId];
        route.desc = result.headerText;

        Route *cached = allRoutes[route.routeId];

        if (cached == nil) {
            allRoutes[route.routeId] = route;
            cached = route;
        }

        [result.routes addObject:cached];
    } else if (result.headerText.length > result.detourDesc.length / 2) {
        result.headerText = @"";
    }

    return result;
}

@end
