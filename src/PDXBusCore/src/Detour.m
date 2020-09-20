//
//  Detour.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Detour.h"
#import "DebugLogging.h"
#import "TriMetXML.h"
#import "Route.h"
#import "NSString+Helper.h"
#import "NSDictionary+TriMetCaseInsensitive.h"
#import "TriMetXMLSelectors.h"

@interface Detour ()

@property (nonatomic, copy) NSString *detourWithDetectedStopIds;

@end

@implementation Detour

- (instancetype)init {
    if (self = [super init]) {
        self.locations = [NSMutableArray array];
    }
    
    return self;
}

- (BOOL)isEqual:(id)anObject {
    return self.detourId.unsignedIntegerValue == ((Detour *)anObject).detourId.unsignedIntegerValue;
    // If it's an object. Otherwise use a simple comparison like self.personId == anObject.personId
}

- (NSUInteger)hash {
    return self.detourId.unsignedIntegerValue;
}

- (NSArray<NSString *> *)extractStops {
    if (self.embeddedStops == nil)
    {
        [self stopScanner];
    }

    return self.embeddedStops.allObjects;
}

- (NSString *)detectStops {
    if (self.detourWithDetectedStopIds == nil)
    {
        [self stopScanner];
    }
    
    return self.detourWithDetectedStopIds;
}



- (void)skipSpaces:(NSMutableString *)result scanString:(NSString *)scanString scanner:(NSScanner *)scanner {
    while (!scanner.isAtEnd && [scanString characterAtIndex:scanner.scanLocation] == ' ') {
        [result appendString:@" "];
        scanner.scanLocation++;
    }
}

- (void)stopScanner {
    self.embeddedStops = [NSMutableSet set];
    
    static NSCharacterSet *numbersOrBrace;
    static NSCharacterSet *numbers;
    static NSArray<NSString *> *searchStrings;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        numbersOrBrace = [NSCharacterSet characterSetWithCharactersInString:@"0123456789)"];
        numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        
        searchStrings = @[ @"(stop id",  @"( stop id"];    // String is made lower case
    });
    
    NSMutableString *result = self.detourDesc.mutableCopy;
    NSString *segment = nil;
    NSString *scanString = nil;
    long long stop = 0;
    
    for (NSString *stopIds in searchStrings) {
        scanString = result;
        result = [NSMutableString string];
        
        NSScanner *scanner = [NSScanner scannerWithString:scanString];
        scanner.caseSensitive = NO;
        scanner.scanLocation = 0;
        segment = nil;
        
        while (!scanner.isAtEnd && [scanner scanUpToString:stopIds intoString:&segment]) {
            if (segment) {
                [result appendString:segment];
            }
            
            if (scanner.scanLocation + stopIds.length < scanString.length) {
                NSString *text = [scanString substringWithRange:NSMakeRange(scanner.scanLocation, stopIds.length)];
                
                scanner.scanLocation += stopIds.length;
                
                [result appendString:text];
                
                while (!scanner.isAtEnd) {
                    segment = nil;
                    
                    [scanner scanUpToCharactersFromSet:numbersOrBrace intoString:&segment];
                    
                    if (segment) {
                        [result appendString:segment];
                    }
                    
                    [self skipSpaces:result scanString:scanString scanner:scanner];
                    
                    if (!scanner.isAtEnd) {
                        if ([scanString characterAtIndex:scanner.scanLocation] == ')') {
                            break;
                        }
                        
                        segment = nil;
                        
                        if ([scanner scanCharactersFromSet:numbers intoString:&segment]) {
                            stop = segment.longLongValue;
                            
                            if (stop > 0) {
                                [result appendFormat:@"#Lid:%lld %@#T", stop, segment];
                                [self.embeddedStops addObject:[NSString stringWithFormat:@"%lld", stop]];
                            } else if (segment) {
                                [result appendString:segment];
                            }
                        } else {
                            break;
                        }
                        
                        [self skipSpaces:result scanString:scanString scanner:scanner];
                    }
                }
            }
            segment = nil;
        }
    }
    
    // This line is for debugging - it adds a stop to every detour so we can test a stop with
    // other detour combinations.
    
    // [self.embeddedStops addObject:[NSString stringWithFormat:@"%lld", (long long)365]];
    
    self.detourWithDetectedStopIds = result;
}

- (NSComparisonResult)compare:(Detour *)other {
    
    if (self.systemWide == other.systemWide)
    {
        NSInteger t1 = self.detourId.integerValue & DETOUR_ID_TAG_MASK;
        NSInteger t2 = other.detourId.integerValue & DETOUR_ID_TAG_MASK;
    
        return (t1 == t2)   ? [self.detourId compare:other.detourId]
                            : t1 - t2;
   
    }
    
    if (self.systemWide) {
        return NSOrderedAscending;
    }
    
    // other.systemWide must be true
    
    return NSOrderedDescending;
}

+ (Detour *)fromAttributeDict:(NSDictionary *)attributeDict allRoutes:(NSMutableDictionary<NSString *, Route *> *)allRoutes {
    Detour *result = [Detour data];
    
    NSNumber *detourId = @(TRIMET_DETOUR_ID(XML_ATR_INT(@"id")));
    
    result.detourDesc = [TriMetXML replaceXMLcodes:XML_NON_NULL_ATR_STR(@"desc")].stringByTrimmingWhitespace;
    result.headerText = [TriMetXML replaceXMLcodes:XML_NON_NULL_ATR_STR(@"header_text")].stringByTrimmingWhitespace;
    result.infoLinkUrl = XML_NULLABLE_ATR_STR(@"info_link_url");
    result.detourId = detourId;
    result.systemWide = XML_ATR_BOOL(@"system_wide_flag");
    result.endDate = XML_ATR_DATE(@"end");
    result.beginDate = XML_ATR_DATE(@"begin");
    result.routes = [NSMutableOrderedSet orderedSet];
    
    if (result.systemWide) {
        if (result.headerText == nil || result.headerText.length == 0) {
            result.headerText = kSystemWideDetour;
        }
        
        static NSDictionary<NSString *, NSString *> *prefixes = nil;
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            prefixes = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DetourEmoji" ofType:@"plist"]];
        });
        
        __block NSString *symbol = @"⚠️";
        
        [prefixes enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
            if ([result.headerText hasCaseInsensitiveSubstring:key]) {
                symbol = obj;
                *stop = YES;
            }
        }];
        
        result.headerText = [NSString stringWithFormat:@"%@ %@", symbol, result.headerText];
        
        Route *route = [Route systemWide:detourId];
        route.desc = result.headerText;
        
        Route *cached = allRoutes[route.route];
        
        if (cached == nil) {
            allRoutes[route.route] = route;
            cached = route;
        }
        
        [result.routes addObject:cached];
    } else if (result.headerText.length > result.detourDesc.length / 2) {
        result.headerText = @"";
    }
    
    return result;
}

@end
