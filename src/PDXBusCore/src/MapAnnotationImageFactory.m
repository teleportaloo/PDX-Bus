//
//  MapAnnotationImage.m
//  PDXBusCore
//
//  Created by Andrew Wallace on 10/20/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapAnnotationImageFactory.h"
#import "DebugLogging.h"
#import "Settings.h"
#import "UIImage+Tint.h"

#define kIconUp   @"icon_arrow_up.png"
#define kIconUp2x @"icon_arrow_up@2x.png"
#define kBusIcon  @"icon_arrow_up.png"

@interface MapAnnotationImageFactory () {
    int _hits;
}

@property (nonatomic, strong) NSMutableDictionary *imageCache;
@property (nonatomic) double lastMapRotation;

@end

@implementation MapAnnotationImageFactory

static __weak MapAnnotationImageFactory *singleton = nil;

- (instancetype)init {
    if ((self = [super init])) {
        self.imageCache = [NSMutableDictionary dictionary];
        self.imageFile = kBusIcon;
        _hits = 0;
    }
    
    return self;
}

+ (MapAnnotationImageFactory *)autoSingleton {
    @synchronized (self) {
        if (singleton == nil) {
            MapAnnotationImageFactory *ret = [[MapAnnotationImageFactory alloc] init];
            singleton = ret;
            return ret;
        } else {
            return singleton;
        }
    }
    
    return nil;
}

- (void)dealloc {
    @synchronized (self) {
        singleton = nil;
    }
    
    DEBUG_LOG(@"Image cache removed.\n");
}

- (UIImage *)getImage:(double)rotation mapRotation:(double)mapRotation bus:(bool)bus named:(NSString *)name {
    if (ABS(mapRotation - self.lastMapRotation) > 0.001) {
        self.imageCache = [NSMutableDictionary dictionary];
        self.lastMapRotation = mapRotation;
    }
    
    double total = rotation - mapRotation;
    
    NSMutableDictionary *cachePerName = self.imageCache[name];
    
    if (cachePerName == nil) {
        cachePerName = [NSMutableDictionary dictionary];
        self.imageCache[name] = cachePerName;
    }
    
    UIImage *arrow = cachePerName[@(rotation)];
    
    if (arrow == nil) {
        arrow = [[UIImage imageNamed:name] rotatedImageByDegreesFromNorth:total];
        
        cachePerName[@(rotation)] = arrow;
        
        DEBUG_LOG(@"Cache miss %03u %-3.2f\n", (unsigned int)cachePerName.count, rotation);
    } else {
        DEBUG_LOG(@"Cache hit  %03u %-3.2f\n", (unsigned int)++_hits, rotation);
    }
    
    return arrow;
}

- (bool)tintableImage {
    if ([self.imageFile characterAtIndex:0] == 'c') {
        return NO;
    }
    
    return YES;
}

- (void)clearCache {
    self.imageCache = [NSMutableDictionary dictionary];
}

@end
