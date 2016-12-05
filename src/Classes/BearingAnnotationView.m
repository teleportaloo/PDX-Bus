//
//  BearingAnnotationView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/19/15.
//  Copyright © 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BearingAnnotationView.h"
#import "MapPinColor.h"
#import "ViewControllerBase.h"
#import "DebugLogging.h"
#import "FilledCircleView.h"

#define ARROW_TAG 1
#define BLOB_TAG 2

#define ROOT2 1.5 // 1.41421356237

@implementation BearingAnnotationView

@synthesize annotationImage = _annotationImage;

- (instancetype)initWithAnnotation:(nullable id <MKAnnotation>)annotation reuseIdentifier:(nullable NSString *)reuseIdentifier
{
    if ((self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]))
    {
        self.annotationImage = [MapAnnotationImage singleton];
    }
    return self;
}

- (void)dealloc
{
    self.annotationImage = nil;
    
    [super dealloc];
}


- (void)updateDirectionalAnnotationView:(MKMapView *)mapView
{
    if ([self.annotation conformsToProtocol:@protocol(MapPinColor)])
    {
        id<MapPinColor> pin = (id<MapPinColor>)self.annotation;
        
        UIColor *col = pin.pinTint;
        
        UIImage *arrow = [self.annotationImage getImage:pin.doubleBearing mapRotation:mapView.camera.heading bus:col==nil];
        
        UIView *oldArrow = [self viewWithTag:ARROW_TAG];
        
        
        
        if (oldArrow)
        {
            [oldArrow removeFromSuperview];
        }
        else
        {
            // DEBUG_LOG(@"new arrow\n");
        }
        
        UIView *blob = [self viewWithTag:BLOB_TAG];
        
        if (blob)
        {
            [blob removeFromSuperview];
        }
        
        if (col == nil && self.annotationImage.tintableImage)
        {
            col = kMapAnnotationBusColor;
        }
        
        
        if (col!=nil)
        {
            UIImageView *imageView = [[[UIImageView alloc] initWithImage:[arrow imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]] autorelease];
            
            self.frame = imageView.frame;
            imageView.tintColor = col;
            
            imageView.tag = ARROW_TAG;
            
            [self addSubview:imageView];
            self.autoresizesSubviews = NO;
            
        }
        else
        {
            UIImageView *imageView = [[[UIImageView alloc] initWithImage:arrow ] autorelease];
            self.frame = imageView.frame;
            imageView.tag = ARROW_TAG;
            [self addSubview:imageView];
            self.autoresizesSubviews = NO;
        }
        
        if ([pin respondsToSelector:@selector(pinSubTint)])
        {
            UIView *arrow = [self viewWithTag:ARROW_TAG];
            UIColor *blockColor = pin.pinSubTint;
            
            if (blockColor != nil)
            {
                CGRect blobRect = CGRectInset(arrow.frame, arrow.frame.size.width/3, arrow.frame.size.height/3);
                FilledCircleView *view = [[[FilledCircleView alloc] initWithFrame:blobRect] autorelease];
                
                view.fillColor = blockColor;
                view.backgroundColor = [UIColor clearColor];
                
                view.tag = BLOB_TAG;
                
                [self addSubview:view];
                
            }
        }
        
        [self layoutIfNeeded];
    }
}

+ (MKAnnotationView*)viewForPin:(id<MapPinColor>)pin mapView:(MKMapView*)mapView
{
    if (!pin.hasBearing)
    {
        NSString *ident = [NSString stringWithFormat:@"stop"];
        MKPinAnnotationView *view = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier: ident];
        
        if (view == nil)
        {
            view=[[[MKPinAnnotationView alloc] initWithAnnotation:pin reuseIdentifier:ident] autorelease];
        }
        
        view.annotation = pin;
        
        if ([view respondsToSelector:@selector(pinTintColor)] && pin.pinTint!=nil)
        {
            view.pinTintColor =pin.pinTint;
        }
        else
        {
            view.pinColor = pin.pinColor;
        }
        
        return view;
    }
    else
    {
        NSString *ident = [NSString stringWithFormat:@"bearing"];
        
        BearingAnnotationView *view = (BearingAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier: ident];
        
        if (view == nil)
        {
            view=[[[BearingAnnotationView alloc] initWithAnnotation:pin reuseIdentifier:ident] autorelease];
        }
        
        view.annotation = pin;
        
        [view updateDirectionalAnnotationView:mapView];
        
        return view;
    }
    
    return nil;
    
}


@end
