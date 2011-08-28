/*
 *  HotSpot.h
 *  PDX Bus
 *
 *  Created by Andrew Wallace on 10/4/10.
 *  Copyright 2010. All rights reserved.
 *
 */

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */


#define MAXHOTSPOTS 190

#define kLinkTypeHttp	'h'
#define kLinkTypeWiki	'w'
#define kLinkTypeStop	's'
#define kLinkTypeNorth	'n'
#define kLinkType1		'1'
#define kLinkType2		'2'
#define kLinkType3		'3'
#define kLinkTypeDir	'd'

typedef struct hotspot_struct
{
	const CGPoint *vertices;
	int	nVertices;
	const char *action;
	bool touched;
} HOTSPOT;


#define kRedLine    0x0001
#define kBlueLine   0x0002
#define kGreenLine  0x0004
#define kYellowLine 0x0008
#define kWesLine    0x0010
#define kStreetcarLine	0x0020

typedef int RAILLINES;

typedef struct alpha_section_struct
{
	char title;
	int offset;
	int items;
} ALPHA_SECTIONS;

// #define CREATE_MAX_ARRAYS 1
#define MAXCOLORS  1