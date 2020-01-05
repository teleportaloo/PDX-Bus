//
//  UIImage+Tint.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/2/19.
//  Copyright © 2019 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "UIImage+Tint.h"

@implementation UIImage (Tint)


- (UIImage*)rotatedImageByDegreesFromNorth:(double)degrees
{
    CGSize rotateSize =  self.size;
    
    /* Note:  This is a graphics context block */
    UIGraphicsBeginImageContextWithOptions(rotateSize, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, rotateSize.width/2, rotateSize.height/2);
    CGContextRotateCTM(context, ( degrees * M_PI/180.0 ) );
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(UIGraphicsGetCurrentContext(),
                       CGRectMake(-rotateSize.width/2,-rotateSize.height/2,rotateSize.width, rotateSize.height),
                       self.CGImage);
    UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return rotatedImage;
}

- (UIImage *)tintImageWithColor:(UIColor *)color
{
    CGRect rect = { 0,0, self.size.width, self.size.height};
   
    /* Note:  This is a graphics context block */
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect); // draw base
    [self drawInRect:rect blendMode:kCGBlendModeDestinationIn alpha:1.0]; // draw image
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
}

@end
