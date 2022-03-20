//
//  PointInclusionInPolygonTest.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/16/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PointInclusionInPolygonTest : NSObject
 
+ (bool)pnpoly:(int) npol points:(const CGPoint *)p  x:(CGFloat)x y:(CGFloat) y;

@end
