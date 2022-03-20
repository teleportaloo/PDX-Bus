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


#define DEBUG_LEVEL_FOR_FILE kLogParsing

#import "LegShapeParser.h"
#import "DebugLogging.h"
#import "math.h"

@implementation LegShapeParser

- (instancetype)init {
    if ((self = [super init])) {
        self.replaceQueryBlock = ^NSString * _Nonnull(LegShapeParser * _Nonnull xml, NSString * _Nonnull query) {
            NSMutableString *mutableQuery = query.mutableCopy;
            
            // The "URL" initially looks like this - we need to remove the transweb part and add the trimet part
            // /transweb/ws/V1/BlockGeoWS/appID/xxxxx/bksTsIDeTeID/3305,X,11:21 AM,15,11:58 AM,7751
            
            [mutableQuery deleteCharactersInRange:NSMakeRange(0, 9)];  // /transweb is 9 characters
            
            
            return [NSString stringWithFormat:@"https://developer.trimet.org%@", [mutableQuery stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        };
    }
    
    return self;
}

- (void)fetchCoords {
    @autoreleasepool {
        NSString *fullQuery = self.replaceQueryBlock(self, self.lineURL);
        
        DEBUG_LOG(@"Query %@\n", fullQuery);
        
        [self fetchDataByPolling:fullQuery cachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        
        if (self.rawData) {
            NSError *error = 0;
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:self.rawData options:0 error:&error];
            
            DEBUG_LOGO(json);
            
            NSDictionary *response = nil;
            NSArray *results = nil;
            NSDictionary *firstResult = nil;
            NSArray *points = nil;
            NSString *errorMsg = nil;
            
            if (error) {
                ERROR_LOG(@"Error parsing JSON: %@\n%@", error.localizedDescription, [[NSString alloc] initWithData:self.rawData encoding:NSUTF8StringEncoding]);
            } else {
                response = json[@"response"];
            }
            
#define EXPECTED_CLASS(X, C) ((X) && [(X) isKindOfClass:[C class]])
            
            if (EXPECTED_CLASS(response, NSDictionary)) {
                results = response[@"results"];
            }
            
            if (EXPECTED_CLASS(results, NSArray)) {
                firstResult = results.firstObject;
            }
            
            if (EXPECTED_CLASS(firstResult, NSDictionary)) {
                points = firstResult[@"points"];
                errorMsg = firstResult[@"error"];
            }
            
            if (EXPECTED_CLASS(errorMsg, NSString)) {
                DEBUG_LOG(@"Error getting shape: %@\n", errorMsg);
            }
            
            if (EXPECTED_CLASS(points, NSArray)) {
                self.segment = [ShapeMutableSegment new];
                
                for (NSDictionary *xy in points) {
                    NSNumber *x = xy[@"x"];
                    NSNumber *y = xy[@"y"];
                    
                    if (EXPECTED_CLASS(x, NSNumber) && EXPECTED_CLASS(y, NSNumber)) {
                        ShapeCoord *coord = [ShapeCoord new];
                        
                        CLLocationDegrees xCoord = x.doubleValue;
                        CLLocationDegrees yCoord = y.doubleValue;
                        
                        //
                        // The coordinates are in the Oregon State Plane North (OSPN) projection.
                        // Frank Purcell has provided the math to convert this to lat and lng in http://groups.google.com/group/transit-developers-pdx
                        //
                        coord.longitude = +((((atan(((xCoord * 0.3048) - 2500000) / (6350713.93 - ((yCoord * 0.3048) - 166910.7663)))) * 180) / (3.14159265359 * 0.709186016884)) - 120.5);
                        coord.latitude = (45.1687259619 + ((((yCoord * 0.3048) - 166910.7663) - (((xCoord * 0.3048) - 2500000) * tan((atan(((xCoord * 0.3048) - 2500000) / (6350713.93 - ((yCoord * 0.3048) - 166910.7663)))) / 2))) * (0.000008999007999 + (((yCoord * 0.3048) - 166910.7663) - (((xCoord * 0.3048) - 2500000) * tan((atan(((xCoord * 0.3048) - 2500000) / (6350713.93 - ((yCoord * 0.3048) - 166910.7663)))) / 2))) * (-7.1202E-015 + (((yCoord * 0.3048) - 166910.7663) - (((xCoord * 0.3048) - 2500000) * tan((atan(((xCoord * 0.3048) - 2500000) / (6350713.93 - ((yCoord * 0.3048) - 166910.7663)))) / 2))) * (-3.6863E-020 + (((yCoord * 0.3048) - 166910.7663) - (((xCoord * 0.3048) - 2500000) * tan((atan(((xCoord * 0.3048) - 2500000) / (6350713.93 - ((yCoord * 0.3048) - 166910.7663)))) / 2))) * -1.3188E-027)))));
                        [self.segment.coords addObject:coord];
                    }
                }
            }
        }
    }
}

@end
