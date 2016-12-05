//
//  DeviceOrientation.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/27/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InterfaceOrientation.h"

@implementation InterfaceOrientation

+ (UIInterfaceOrientation) getInterfaceOrientation:(UIViewController*)controller
{
    return [UIApplication sharedApplication].statusBarOrientation;
}


@end
