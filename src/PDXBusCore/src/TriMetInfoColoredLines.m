//
//  TriMetInfoRailLines.c
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#include "TriMetInfoColoredLines.h"
#import "CLLocation+Helper.h"
#include "HotSpot.h"
#import "HotSpot.h"
#include "NSString+Core.h"
#import "RailStation.h"
#import "TaskDispatch.h"

#define DEBUG_LEVEL_FOR_FILE LogData

static NSString *allTriMetCircularRoutes = @"18";

#define RGB(R, G, B)                                                           \
    (((((R) & 0xFF) << 16) | (((G) & 0xFF) << 8) | ((B) & 0xFF)))
#define RGB_RED RGB(255, 0, 0)
#define RGB_WHITE RGB(255, 255, 255)

// These must be in route order and the line bits also in order so a binary
// search works on either!
// clang-format off
// uncrustify-off
static const TriMetInfo_Route allTriMetRailLines[] =
{//   Route     Route Bit      Op Dir Interline HTML Color  Back color  Outline         Wiki                            Name                            Short name    Tiny      Type              Order   Phase   Pattern Keywords            Rail Stop Optional in data
    { 2,        (0x1 << 0),    kDir1, kNoRoute, 0x61A744,   RGB_WHITE,  RGB_WHITE,      @"Frequent_Express",            @"FX2-Division",                @"FX2",       @"FX2",   LineTypeBus,      500,      0,      2,      @"fx,fx2",          NO,       NO    },   // FX2
    { 90,       (0x1 << 1),    kDir1, kNoRoute, 0xC41F3E,   RGB_WHITE,  RGB_SAME,       @"MAX_Red_Line",                @"MAX Red Line",                @"MAX",       @"Red",   LineTypeMAX,      130,      0,      2,      @"red",             YES,      NO    },   // Red line
    { 100,      (0x1 << 2),    kDir1, kNoRoute, 0x114c96,   RGB_RED,    RGB_SAME,       @"MAX_Blue_Line",               @"MAX Blue Line",               @"MAX",       @"Blu",   LineTypeMAX,      100,      0.5,    2,      @"blue",            YES,      NO    },   // Blue line
    { 190,      (0x1 << 3),    kDir1, 290,      0xffc52f,   RGB_RED,    RGB_SAME,       @"MAX_Yellow_Line",             @"MAX Yellow Line",             @"MAX",       @"Yel",   LineTypeMAX,      140,      1.0,    2,      @"yellow",          YES,      NO    },   // Yellow line
    { 193,      (0x1 << 4),    kDir1, kNoRoute, 0x8DC63F,   RGB_WHITE,  RGB_SAME,       @"Portland_Streetcar",          @"Portland Streetcar - NS Line",@"NS Line",   @"NS",    LineTypeStreetcar,200,      0,      2,      @"ns,north south",  YES,      NO    },   // Streetcar Green
    { 194,      (0x1 << 5),    195,   kNoRoute, 0xD91965,   RGB_WHITE,  RGB_SAME,       @"Portland_Streetcar",          @"Portland Streetcar - A Loop", @"A Loop",    @"A",     LineTypeStreetcar,250,      1.5,    2,      @"a loop,clockwise",YES,      NO    },   // Streetcar Blue
    { 195,      (0x1 << 6),    194,   kNoRoute, 0x32398E,   RGB_WHITE,  RGB_SAME,       @"Portland_Streetcar",          @"Portland Streetcar - B Loop", @"B Loop",    @"B",     LineTypeStreetcar,275,      2,      2,      @"b loop,counter",  YES,      NO    },   // Streetcar Pink
    { 200,      (0x1 << 7),    kDir1, kNoRoute, 0x008342,   RGB_WHITE,  RGB_SAME,       @"MAX_Green_Line",              @"MAX Green Line",              @"MAX",       @"Gre",   LineTypeMAX,      110,      1.75,   2,      @"green",           YES,      NO    },   // Green Line
    { 203,      (0x1 << 8),    kDir1, kNoRoute, 0x6E6E6E,   RGB_WHITE,  RGB_WHITE,      @"Westside_Express_Service",    @"WES Commuter Rail",           @"WES",       @"WES",   LineTypeMAX,      150,      0,      1,      @"wes,westside",    YES,      NO    },   // WES Black
    { 208,      (0x1 << 9),    kDir1, kNoRoute, 0x898E91,   RGB_WHITE,  RGB_SAME,       @"Portland_Aerial_Tram",        @"Portland Aerial Tram",        @"Tram",      @"Trm",   LineTypeTram,     300,      0,      2,      @"tram",            NO,       YES   },   // Portland Aerial Tram
    { 287,      (0x1 << 10),   kDir1, kNoRoute, 0x114c96,   RGB_RED,    RGB_SAME,       @"MAX_Blue_Line",               @"287-Blue Eastside Bus",       @"287",       @"287",   LineTypeMAXBus,   9750,     0,      2,      @"bus",             NO,       YES   },   // Blue Eastside Bus
    { 288,      (0x1 << 11),   kDir1, kNoRoute, 0x114c96,   RGB_RED,    RGB_SAME,       @"MAX_Blue_Line",               @"288-Blue Westside Bus",       @"288",       @"288",   LineTypeMAXBus,   9800,     0,      2,      @"bus",             NO,       YES   },   // Blue Westside Bus
    { 290,      (0x1 << 12),   kDir1, 190,      0xD05F27,   RGB_WHITE,  RGB_SAME,       @"MAX_Orange_Line",             @"MAX Orange Line",             @"MAX",       @"Ora",   LineTypeMAX,      120,      1.75,   2,      @"orange",          YES,      NO    },   // MAX Orange
    { 291,      (0x1 << 13),   kDir1, kNoRoute, 0xD05F27,   RGB_WHITE,  RGB_SAME,       @"MAX_Orange_Line",             @"291-Orange Bus",              @"291",       @"291",   LineTypeMAXBus,   9850,     0,      2,      @"bus",             NO,       YES   },   // Orange Bus
    { 292,      (0x1 << 14),   kDir1, kNoRoute, 0xC41F3E,   RGB_WHITE,  RGB_SAME,       @"MAX_Red_Line",                @"292-Red Bus",                 @"292",       @"292",   LineTypeMAXBus,   9900,     0,      2,      @"bus",             NO,       YES   },   // Red Bus
    { 293,      (0x1 << 15),   kDir1, kNoRoute, 0xffc52f,   RGB_RED,    RGB_SAME,       @"MAX_Yellow_Line",             @"293-Yellow Bus",              @"293",       @"293",   LineTypeMAXBus,   9950,     0,      2,      @"bus",             NO,       YES   },   // Yellow Bus
    { kNoRoute,  0x0,          kNoDir,kNoRoute, 0x000000,   RGB_WHITE,  RGB_SAME,       nil,                            nil,                            nil,          nil,      LineTypeMAX,      0,        0,      0,      nil,                NO,       NO    }    // Terminator
};
// clang-format on

int TriMetInfo_compareRouteNumber(const void *first, const void *second) {
    return (int)(((TriMetInfo_Route *)first)->route_number -
                 ((TriMetInfo_Route *)second)->route_number);
}

int TriMetInfo_compareRouteLineBit(const void *first, const void *second) {
    return (int)((int)((TriMetInfo_Route *)first)->line_bit -
                 (int)((TriMetInfo_Route *)second)->line_bit);
}

int TriMetInfo_compareSortOrder(const void *first, const void *second) {
    return (int)((int)((TriMetInfo_Route *)first)->sort_order -
                 (int)((TriMetInfo_Route *)second)->sort_order);
}

@implementation TriMetInfoColoredLines

+ (PtrConstRouteInfo)allLines {
    return &(allTriMetRailLines[0]);
}

+ (size_t)numOfLines {
    return ((sizeof(allTriMetRailLines) / sizeof(allTriMetRailLines[0])) - 1);
}

+ (NSSet<NSString *> *)allCircularRoutes {
    static NSSet<NSString *> *loops;

    DoOnce(^{
      loops = [NSSet setWithArray:allTriMetCircularRoutes
                                      .mutableArrayFromCommaSeparatedString];
    });

    return loops;
}

@end
