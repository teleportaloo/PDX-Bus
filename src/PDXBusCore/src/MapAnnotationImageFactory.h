//
//  MapAnnotationImageFactory.h
//  PDXBusCore
//
//  Created by Andrew Wallace on 10/20/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "PDXBusCore.h"
#import "UIColor+DarkMode.h"

@interface MapAnnotationImageFactory : NSObject

@property (nonatomic, readonly) bool tintableImage;
@property (nonatomic, strong) NSString *imageFile;

@property (nonatomic) bool forceRetinaImage;

- (UIImage *)getImage:(double)rotation mapRotation:(double)mapRotation bus:(bool)bus named:(NSString *)name;
- (void)clearCache;

+ (MapAnnotationImageFactory *)autoSingleton;   // zero or one instances can exist - is refrence counted.

@end
