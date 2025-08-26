//
//  HotSpot.c
//  PDX Bus
//
//  Created by Andy Wallace on 3/6/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//


/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#include "HotSpot.h"
#import "DebugLogging.h"
#import "PDXBusCore.h"
#import "StationData.h"
#import "TaskDispatch.h"
#include <Foundation/Foundation.h>

#define DEBUG_LEVEL_FOR_FILE LogData

#ifndef GENERATE_ARRAYS
#define GENERATED_ARRAY(X) (X)
#else
#define GENERATED_ARRAY(X) (NULL)
#endif

@implementation HotSpotArrays

- (PtrConstHotSpot)hotSpots {
    return &hotSpotRegions[0];
}

- (int)hotSpotCount {
    return sizeof(hotSpotRegions) / sizeof(hotSpotRegions[0]);
}

- (PtrConstRailMap)railMaps {
    return &railmaps[0];
}

+ (HotSpotArrays *)sharedInstance {
    static HotSpotArrays *singleton = nil;

    DoOnce(^{
      singleton = [[HotSpotArrays alloc] init];
    });

    return singleton;
}

- (instancetype)init {
    if ((self = [super init])) {
    }
    return self;
}

+ (void)initialize {
    DEBUG_BLOCK(^{
      DoOnce(^{
        DEBUG_LOG_long(sizeof(HotSpot));

        int i;
        size_t sz = 0;

        size_t nHotSpots = sizeof(hotSpotRegions) / sizeof(hotSpotRegions[0]);

        for (i = 0; i < nHotSpots; i++) {
            PtrConstHotSpot hs = &(hotSpotRegions[i]);

            if (hs->isRect) {
                sz += sizeof(CGRect);
            } else {
                sz += sizeof(CGPoint) * hs->nVertices;
            }

            sz += HS_ACTION(*hs).length + 1;
            sz += sizeof(hotSpotRegions);
        }

        DEBUG_LOG(@"Hotspot database size %ld\n", (long)sz);
      });
    });
}

// Helper macros to construct the static tables
#define HS_BRACES(...) __VA_ARGS__

// This was suggested by ChatGPT, we create a name based on the line number
// We will import headers several times defining the macros differently but
// this will remain constant when it is used so works to create a nice
// unique name.
//
// First... concat three symbols
#define CAT3_IMPL(a, b, c) a##b##c
#define CAT3(a, b, c) CAT3_IMPL(a, b, c)

// Now constuct a unique name from the prefix, map and line no
#define UNIQUE_LINE_NO_NAME(prefix) CAT3(prefix, HS_MAP, __LINE__)

#define CAT2_IMPL(a, b) a##b
#define CAT2(a, b) CAT2_IMPL(a, b)

//------------------------------------------------------------------------------
#pragma mark HOT SPOTS
//------------------------------------------------------------------------------

//-----------------------------------------------------------------------------
#pragma mark PASS 1 - create static arrays of vertices and rects
//------------------------------------------------------------------------------
// We use the line number and the map number to create a unique static array
// name for the virtices or rects
#define HS_POLY(P, STR)                                                        \
    static const CGPoint UNIQUE_LINE_NO_NAME(_pts_)[] = {HS_BRACES P};

#define HS_RECT(X1, Y1, X2, Y2, STR)                                           \
    static const CGRect UNIQUE_LINE_NO_NAME(_rect_)[] = {                      \
        (X1), (Y1), (X2) - (X1), (Y2) - (Y1)};

#include "HotSpotTables.h"

#undef HS_POLY
#undef HS_RECT

//-----------------------------------------------------------------------------
#pragma mark PASS 2 - create static hotspot array
//------------------------------------------------------------------------------
// The polygons and rects from the HTML become static arrays of vertices

#define HS_POLY(P, STR)                                                        \
    (const HotSpot) {                                                          \
        .coords.vertices = UNIQUE_LINE_NO_NAME(_pts_), .isRect = 0,            \
        .nVertices = sizeof(UNIQUE_LINE_NO_NAME(_pts_)) /                      \
                     sizeof(UNIQUE_LINE_NO_NAME(_pts_)[0]),                    \
        .action = @STR, .nMap = HS_MAP                                         \
    }                                                                          \
    ,

#define HS_RECT(X1, Y1, X2, Y2, STR)                                           \
    (const HotSpot) {                                                          \
        .coords.rect = UNIQUE_LINE_NO_NAME(_rect_), .isRect = 1,               \
        .nVertices = 4, .action = @STR, .nMap = HS_MAP                         \
    }                                                                          \
    ,

