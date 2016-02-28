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
#import "TriMetRouteColors.h"


#define MAXHOTSPOTS 278
#define MAXSTRIPES   40

#define kLinkTypeHttp	'h'
#define kLinkTypeWiki	'w'
#define kLinkTypeStop	's'
#define kLinkTypeNorth	'n'
#define kLinkType1		'1'
#define kLinkType2		'2'
#define kLinkType3		'3'
#define kLinkTypeDir	'd'
#define kLinkTypeMap    'm'

typedef struct hotspot_struct
{
    union
    {
        const CGPoint *vertices;
        const CGRect  *rect;
    } coords;
    const char *    action;
	unsigned char   nVertices: 6;
    unsigned char   touched  : 1;
    unsigned char   isRect   : 1;
} HOTSPOT;

#define HOTSPOT_IS_RECT(X) ((X)->isRect==1)
#define HOTSPOT_IS_POLY(X) ((X)->isRect==0)

#define MAP_LAST_INDEX 0xFF


typedef struct alpha_section_struct
{
	char *title;
	int offset;
	int items;
} ALPHA_SECTIONS;

typedef unsigned char HOTSPOT_INDEX;

typedef struct tile_array
{
    HOTSPOT_INDEX *hotspots;
}  RAILMAP_TILE;

typedef struct railmap_struct
{
    NSString *title;
    NSString *fileName;
    CGSize   size;
    int      firstHotspot;
    int      lastHotspot;
    int      xTiles;
    int      yTiles;
    
    RAILMAP_TILE **tiles;
    
    CGSize   tileSize;

} RAILMAP;
   
#define kRailMapMaxWes          0
#define kRailMapPdxStreetcar    1
#define kRailMaps               2


#define MAXCOLORS  1
