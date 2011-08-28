//
//  LegShapeParser.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/31/10.
//  Copyright 2010. All rights reserved.
//

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

#import "LegShapeParser.h"
#import "debug.h"
#import "math.h"

@implementation ShapeCoord

@synthesize end = _end;
@synthesize coord = _coord;

- (CLLocationDegrees) latitude
{
	return _coord.latitude;
}


- (CLLocationDegrees) longitude
{
	return _coord.longitude;
}

- (void)setLatitude:(CLLocationDegrees)val
{
	_coord.latitude = val;
}

- (void)setLongitude:(CLLocationDegrees)val
{
	_coord.longitude = val;
}

- (id)init
{
	if ((self = [super init]))
	{
		self.end = false;
	}
	return self;
}

+ (ShapeCoord*) makeEnd
{
	ShapeCoord *newEnd = [[[ShapeCoord alloc] init] autorelease];
	newEnd.end = true;
	return newEnd;
}

@end



@implementation LegShapeParser

@synthesize shapeCoords = _shapeCoords;
@synthesize lineURL = _lineURL;

- (void)dealloc
{
	self.lineURL = nil;
	self.shapeCoords = nil;
	[super dealloc];
}

- (void)fetchCoords
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
	NSMutableString *query = [[[ NSMutableString alloc] initWithString:self.lineURL] autorelease];
	
	// The "URL" initially looks like this - we need to remove the transweb part and add the trimet part
	// /transweb/ws/V1/BlockGeoWS/appID/xxxxx/bksTsIDeTeID/3305,X,11:21 AM,15,11:58 AM,7751

	[query deleteCharactersInRange:NSMakeRange(0,9)];  // /transweb is 9 characters
	
	[self fetchDataAsynchronously:[[NSString stringWithFormat:@"http://developer.trimet.org%@", query] 
										stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	if (self.dataComplete && self.rawData)
	{
		NSString * data = [[[NSString alloc] initWithData:self.rawData encoding:NSUTF8StringEncoding] autorelease];
		self.rawData = nil;
		
		NSScanner *scanner = [NSScanner scannerWithString:data];
		
		[scanner scanUpToString:@"points" intoString:nil];
		
		if ([scanner isAtEnd])
		{
			DEBUG_LOG(@"No points\n");
			return;
		}
		
		[scanner scanUpToString:@"[" intoString:nil];
		
		if ([scanner isAtEnd])
		{
			DEBUG_LOG(@"No [\n");
			return;
		}
		
		self.shapeCoords = [[[NSMutableArray alloc] init] autorelease];
		
		NSString *axis = nil;
		NSString *xy = nil;
		CLLocationDegrees xCoord = 0.0;
		CLLocationDegrees yCoord = 0.0;
		ShapeCoord *coord = nil;
		
		//
		// We are parsing a file that looks like this:
		// {"results": [{
		//	"sid": 15,
		//	"start": 40860,
		//	"block": "3305",
		//	"points":  [
		//				{
		//					"y": 634104.45,
		//					"x": 7661130.07
		//				},
		//				{
		//					"y": 634120,
		//					"x": 7661121
		//				}
		//				],
		//	"eid": 7751,
		//	"end": 43080,
		//	"key": "X"
		// }]}
		//
		//
		// So we extract the {} block that contains each x,y coord, then extract the coord from that
		// string, not assuming if x or y comes first.
		//
		while (![scanner isAtEnd] && [scanner scanUpToString:@"{" intoString:nil])
		{
			if (![scanner isAtEnd])
			{
				coord = [[[ShapeCoord alloc] init] autorelease];
				
				[scanner scanUpToString:@"}" intoString:&xy];
			}
			
			if (![scanner isAtEnd])
			{
				NSScanner *xyscanner = [NSScanner scannerWithString:xy];
				
				while (![xyscanner isAtEnd] && [xyscanner scanUpToString:@"\"" intoString:nil])
				{
					if (![xyscanner isAtEnd])
					{
						[xyscanner scanUpToString:@":" intoString:&axis];
						
						if (![xyscanner isAtEnd])
						{
							[xyscanner setScanLocation:xyscanner.scanLocation+1];
							unichar c = [axis characterAtIndex:1];
							if ((c == 'x' || c == 'X'))
							{
								[xyscanner scanDouble:&xCoord];
							}
							else {
								[xyscanner scanDouble:&yCoord];
							}
							
						}
					}
				}
				//
				// The data is in the Oregon State Plane North (OSPN) projection.
				// Frank Purcell has provided the math to convert this to lat and lng in http://groups.google.com/group/transit-developers-pdx
				//
				coord.longitude = +((((atan(((xCoord*0.3048)-2500000)/(6350713.93-((yCoord*0.3048)-166910.7663))))*180)/(3.14159265359*0.709186016884))-120.5);
				coord.latitude = (45.1687259619+((((yCoord*0.3048)-166910.7663)-(((xCoord*0.3048)-2500000)*tan((atan(((xCoord*0.3048)-2500000)/(6350713.93-((yCoord*0.3048)-166910.7663))))/2)))*(0.000008999007999+(((yCoord*0.3048)-166910.7663)-(((xCoord*0.3048)-2500000)*tan((atan(((xCoord*0.3048)-2500000)/(6350713.93-((yCoord*0.3048)-166910.7663))))/2)))*(-7.1202E-015+(((yCoord*0.3048)-166910.7663)-(((xCoord*0.3048)-2500000)*tan((atan(((xCoord*0.3048)-2500000)/(6350713.93-((yCoord*0.3048)-166910.7663))))/2)))*(-3.6863E-020+(((yCoord*0.3048)-166910.7663)-(((xCoord*0.3048)-2500000)*tan((atan(((xCoord*0.3048)-2500000)/(6350713.93-((yCoord*0.3048)-166910.7663))))/2)))*-1.3188E-027)))));
				[self.shapeCoords addObject:coord];
			}
		
		}	
	}
	[pool release];
	
}

@end
