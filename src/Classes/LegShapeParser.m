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

@implementation ShapeObject

@end

@implementation ShapeCoord

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

- (instancetype)init
{
	if ((self = [super init]))
	{
		
	}
	return self;
}

@end

@implementation ShapeCoordEnd

@synthesize direct = _direct;
@synthesize color = _color;

-(void)dealloc
{
    self.color = nil;
    [super dealloc];
}

+ (ShapeCoordEnd*)makeDirect:(bool)direct color:(UIColor *)color
{
    ShapeCoordEnd *end = [ShapeCoordEnd data];
    end.direct  = direct;
    end.color   = color;
    
    return end;
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
    NSMutableString *query = [self.lineURL.mutableCopy autorelease];
    
    // The "URL" initially looks like this - we need to remove the transweb part and add the trimet part
    // /transweb/ws/V1/BlockGeoWS/appID/xxxxx/bksTsIDeTeID/3305,X,11:21 AM,15,11:58 AM,7751
    
    [query deleteCharactersInRange:NSMakeRange(0,9)];  // /transweb is 9 characters
    
    NSString *fullQuery = [NSString stringWithFormat:@"%@://developer.trimet.org%@",
                       [UserPrefs singleton].triMetProtocol, query];
    
    DEBUG_LOG(@"Query %@\n", fullQuery);
    
    [self fetchDataByPolling:[fullQuery stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    if (self.dataComplete && self.rawData)
    {
        // NSString * data = [[[NSString alloc] initWithData:self.rawData encoding:NSUTF8StringEncoding] autorelease];
        
        
        // DEBUG_LOG(@"Data: %@\n", data);
        
        
        //
        // We are parsing a JSON response that looks like this:
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
        NSError *error = 0;
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:self.rawData  options:0 error:&error];
        
        self.rawData = nil;
        
        NSDictionary *  response      = nil;
        NSArray *       results       = nil;
        NSDictionary *  firstResult   = nil;
        NSArray *       points        = nil;
        NSString *      errorMsg      = nil;
        
        if (error)
        {
            ERROR_LOG(@"Error parsing JSON: %@\n", error.localizedDescription);
        }
        else
        {
            response = json[@"response"];
        }
        
#define EXPECTED_CLASS(X,C) ((X) && [(X) isKindOfClass:[C class]])
        
        if (EXPECTED_CLASS(response, NSDictionary))
        {
            results = response[@"results"];
        }
        
        if (EXPECTED_CLASS(results, NSArray))
        {
            firstResult = results.firstObject;
        }
        
        if (EXPECTED_CLASS(firstResult, NSDictionary))
        {
            points =   firstResult[@"points"];
            errorMsg = firstResult[@"error"];
        }
        
        if (EXPECTED_CLASS(errorMsg, NSString))
        {
            ERROR_LOG(@"Error getting shape: %@\n", errorMsg);
        }
        
        if (EXPECTED_CLASS(points, NSArray))
        {
            self.shapeCoords = [NSMutableArray alloc].init.autorelease;
            
            for (NSDictionary *xy in points)
            {
                NSNumber *x = xy[@"x"];
                NSNumber *y = xy[@"y"];
                
                if(EXPECTED_CLASS(x, NSNumber) && EXPECTED_CLASS(y, NSNumber))
                {
                    ShapeCoord *coord = [ShapeCoord data];
                    
                    CLLocationDegrees xCoord = x.doubleValue;
                    CLLocationDegrees yCoord = y.doubleValue;
                    
                    //
                    // The coordinates are in the Oregon State Plane North (OSPN) projection.
                    // Frank Purcell has provided the math to convert this to lat and lng in http://groups.google.com/group/transit-developers-pdx
                    //
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
