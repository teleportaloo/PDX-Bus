//
//  XMLToTestCode.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 10/4/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLToTestCode.h"

@implementation XMLToTestCode

- (void)emitProperty {
    if (self.contentOfCurrentProperty &&
        self.contentOfCurrentProperty.length > 0 &&
        [self.contentOfCurrentProperty
            stringByTrimmingCharactersInSet:
                [NSCharacterSet whitespaceAndNewlineCharacterSet]]
                .length != 0) {
        NSMutableString *prop = self.contentOfCurrentProperty;

        [prop replaceOccurrencesOfString:@"&"
                              withString:@"&amp;"
                                 options:NSLiteralSearch
                                   range:NSMakeRange(0, [prop length])];
        [prop replaceOccurrencesOfString:@"\""
                              withString:@"&quot;"
                                 options:NSLiteralSearch
                                   range:NSMakeRange(0, [prop length])];
        [prop replaceOccurrencesOfString:@"'"
                              withString:@"&#x27;"
                                 options:NSLiteralSearch
                                   range:NSMakeRange(0, [prop length])];
        [prop replaceOccurrencesOfString:@">"
                              withString:@"&gt;"
                                 options:NSLiteralSearch
                                   range:NSMakeRange(0, [prop length])];
        [prop replaceOccurrencesOfString:@"<"
                              withString:@"&lt;"
                                 options:NSLiteralSearch
                                   range:NSMakeRange(0, [prop length])];
        [prop replaceOccurrencesOfString:@"\n"
                              withString:@"\\n"
                                 options:NSLiteralSearch
                                   range:NSMakeRange(0, [prop length])];

        [self.result
            appendFormat:@"[xmlFile.xml appendString:@\"%@\"]\n", prop];
    }
    self.contentOfCurrentProperty = nil;
}

- (void)parser:(NSXMLParser *)parser
    didStartElement:(NSString *)elementName
       namespaceURI:(NSString *)namespaceURI
      qualifiedName:(NSString *)qName
         attributes:(NSDictionary *)attributeDict {
    if ([NSThread currentThread].isCancelled) {
        [parser abortParsing];
        return;
    }

    if (qName) {
        elementName = qName;
    }

    [self emitProperty];

    self.contentOfCurrentProperty = [NSMutableString string];

    if (self.result == nil) {
        self.result = [NSMutableString string];
    }

    [self.result
        appendFormat:@"[xmlFile startTagWithAttributes:@\"%@\" attributes:@[\n",
                     elementName];

    __block bool first = YES;

    [attributeDict enumerateKeysAndObjectsUsingBlock:^(
                       id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
      if (!first) {
          [self.result appendFormat:@",\n"];
      }
      [self.result appendFormat:@"        @[@\"%@\", @\"%@\"]", (NSString *)key,
                                (NSString *)obj];
      first = NO;
    }];

    [self.result appendFormat:@"\n]];\n"];
}

- (void)parser:(NSXMLParser *)parser
    didEndElement:(NSString *)elementName
     namespaceURI:(NSString *)namespaceURI
    qualifiedName:(NSString *)qName {
    if ([NSThread currentThread].isCancelled) {
        [parser abortParsing];
        return;
    }

    [self emitProperty];

    self.contentOfCurrentProperty = nil;

    [self.result appendFormat:@"[xmlFile closeTag:@\"%@\"]\n", elementName];
}

@end
