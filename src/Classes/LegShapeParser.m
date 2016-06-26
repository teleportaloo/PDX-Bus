//
//  LegShapeParser.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/31/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "LegShapeParser.h"
#import "DebugLogging.h"
#import "math.h"
#import "UserPrefs.h"

#define END_LAT 2000

@implementation ShapeCoord

@dynamic end;
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

- (bool)end
{
    return _coord.latitude >= END_LAT;
}

- (void)setEnd:(bool)end
{
    if (end)
    {
        _coord.latitude = END_LAT;
    }
    else
    {
        _coord.latitude = 0;
    }
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
	
	[self fetchDataByPolling:[[NSString stringWithFormat:@"%@://developer.trimet.org%@",
                                                [UserPrefs getSingleton].triMetProtocol, query]
										stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	if (self.dataComplete && self.rawData)
	{
		NSString * data = [[[NSString alloc] initWithData:self.rawData encoding:NSUTF8StringEncoding] autorelease];
		self.rawData = nil;
        
        DEBUG_LOG(@"Data: %@\n", data);
        
		
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
							xyscanner.scanLocation++;
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
                
                if (coord!=nil)
                {
                    coord.longitude = +((((atan(((xCoord*0.3048)-2500000)/(6350713.93-((yCoord*0.3048)-166910.7663))))*180)/(3.14159265359*0.709186016884))-120.5);
                    coord.latitude = (45.1687259619+((((yCoord*0.3048)-166910.7663)-(((xCoord*0.3048)-2500000)*tan((atan(((xCoord*0.3048)-2500000)/(6350713.93-((yCoord*0.3048)-166910.7663))))/2)))*(0.000008999007999+(((yCoord*0.3048)-166910.7663)-(((xCoord*0.3048)-2500000)*tan((atan(((xCoord*0.3048)-2500000)/(6350713.93-((yCoord*0.3048)-166910.7663))))/2)))*(-7.1202E-015+(((yCoord*0.3048)-166910.7663)-(((xCoord*0.3048)-2500000)*tan((atan(((xCoord*0.3048)-2500000)/(6350713.93-((yCoord*0.3048)-166910.7663))))/2)))*(-3.6863E-020+(((yCoord*0.3048)-166910.7663)-(((xCoord*0.3048)-2500000)*tan((atan(((xCoord*0.3048)-2500000)/(6350713.93-((yCoord*0.3048)-166910.7663))))/2)))*-1.3188E-027)))));
                    [self.shapeCoords addObject:coord];
                }
			}
		
		}	
	}
	[pool release];
	
}

@end
