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


#import <UIKit/UIKit.h>
#import "TriMetInfo.h"


#define MAXHOTSPOTS    278
#define MAXSTRIPES     40

#define kLinkTypeHttp  'h'
#define kLinkTypeWiki  'w'
#define kLinkTypeStop  's'
#define kLinkTypeNorth 'n'
#define kLinkType1     '1'
#define kLinkType2     '2'
#define kLinkType3     '3'
#define kLinkTypeDir   'd'
#define kLinkTypeMap   'm'
#define kLinkTypeTest  't'

typedef struct HotSpotStruct {
    union {
        const CGPoint *vertices;
        const CGRect *rect;
    } coords;
    NSString *action;
    unsigned char nVertices : 6;
    unsigned char touched  : 1;
    unsigned char isRect   : 1;
} HotSpot;

#define HOTSPOT_IS_RECT(X) ((X)->isRect == 1)
#define HOTSPOT_IS_POLY(X) ((X)->isRect == 0)
#define HOTSPOT_HIT(HS, P) (     ((HOTSPOT_IS_POLY(HS) && [PointInclusionInPolygonTest  pnpoly:(HS)->nVertices points:(HS)->coords.vertices x:(P).x y:(P).y]) \
                             ||  (HOTSPOT_IS_RECT(HS) && CGRectContainsPoint(*HS->coords.rect, (P)))))

#define MAP_LAST_INDEX 0xFF


typedef struct AlphaSectionsStruct {
    const char *title;
    int offset;
    int items;
} AlphaSections;

typedef const unsigned char ConstHotSpotIndex;
typedef unsigned char HotSpotIndex;


typedef struct StopInfoStruct {
    unsigned long stopId;
    int hotspot;
    double lat;
    double lng;
    bool tp;
    RailLines lines;
} StopInfo;

typedef struct RailMapTileStruct {
    ConstHotSpotIndex *hotspots;
}  RailMapTile;

typedef struct RailMapStruct {
    NSString *title;
    NSString *fileName;
    CGSize size;
    int firstHotspot;
    int lastHotspot;
    int xTiles;
    int yTiles;
    
    RailMapTile **tiles;
    
    CGSize tileSize;
} RailMap;

#define kRailMapMaxWes       0
#define kRailMapPdxStreetcar 1
#define kRailMaps            2


#define MAXCOLORS            1
