//
//  XMLTestFile.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 10/3/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//




/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogTestFiles

#import "XMLTestFile.h"
#import "../PDXBusCore/src/DebugLogging.h"

@implementation XMLTestFile


- (instancetype)init {
    if ((self = [super init])) {
        self.xml = [NSMutableString string];
    }
    
    return self;
}

+ (XMLTestFile *)fileWithOneTag:(NSString *)tag attributes:(NSArray<NSArray<NSString*> *> *)attributes
{
    XMLTestFile *xmlFile =  [[XMLTestFile alloc] init];
    
    [xmlFile addHeaderTag:[NSDate date]];
    [xmlFile tagWithAtrributes:tag attributes:attributes];
    [xmlFile closeHeaderTag];
    
    return xmlFile;
}

- (void)addHeaderTag:(NSDate *)date
{
    [self.xml appendFormat:@"\n<resultSet xmlns=\"urn:trimet:rt\" queryTime=\"%lld\">\n", (long long)([date timeIntervalSince1970] * 1000.0)];
}

- (void)closeHeaderTag
{
    [self.xml appendFormat:@"</resultSet>"];
    DEBUG_LOGS(self.xml);
    
}

- (void)tagWithAtrributes:(NSString *)tag attributes:(NSArray<NSArray<NSString*> *> *)attributes
{
    [self tagLineWithAtrributes:tag attributes:attributes close:YES];
}

- (void)startTagWithAttributes:(NSString *)tag attributes:(nonnull NSArray<NSArray<NSString*> *> *)attributes
{
    [self tagLineWithAtrributes:tag attributes:attributes close:NO];
}

- (void)tagLineWithAtrributes:(NSString *)tag attributes:(nonnull NSArray<NSArray<NSString*> *> *)attributes close:(bool)close
{
    [self.xml appendString:@"<"];
    [self.xml  appendString:tag];
    
    for (NSArray<NSString *> *atr in attributes)
    {
        [self.xml appendString:@" "];
        [self.xml appendString:atr.firstObject];
        [self.xml appendString:@"=\""];
        [self.xml appendString:atr.lastObject];
        [self.xml appendString:@"\""];
    }
    
    if (close) {
        [self.xml appendString:@"/>\n"];
    } else {
        [self.xml appendString:@">\n"];
    }
}

- (void)closeTag:(NSString *)tag
{
    [self.xml appendString:@"</"];
    [self.xml appendString:tag];
    [self.xml appendString:@">\n"];
}


- (NSString *)makeURLstring
{
    NSData *data = [self.xml dataUsingEncoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"data:text/plain;base64,%@", [data base64EncodedStringWithOptions:0]];
}

- (XMLQueryBlock)queryBlock
{
    return ^NSString * _Nonnull(TriMetXML * _Nonnull xml, NSString * _Nonnull query) {
        return self.makeURLstring;
    };
}

+ (XMLQueryBlock) queryBlockWithFileForClass:(NSDictionary<NSString *,NSString *> *)filesPerClass
{
    return ^NSString * _Nonnull(TriMetXML * _Nonnull xml, NSString * _Nonnull query) {
        NSString *name = NSStringFromClass([xml class]);
        NSString *file = filesPerClass[name];
        NSURL *myURL = [[NSBundle bundleForClass:[self class]] URLForResource: file withExtension:@"xml"];
        return myURL.absoluteString;
    };
}

@end
