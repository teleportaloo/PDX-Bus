//
//  Hotspots.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/4/10.
//  Copyright 2010 Intel. All rights reserved.
//

#import <Foundation/Foundation.h>

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

#define MAXHOTSPOTS 137

@interface Hotspot : NSObject {
	int _index;
}

@property (readonly) (int)index;
@property (readonly) (char)type;
@property (readonly) (HOTSPOT*)hotspot;

+ (Hotspot*)createFromHotspot:(int)index;
+ (Hotspot*)matchTapX:(CGFloat)x Y:(CGFloat)y;

@end


#pragma mark WikiHotspot
@interface StationHotspot: WikiHotspot
{
	NSString *_wiki;
}
@property (retain, nonatomic) NSString *wiki;

@end

#pragma mark StationHotspot
@interface StationHotspot: Hotspot
{
	NSString *_name;
	NSString *_wiki;
	NSMutableArray *_locs;
	NSMutableArray *_dirs;
}

@property (retain, nonatomic) NSString *name;
@property (retain, nonatomic) NSString *wiki;
@property (retain, nonatomic) NSMutableArray *locs;
@property (retain, nonatomic) NSMutableArray *dirs;

@end

#pragma mark DirectionHotspot
@interface StationHotspot: Hotspot
{
	NSString *_route;
}

@property (retain, nonatomic) NSString *_route;

@end




