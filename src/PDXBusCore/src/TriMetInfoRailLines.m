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


#include "TriMetInfoRailLines.h"
#include "NSString+Helper.h"

#define DEBUG_LEVEL_FOR_FILE kLogDataManagement

static NSString *allTriMetCircularRoutes = @"18";


#define RGB(R, G, B) (((((R) & 0xFF) << 16) | (((G) & 0xFF) << 8) | ((B) & 0xFF)))
#define RGB_RED   RGB(255,  0,  0)
#define RGB_WHITE RGB(255, 255, 255)

// These must be in route order and the line bits also in order so a binary search works on either!
// uncrustify-off
static const RouteInfo allTriMetRailLines[] =
{//   Route     Route Bit      Op Dir Interline HTML Color  Back color  Wiki                            Name                            Short name    Streetcar Order   Phase   Pattern     Keywords            Has Stops       Optional in data
    { 90,       (0x1 << 0),    kDir1, kNoRoute, 0xD81526,   RGB_WHITE,  @"MAX_Red_Line",                @"MAX Red Line",                @"MAX",       NO,       3,      0,      2,          @"red",             YES,            NO         },   // Red line
    { 100,      (0x1 << 1),    kDir1, kNoRoute, 0x084C8D,   RGB_RED,    @"MAX_Blue_Line",               @"MAX Blue Line",               @"MAX",       NO,       0,      0.5,    2,          @"blue",            YES,            NO         },   // Blue Line
    { 190,      (0x1 << 2),    kDir1, 290,      0xF8C213,   RGB_RED,    @"MAX_Yellow_Line",             @"MAX Yellow Line",             @"MAX",       NO,       4,      1.0,    2,          @"yellow",          YES,            NO         },   // Yellow line
    { 193,      (0x1 << 3),    kDir1, kNoRoute, 0x84BD00,   RGB_WHITE,  @"Portland_Streetcar",          @"Portland Streetcar - NS Line",@"NS Line",   YES,      6,      0,      2,          @"ns,north south",  YES,            NO         },   // Streetcar Green
    { 194,      (0x1 << 4),    195,   kNoRoute, 0xCE0F69,   RGB_WHITE,  @"Portland_Streetcar",          @"Portland Streetcar - A Loop", @"A Loop",    YES,      7,      1.5,    2,          @"a loop,clockwise",YES,            NO         },   // Streetcar Blue
    { 195,      (0x1 << 5),    194,   kNoRoute, 0x0093B2,   RGB_WHITE,  @"Portland_Streetcar",          @"Portland Streetcar - B Loop", @"B Loop",    YES,      8,      2,      2,          @"b loop,counter",  YES,            NO         },   // Streetcar Pink
    { 200,      (0x1 << 6),    kDir1, kNoRoute, 0x008852,   RGB_WHITE,  @"MAX_Green_Line",              @"MAX Green Line",              @"MAX",       NO,       1,      1.75,   2,          @"green",           YES,            NO         },   // Green Line
    { 203,      (0x1 << 7),    kDir1, kNoRoute, 0x000000,   RGB_WHITE,  @"Westside_Express_Service",    @"WES Commuter Rail",           @"WES",       NO,       5,      0,      1,          @"wes,westside",    YES,            NO         },   // WES Black
    { 208,      (0x1 << 8),    kDir1, kNoRoute, 0x898E91,   RGB_WHITE,  @"Portland_Aerial_Tram",        @"Portland Aerial Tram",        @"Tram",      NO,       9,      0,      2,          @"tram",            NO,             YES        },   // Portland Aerial Tram
    { 290,      (0x1 << 9),    kDir1, 190,      0xF58220,   RGB_WHITE,  @"MAX_Orange_Line",             @"MAX Orange Line",             @"MAX",       NO,       2,      1.75,   2,          @"orange",          YES,            NO         },   // MAX Orange
    { kNoRoute,  0x0,          kNoDir,kNoRoute, 0x000000,   RGB_WHITE,  nil,                            nil,                            nil,          NO,       9,      0,      0,          nil,                NO,             NO         }    // Terminator
};


PtrConstRouteInfo getAllTriMetRailLines()
{
    return &(allTriMetRailLines[0]);
}

size_t noOfTriMetRailLines()
{
    return ((sizeof(allTriMetRailLines) / sizeof(allTriMetRailLines[0])) - 1);
}

int compareRouteNumber(const void *first, const void *second) {
    return (int)(((RouteInfo *)first)->route_number - ((RouteInfo *)second)->route_number);
}

int compareRouteLineBit(const void *first, const void *second) {
    return (int)((int)((RouteInfo *)first)->line_bit - (int)((RouteInfo *)second)->line_bit);
}



NSSet<NSString *>* getAllTriMetCircularRoutes(void)
{
    static NSSet<NSString *> *loops;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        loops = [NSSet setWithArray:allTriMetCircularRoutes.mutableArrayFromCommaSeparatedString];
    });
    
    return loops;
}
