//
//  KMLRoutes.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/4/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetXML.h"
#import "KMLPlacemark.h"

#define kKmlNoRouteNumber       @"None"

#define kKmlFirstDirection      @"0"
#define kKmlOptionalDirection   @"1"

#define kKmlkey(R,D)            [R stringByAppendingString:D]

@class ShapeRoutePath;

@interface KMLRoutes : TriMetXML<NSArray*>
{
    bool _gitHubRouteShapes;
    SEL _currentSelector;
}

@property (nonatomic, strong) KMLPlacemark *currentPlacemark;
@property (nonatomic, copy) NSString *currentAttribute;
@property (nonatomic, strong) NSMutableDictionary <NSString *, KMLPlacemark*> *routes;
@property (weak, nonatomic, readonly) NSEnumerator<NSString *> * keyEnumerator;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSValue*> *selsForProps;

- (void)fetch;
- (ShapeRoutePath*)lineCoordsForKey:(NSString *)key;
- (ShapeRoutePath*)lineCoordsForRoute:(NSString *)route direction:(NSString *)dir;
- (bool)cached;

+ (void)initCaches;
+ (void)deleteCacheFile;

@end
