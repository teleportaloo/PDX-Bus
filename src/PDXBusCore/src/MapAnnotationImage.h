//
//  MapAnnotationImage.h
//  PDXBusCore
//
//  Created by Andrew Wallace on 10/20/15.
//  Copyright © 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "PDXBusCore.h"

#define kMapAnnotationBusColor [UIColor grayColor]

@interface MapAnnotationImage : NSObject
{
    int                     _hits;
}

@property (nonatomic, strong) NSMutableDictionary *imageCache;
@property (nonatomic, readonly) bool tintableImage;
@property (nonatomic, strong) NSString *imageFile;
@property (nonatomic) double lastMapRotation;
@property (nonatomic) bool forceRetinaImage;

- (UIImage *)getImage:(double)rotation mapRotation:(double)mapRotation bus:(bool)bus named:(NSString*)name;
- (UIImage *)tintImage:(UIImage *)sourceImage color:(UIColor *)color;
- (void)clearCache;

+ (MapAnnotationImage*)autoSingleton;   // zero or one instances can exist - is refrence counted.

@end
