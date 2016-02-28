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
#import "UIKit/UIKit.h"

#define kMapAnnotationBusColor [UIColor purpleColor]

@interface MapAnnotationImage : NSObject
{
    NSMutableDictionary *_imageCache;
    double _lastMapRotation;
    NSString *_imageFile;
    bool _forceRetinaImage;
}

@property (nonatomic, retain) NSMutableDictionary *imageCache;
@property (nonatomic)         double              lastMapRotation;
@property (nonatomic, retain) NSString             *imageFile;
@property (nonatomic) bool                          forceRetinaImage;

- (UIImage *)getImage:(double)rotation mapRotation:(double)mapRotation bus:(bool)bus;
+ (MapAnnotationImage*)getSingleton;
- (UIImage *)tintImage:(UIImage *)sourceImage color:(UIColor *)color;
- (bool)tintableImage;
- (void)clearCache;


@end
