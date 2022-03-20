//
//  Links.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 5/9/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <XCTest/XCTest.h>
#import "LinkChecker.h"
#import "../Classes/WhatsNewWeb.h"

#define kLinkFull   @"LinkF"
#define kLinkMobile @"LinkM"
#define kIcon       @"Icon"
#define kCellText   @"Title"


@interface Links : XCTestCase

@property (atomic, strong) LinkChecker *linkChecker;

@end

@implementation Links

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.linkChecker = [LinkChecker withContext:NSSTR_FUNC];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    
    self.linkChecker = nil;
}

- (void)testAbout {
    NSArray *sut = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about-links" ofType:@"plist"]];
    
    self.linkChecker.context = NSSTR_FUNC;
    
    for(NSDictionary *dict in sut)
    {
        [self.linkChecker checkLink:dict[kLinkFull]];
        [self.linkChecker checkLink:dict[kLinkMobile]];
    }
    
    [self.linkChecker waitUntilDone];

}

- (void)testLegal {
    NSArray *sut = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about-legal" ofType:@"plist"]];
    
    self.linkChecker.context = NSSTR_FUNC;
    
    for(NSDictionary *dict in sut)
    {
        [self.linkChecker checkLink:dict[kLinkFull]];
        [self.linkChecker checkLink:dict[kLinkMobile]];
    }

    [self.linkChecker waitUntilDone];
}


- (void)testOtherLinks {
    NSDictionary<NSString *, NSDictionary*> *sut= [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"web-links" ofType:@"plist"]];
    
    self.linkChecker.context = NSSTR_FUNC;
    
    [sut enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSDictionary* _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *testString = obj[@"TestString"];
        NSString *testString2 = obj[@"TestString2"];
        
        NSString * full   = obj[kLinkFull];
        NSString * mobile = obj[kLinkMobile];
        
        if (full != nil && testString != nil && testString2 != nil) {
            full = [NSString stringWithFormat:full, testString, testString2];
        } else if (full != nil && testString != nil) {
            full = [NSString stringWithFormat:full, testString];
        }
        
        
        if (mobile != nil && testString != nil && testString2 != nil) {
            mobile = [NSString stringWithFormat:mobile, testString, testString2];
        } else if (mobile != nil && testString != nil) {
            mobile = [NSString stringWithFormat:mobile, testString];
        }
        
        [self.linkChecker checkLink:full];
        [self.linkChecker checkLink:mobile];
    }];


    [self.linkChecker waitUntilDone];
}


- (void)testWhatsNew {
    NSArray *sut =  [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"whats-new" ofType:@"plist"]];
    
    WhatsNewWeb *webAction =  [WhatsNewWeb action];
    
    self.linkChecker.context = NSSTR_FUNC;
    
    for(NSString *text in sut)
    {
        if ([WhatsNewWeb matches:text])
        {
            [self.linkChecker checkLink:[webAction prefix:text restOfText:nil]];
        }
    }
    
    [self.linkChecker waitUntilDone];
}



@end
