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

#define kMapAnnotationBusColor [UIColor purpleColor]

@interface MapAnnotationImage : NSObject
{
    NSMutableDictionary *   _imageCache;
    double                  _lastMapRotation;
    NSString *              _imageFile;
    bool                    _forceRetinaImage;
    int                     _hits;
}

@property (nonatomic, retain) NSMutableDictionary *imageCache;
@property (nonatomic)         double              lastMapRotation;
@property (nonatomic, retain) NSString             *imageFile;
@property (nonatomic) bool                          forceRetinaImage;

- (UIImage *)getImage:(double)rotation mapRotation:(double)mapRotation bus:(bool)bus;
+ (MapAnnotationImage*)autoSingleton;   // zero or one instances can exist - is refrence counted.
- (UIImage *)tintImage:(UIImage *)sourceImage color:(UIColor *)color;
@property (nonatomic, readonly) bool tintableImage;
- (void)clearCache;


@end
