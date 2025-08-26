/*
 *  HotSpot.h
 *  PDX Bus
 *
 *  Created by Andrew Wallace on 10/4/10.
 *  Copyright 2010. All rights reserved.
 *
 */



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetInfo.h"

#define MAXHOTSPOTS 278
#define MAXSTRIPES 40

#define kLinkTypeHttp 'h'
#define kLinkTypeWiki 'w'
#define kLinkTypeStop 's'
#define kLinkTypeNorth 'n'
#define kLinkType1 '1'
#define kLinkType2 '2'
#define kLinkType3 '3'
#define kLinkTypeDir 'd'
#define kLinkTypeMap 'm'
#define kLinkTypeTest 't'

typedef struct HotSpotStruct {
    const union {
        const CGPoint *vertices;
        const CGRect *rect;
    } coords;
    NSString *action;
    unsigned const char nVertices;
    unsigned const char isRect;
    unsigned const char nMap;
} HotSpot;

#define HS_ACTION(HS) ((HS).action)
#define HS_TYPE(HS) (HS_ACTION(HS).firstUnichar)

typedef const HotSpot ConstHotSpot;
typedef ConstHotSpot *PtrConstHotSpot;

#define HOTSPOT_IS_RECT(X) ((X)->isRect == 1)
#define HOTSPOT_IS_POLY(X) ((X)->isRect == 0)
#define HOTSPOT_HIT(HS, P)                                                     \
    (((HOTSPOT_IS_POLY(HS) &&                                                  \
       [PointInclusionInPolygonTest pnpoly:(HS)->nVertices                     \
                                    points:(HS)->coords.vertices               \
                                         x:(P).x                               \
                                         y:(P).y]) ||                          \
      (HOTSPOT_IS_RECT(HS) && CGRectContainsPoint(*HS->coords.rect, (P)))))

#define MAP_END 0xFF

typedef const unsigned char ConstHotSpotIndex;
typedef unsigned char HotSpotIndex;

typedef struct StopInfoStruct {
    unsigned long stopId;
    int hotspot;
    double lat;
    double lng;
    bool tp;
    TriMetInfo_ColoredLines lines;
} StopInfo;

typedef struct RailMapHotSpotsStruct {
    int first;
    int last;
} RailMapHotSpots;

typedef struct RailMapTileStruct {
    ConstHotSpotIndex *hotspots;
} RailMapTile;

typedef struct RailMapStruct {
    NSString *title;
    NSString *fileName;
    CGSize size;
    const RailMapHotSpots *hotSpots;
    int xTiles;
    int yTiles;
    const RailMapTile **tiles;
    CGSize tileSize;
} RailMap;

typedef const RailMap *PtrConstRailMap;

#define kRailMapMaxWes 0
#define kRailMapPdxStreetcar 1
#define kRailMaps 2

@interface HotSpotArrays : NSObject

+ (instancetype)sharedInstance;

- (PtrConstHotSpot)hotSpots;
- (int)hotSpotCount;
- (PtrConstRailMap)railMaps;

@end
