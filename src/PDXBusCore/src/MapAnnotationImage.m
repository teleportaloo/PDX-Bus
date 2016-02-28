//
//  MapAnnotationImage.m
//  PDXBusCore
//
//  Created by Andrew Wallace on 10/20/15.
//  Copyright © 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapAnnotationImage.h"
#import "DebugLogging.h"
#import "UserPrefs.h"

#define kIconUp				 @"icon_arrow_up.png"
#define kIconUp2x            @"icon_arrow_up@2x.png"

@implementation MapAnnotationImage

@synthesize imageCache = _imageCache;
@synthesize lastMapRotation = _lastMapRotation;
@synthesize imageFile = _imageFile;
@synthesize forceRetinaImage = _forceRetinaImage;

static MapAnnotationImage *singleton = nil;

- (id)init {
    if ((self = [super init]))
    {
        self.imageCache = [[[NSMutableDictionary alloc] init] autorelease];
        self.imageFile = [UserPrefs getSingleton].busIcon;
    }
    
    return self;
}

+ (MapAnnotationImage*)getSingleton
{
    if (singleton == nil)
    {
        singleton = [[[MapAnnotationImage alloc] init] autorelease];
        
        return singleton;
    }
    else
    {
        return [[singleton retain] autorelease];
    }
    
    return nil;
}

- (void)dealloc
{
    self.imageCache = nil;
    self.imageFile = nil;
    singleton = nil;
    
    DEBUG_LOG(@"Image cache removed.\n");
    
    [super dealloc];
}


- (UIImage*)rotatedImage:(UIImage*)sourceImage byDegreesFromNorth:(double)degrees
{
    
    CGSize rotateSize =  sourceImage.size;
    UIGraphicsBeginImageContext(rotateSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, rotateSize.width/2, rotateSize.height/2);
    CGContextRotateCTM(context, ( degrees * M_PI/180.0 ) );
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(UIGraphicsGetCurrentContext(),
                       CGRectMake(-rotateSize.width/2,-rotateSize.height/2,rotateSize.width, rotateSize.height),
                       sourceImage.CGImage);
    UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return rotatedImage;
}

- (UIImage *)tintImage:(UIImage *)sourceImage color:(UIColor *)color
{

    CGRect rect = { 0,0, sourceImage.size.width, sourceImage.size.height};
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    
    CGContextFillRect(context, rect); // draw base
    
    [sourceImage drawInRect:rect blendMode:kCGBlendModeDestinationIn alpha:1.0]; // draw image
    
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
    
}

- (UIImage *)getImage:(double)rotation mapRotation:(double)mapRotation bus:(bool)bus
{
    if ( ABS(mapRotation - self.lastMapRotation) > 0.001 )
    {
        self.imageCache = [[[NSMutableDictionary alloc] init] autorelease];
        self.lastMapRotation = mapRotation;
    }
    
    double total = rotation - mapRotation;
    
    NSString *image = self.forceRetinaImage ? kIconUp2x : kIconUp;
    
    if (bus)
    {
        rotation += 360*3;   // this just makes them different!
        image = self.imageFile;
    }
    
    NSNumber *rot = [NSNumber numberWithDouble:rotation];
    
    UIImage *arrow = [self.imageCache objectForKey:rot];
    
    if (arrow == nil)
    {
        arrow = [self rotatedImage:[UIImage imageNamed:image ] byDegreesFromNorth:total];
        
        [self.imageCache setObject:arrow forKey:rot];
        
        DEBUG_LOG(@"Cache %f %lu\n", rotation, (unsigned long)self.imageCache.count);
    }
    else
    {
        DEBUG_LOG(@"Cache hit %f\n", rotation);
    }
    
    return arrow;
    
}

- (bool)tintableImage
{
    if ([self.imageFile characterAtIndex:0] == 'c')
    {
        return NO;
    }
    return YES;
}

- (void)clearCache
{
    self.imageCache = [[[NSMutableDictionary alloc] init] autorelease];
}


@end
