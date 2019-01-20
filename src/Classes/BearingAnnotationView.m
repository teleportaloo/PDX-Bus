//
//  BearingAnnotationView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/19/15.
//  Copyright © 2015 Andrew Wallace
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
#define HEAD_TAG 3

#define ROOT2 1.5 // 1.41421356237

@implementation BearingAnnotationView

- (instancetype)initWithAnnotation:(nullable id <MKAnnotation>)annotation reuseIdentifier:(nullable NSString *)reuseIdentifier
{
    if ((self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]))
    {
        self.annotationImage = [MapAnnotationImage autoSingleton];
    }
    return self;
}



- (void)updateDirectionalAnnotationView:(MKMapView *)mapView
{
    if ([self.annotation conformsToProtocol:@protocol(MapPinColor)])
    {
        id<MapPinColor> pin = (id<MapPinColor>)self.annotation;
        
        UIColor *col = pin.pinTint;
        
        UIImage *arrow = [self.annotationImage getImage:pin.doubleBearing mapRotation:mapView.camera.heading bus:col==nil named:self.annotationImage.forceRetinaImage ? kIconUp2x : kIconUp];
        
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
        
        UIView *head = [self viewWithTag:HEAD_TAG];
        
        if (head)
        {
            [head removeFromSuperview];
        }
        
        if (col == nil && self.annotationImage.tintableImage)
        {
            col = kMapAnnotationBusColor;
        }
        
        
        if (col!=nil)
        {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[arrow imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            
            self.frame = imageView.frame;
            imageView.tintColor = col;
            
            imageView.tag = ARROW_TAG;
            
            [self addSubview:imageView];
            
            UIImage *head = [self.annotationImage getImage:pin.doubleBearing mapRotation:mapView.camera.heading bus:col==nil named:self.annotationImage.forceRetinaImage ? kIconUpHead2x : kIconUpHead];
            UIImageView *headView = [[UIImageView alloc] initWithImage:[head imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            headView.tintColor = [UIColor darkGrayColor];
            headView.tag = HEAD_TAG;
            [self addSubview:headView];
            
            self.autoresizesSubviews = NO;
            
        }
        else
        {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:arrow ];
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
                FilledCircleView *view = [[FilledCircleView alloc] initWithFrame:blobRect];
                
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
            view=[[MKPinAnnotationView alloc] initWithAnnotation:pin reuseIdentifier:ident];
        }
        
        view.annotation = pin;
        
        if ([view respondsToSelector:@selector(pinTintColor)] && pin.pinTint!=nil)
        {
            view.pinTintColor =pin.pinTint;
        }
        else
        {
#ifdef BASE_IOS12
            switch (pin.pinColor)
            {
                default:
                case MAP_PIN_COLOR_RED:         view.pinTintColor = [UIColor redColor]; break;
                case MAP_PIN_COLOR_GREEN:       view.pinTintColor = [UIColor greenColor]; break;
                case MAP_PIN_COLOR_PURPLE:      view.pinTintColor = [UIColor greenColor]; break;
            }

#else
            switch (pin.pinColor)
            {
                default:
                case MAP_PIN_COLOR_RED:         view.pinColor =  MKPinAnnotationColorRed;       break;
                case MAP_PIN_COLOR_GREEN:       view.pinColor =  MKPinAnnotationColorGreen;     break;
                case MAP_PIN_COLOR_PURPLE:      view.pinColor =  MKPinAnnotationColorPurple;    break;
            }
            
#endif
        }
        
        return view;
    }
    else
    {
        NSString *ident = [NSString stringWithFormat:@"bearing"];
        
        BearingAnnotationView *view = (BearingAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier: ident];
        
        if (view == nil)
        {
            view=[[BearingAnnotationView alloc] initWithAnnotation:pin reuseIdentifier:ident];
        }
        
        view.annotation = pin;
        
        [view updateDirectionalAnnotationView:mapView];
        
        return view;
    }
    
    return nil;
    
}


@end
