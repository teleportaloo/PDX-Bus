//
//  WatchArrivalsContext.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WatchArrivalsContext : NSObject

@property (retain, nonatomic) NSString *locid;
@property (nonatomic)         bool     showMap;
@property (nonatomic)         double   distance;
@property (nonatomic)         bool     showDistance;
@property (nonatomic, retain) NSString *stopDesc;

+ (WatchArrivalsContext*)contextWithLocation:(NSString *)location;
+ (WatchArrivalsContext*)contextWithLocation:(NSString *)location distance:(double)distance;
+ (WatchArrivalsContext*)contextWithLocation:(NSString *)location distance:(double)distance stopDesc:(NSString*)stopDesc;


@end