static const HotSpot hotSpotRegions[] = {

#include "HotSpotTables.h"

};

//------------------------------------------------------------------------------
#pragma mark TILING
// The tiles are used to optimize the search when the user taps on the map
//------------------------------------------------------------------------------

#ifndef GENERATE_ARRAYS
static ConstHotSpotIndex noHotspots[] = {MAP_END};
#endif

//------------------------------------------------------------------------------
#pragma mark PASS 1 - create static arrays of hotspot indexes for each tile
//------------------------------------------------------------------------------

#define MAP_TILE_STATIC_ARRAY(SZ)
#define MAP_TILE_STATIC_END_ARRAY

#define MAP_TILE_STATIC_ROW(X, SZ)
#define MAP_TILE_STATIC_END_ROW

#define MAP_TILES(X, Y, A)                                                     \
    static ConstHotSpotIndex UNIQUE_LINE_NO_NAME(_hotspots_)[] = {HS_BRACES A, \
                                                                  MAP_END};
#define MAP_NONE(X, Y)

#include "HotSpotTileTables.h"

#undef MAP_TILE_STATIC_ARRAY
#undef MAP_TILE_STATIC_END_ARRAY
#undef MAP_TILE_STATIC_ROW
#undef MAP_TILE_STATIC_END_ROW
#undef MAP_TILES
#undef MAP_NONE

//-----------------------------------------------------------------------------
#pragma mark PASS 2 - create static arrays of rows for the above arrays per tile
//------------------------------------------------------------------------------
#define MAP_TILE_STATIC_ARRAY(SZ)
#define MAP_TILE_STATIC_END_ARRAY

#define MAP_TILE_STATIC_ROW(X, SZ)                                             \
    static const RailMapTile UNIQUE_LINE_NO_NAME(_row_)[] = {
#define MAP_TILE_STATIC_END_ROW                                                \
    }                                                                          \
    ;

#define MAP_TILES(X, Y, A) UNIQUE_LINE_NO_NAME(_hotspots_),
#define MAP_NONE(X, Y) noHotspots,

#include "HotSpotTileTables.h"

#undef MAP_TILE_STATIC_ARRAY
#undef MAP_TILE_STATIC_END_ARRAY
#undef MAP_TILE_STATIC_ROW
#undef MAP_TILE_STATIC_END_ROW
#undef MAP_TILES
#undef MAP_NONE

//------------------------------------------------------------------------------
#pragma mark PASS 3 - make a big array of all the rows
// Give it a unique name of tiles + HS_MAP
//------------------------------------------------------------------------------
#define MAP_TILE_STATIC_ARRAY(SZ)                                              \
    static const RailMapTile *CAT2(tiles, HS_MAP)[] = {
#define MAP_TILE_STATIC_END_ARRAY                                              \
    }                                                                          \
    ;

#define MAP_TILE_STATIC_ROW(X, SZ) UNIQUE_LINE_NO_NAME(_row_),
#define MAP_TILE_STATIC_END_ROW

#define MAP_TILES(X, Y, A)
#define MAP_NONE(X, Y)

#include "HotSpotTileTables.h"

#undef MAP_TILE_STATIC_ARRAY
#undef MAP_TILE_STATIC_END_ARRAY
#undef MAP_TILE_STATIC_ROW
#undef MAP_TILE_STATIC_END_ROW
#undef MAP_TILES
#undef MAP_NONE

//------------------------------------------------------------------------------
#pragma mark Rail maps
//------------------------------------------------------------------------------

#define RAIL_MAP(TITLE, FILE, W, H, TX, TY, HS, T)                             \
    {                                                                          \
        @TITLE, @FILE, {W, H}, GENERATED_ARRAY(HS), TX, TY,                    \
            GENERATED_ARRAY(T), {                                              \
            (CGFloat) W / TX, (CGFloat)H / TY,                                 \
        }                                                                      \
    }

#ifndef GENERATE_ARRAYS
#define ONLY_RAILMAP_DATA
#import "../Tables/StaticStationData.c"
#endif

static const RailMap railmaps[] = {
    RAIL_MAP("MAX & WES Map", "MAXWESMap", 3000, 1700, 30, 15,
             &railMapHotSpots[0], tiles0),
    RAIL_MAP("Streetcar Map", "StreetcarMap", 1500, 2102, 15, 20,
             &railMapHotSpots[1], tiles1),
    {nil, 0, 0}};

@end
