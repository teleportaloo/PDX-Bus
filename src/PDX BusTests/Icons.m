//
//  Icons.m
//  PDX BusTests
//
//  Created by Andy Wallace on 9/2/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//

// Put these first
#import "DebugLogging.h"
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

// Formatter will put them after these which is a problem without the gap

#import "../Classes/BoxedIcon.h"
#import "../Classes/IconNames.h"
#import "../Classes/Icons.h"
#import "../Classes/LinkInfo.h"
#import "../PDXBusCore/src/DebugLogging.h"

#define DEBUG_LEVEL_FOR_FILE LogTests

// Or build a table from the .def:
typedef struct {
    NSString *const *sym;
    const char *symbolName;
    NSString *alt;
    bool sf;
} NamedIcon;

static const NamedIcon kIcons[] = {
#define ICON(X, S) {&X##Name, #X, NULL, NO},
#define SF_ICON(X, S) {&X##Name, #X, NULL, YES},
#define SF_ICON_TINT(X, S, C) SF_ICON(X, S)
#define SF_ICON_ALT(X, S, A) {&X##Name, #X, A, YES},
#define SF_ICON_ALT_TINT(X, S, A, C) SF_ICON_ALT(X, S, A)

#include "../Classes/IconNames.def"

#undef ICON
#undef SF_ICON
#undef SF_ICON_TINT
#undef SF_ICON_ALT
#undef SF_ICON_ALT_TINT

};

@interface TestIcons : XCTestCase

@end

@implementation TestIcons

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the
    // class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the
    // class.
}

- (void)testAllIconsLoad {

    DEBUG_HERE();

    for (size_t i = 0; i < sizeof kIcons / sizeof kIcons[0]; ++i) {
        NSString *name = *kIcons[i].sym;
        NSString *alt = kIcons[i].alt;

        if (kIcons[i].sf) {
            UIImage *img = [UIImage systemImageNamed:name];
            DEBUG_LOG(@"%s %@ %@", kIcons[i].symbolName, name, img);

            if (alt == nil) {
                XCTAssertNotNil(
                    img, @"Missing system image for %s -> %@", kIcons[i].symbolName, name);
            } else {
                if (img == nil) {
                    DEBUG_TEST_WARNING(
                        @"Missing system image for %s -> %@", kIcons[i].symbolName, name);
                }

                UIImage *img = [UIImage systemImageNamed:alt];
                DEBUG_LOG(@"%s %@ %@", kIcons[i].symbolName, alt, img);
                XCTAssertNotNil(
                    img, @"Missing system image for alt %s -> %@", kIcons[i].symbolName, alt);
            }
        } else {
            UIImage *img = [UIImage imageNamed:name];
            DEBUG_LOG(@"%s %@ %@", kIcons[i].symbolName, name, img);
            XCTAssertNotNil(img, @"Missing image for %s -> %@", kIcons[i].symbolName, name);
        }
    }
}

- (void)checkIcons:(NSArray *)about {
    for (NSDictionary *dict in about) {
        LinkInfo *info = dict.linkInfo;

        NSString *iconName = info.valLinkIcon;

        BoxedIcon *icon = [Icons assetOrSystemBoxedIcon:iconName];

        if (icon != nil) {
            UIImage *img = icon.image;
            DEBUG_LOG(@"%@ %@", iconName, img);
            XCTAssertNotNil(img, @"Missing image for %@", iconName);
        } else {
            XCTAssertNotNil(icon, @"Missing image for %@", iconName);
        }
    }
}

- (void)testAboutIcons {
    NSArray *plists = @[ @"about-links", @"about-other", @"about-legal" ];

    for (NSString *file in plists) {
        [self checkIcons:[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle]
                                                              pathForResource:file
                                                                       ofType:@"plist"]]];
    }
}

@end
