/*
     File: TilingView.m
 Abstract: Handles tile drawing and tile image loading.
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import "TilingView.h"
#import <QuartzCore/CATiledLayer.h>
#import "DebugLogging.h"


@implementation TilingView
@synthesize annotates = _annotates;
@synthesize imageName = _imageName;

- (void)dealloc
{
    self.imageName = nil;
    self.tiledLayer = nil;
    [super dealloc];
}

+ (Class)layerClass {
	return [CATiledLayer class];
}

- (instancetype)initWithImageName:(NSString *)name size:(CGSize)size
{
    if ((self = [super initWithFrame:CGRectMake(0, 0, size.width, size.height)])) {
        self.imageName = name;

        self.tiledLayer = (CATiledLayer *)self.layer;
        self.tiledLayer.levelsOfDetail = 4;
        self.safeBounds = self.bounds;
        DEBUG_LOGR(self.bounds);
    }
    return self;
}

// to handle the interaction between CATiledLayer and high resolution screens, we need to
// always keep the tiling view's contentScaleFactor at 1.0. UIKit will try to set it back
// to 2.0 on retina displays, which is the right call in most cases, but since we're backed
// by a CATiledLayer it will actually cause us to load the wrong sized tiles.
//
- (void)setContentScaleFactor:(CGFloat)contentScaleFactor
{
    super.contentScaleFactor = 1.f;
}

- (void)drawRect:(CGRect)rect
{
#if 0
 	CGContextRef context = UIGraphicsGetCurrentContext();
    
    // get the scale from the context by getting the current transform matrix, then asking
    // for its "a" component, which is one of the two scale components. We could also ask
    // for "d". This assumes (safely) that the view is being scaled equally in both dimensions.
    CGFloat scale = CGContextGetCTM(context).a;
    
    CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
    CGSize tileSize = tiledLayer.tileSize;
    
    // Even at scales lower than 100%, we are drawing into a rect in the coordinate system
    // of the full image. One tile at 50% covers the width (in original image coordinates)
    // of two tiles at 100%. So at 50% we need to stretch our tiles to double the width
    // and height; at 25% we need to stretch them to quadruple the width and height; and so on.
    // (Note that this means that we are drawing very blurry images as the scale gets low.
    // At 12.5%, our lowest scale, we are stretching about 6 small tiles to fill the entire
    // original image area. But this is okay, because the big blurry image we're drawing
    // here will be scaled way down before it is displayed.)
    tileSize.width /= scale;
    tileSize.height /= scale;
    
    // calculate the rows and columns of tiles that intersect the rect we have been asked to draw
    int firstCol = floorf(CGRectGetMinX(rect) / tileSize.width);
    int lastCol = floorf((CGRectGetMaxX(rect)-1) / tileSize.width);
    int firstRow = floorf(CGRectGetMinY(rect) / tileSize.height);
    int lastRow = floorf((CGRectGetMaxY(rect)-1) / tileSize.height);
    
    for (int row = firstRow; row <= lastRow; row++) {
        for (int col = firstCol; col <= lastCol; col++) {
            UIImage *tile = [self tileForScale:scale row:row col:col];
            CGRect tileRect = CGRectMake(tileSize.width * col, tileSize.height * row,
                                         tileSize.width, tileSize.height);
            
            // if the tile would stick outside of our bounds, we need to truncate it so as
            // to avoid stretching out the partial tiles at the right and bottom edges
            tileRect = CGRectIntersection(self.bounds, tileRect);
            
            [tile drawInRect:tileRect];
        }
    }
#endif
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // get the scale from the context by getting the current transform matrix, then asking for
    // its "a" component, which is one of the two scale components. We need to also ask for the "d" component as it might not be precisely the same as the "a" component, even at the "same" scale.
    CGFloat _scaleX = CGContextGetCTM(context).a;
    CGFloat _scaleY = CGContextGetCTM(context).d;
    
    CGSize tileSize = self.tiledLayer.tileSize;
    
    // Even at scales lower than 100%, we are drawing into a rect in the coordinate system of the full
    // image. One tile at 50% covers the width (in original image coordinates) of two tiles at 100%.
    // So at 50% we need to stretch our tiles to double the width and height; at 25% we need to stretch
    // them to quadruple the width and height; and so on.
    // (Note that this means that we are drawing very blurry images as the scale gets low. At 12.5%,
    // our lowest scale, we are stretching about 6 small tiles to fill the entire original image area.
    // But this is okay, because the big blurry image we're drawing here will be scaled way down before
    // it is displayed.)
    
    tileSize.width /= _scaleX;
    tileSize.height /= -_scaleY;
    
    // calculate the rows and columns of tiles that intersect the rect we have been asked to draw
    int firstCol = floorf(CGRectGetMinX(rect) / tileSize.width);
    int lastCol = floorf((CGRectGetMaxX(rect)-1) / tileSize.width);
    int firstRow = floorf(CGRectGetMinY(rect) / tileSize.height);
    int lastRow = floorf((CGRectGetMaxY(rect)-1) / tileSize.height);
    
    for (int row = firstRow; row <= lastRow; row++) {
        for (int col = firstCol; col <= lastCol; col++) {
            UIImage *tile = [self tileForScale:_scaleX row:row col:col];
            CGRect tileRect = CGRectMake(tileSize.width * col, tileSize.height * row,
                                         tileSize.width, tileSize.height);
            
            // if the tile would stick outside of our bounds, we need to truncate it so as to avoid
            // stretching out the partial tiles at the right and bottom edges
            
            // Uses the safe bounds now as not allowed to access the bounds.
            tileRect = CGRectIntersection(self.safeBounds, tileRect);
            DEBUG_LOGR(self.safeBounds);
            
            [tile drawInRect:tileRect];
            
            /// change this to yes to annotate

            if (self.annotates)
            {
                [[UIColor redColor] set];
                CGContextSetLineWidth(context, 6.0 / _scaleX);
                CGContextStrokeRect(context, tileRect);
            }
        }
    }
}

- (UIImage *)tileForScale:(CGFloat)scale row:(int)row col:(int)col
{
    NSString *tileName = [NSString stringWithFormat:@"%@_%d_%d_%d", self.imageName, (int)(scale * 100), col, row];
    // NSLog(@"%@\n", tileName);
    NSString *path = [[NSBundle mainBundle] pathForResource:tileName ofType:@"gif" inDirectory:self.imageName];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    // NSLog(@"%@ %p\n", tileName, image);
    return image;

#if 0
     // we use "imageWithContentsOfFile:" instead of "imageNamed:" here because we don't want UIImage to cache our tiles

	
	// Scale 1    maps to 4
	// Scale 1/2  maps to 3
	// Scale 1/4  maps to 2
	// Scale 1/8  maps to 1
	int level = 0;
    
    //int scale1   = (int)(scale * 1000);
    //int scale2   = scale1 + 60;
    //int scale3   = scale2 / 125;
    //int scaleInt = scale3 * 125;
    int scaleInt = (((((int)(scale*1000)) + 60) / 125 ) * 125);
	
    
	switch (scaleInt)
	{
		case 1000: level = 4; break;
		case 500:  level = 3; break;
		case 250:  level = 2; break;
		case 125:  level = 1; break;
		default:
			level = 0;
			break;
	}
	

	
    NSString *tileName = [NSString stringWithFormat:@"%d-%d-%d", level, col, row];
    // NSLog(@"%@\n", tileName);
    NSString *path = [[NSBundle mainBundle] pathForResource:tileName ofType:@"jpg" inDirectory:imageName];
    
    
    UIImage *image = [UIImage imageWithContentsOfFile:path];
       
    return image;
#endif
}

@end
