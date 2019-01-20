//
//  SimpleAnnotation.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/24/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "SimpleAnnotation.h"


@implementation SimpleAnnotation


+ (instancetype)annotation
{
    return [[[self class] alloc] init];
}

#pragma mark Setters

#pragma mark Getters

- (NSString *)title
{
    return self.pinTitle;
}
- (NSString *)subtitle
{
    return self.pinSubtitle;
}

- (bool)showActionMenu
{
    return false;
}

- (bool)hasBearing
{
    return _hasBearing;
}

- (void)setDoubleBearing:(double)bearing
{
    _bearing = bearing;
    _hasBearing = YES;
}

- (double)doubleBearing
{
    return _bearing;
}


@end
