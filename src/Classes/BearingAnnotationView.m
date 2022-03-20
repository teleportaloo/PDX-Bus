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


#define DEBUG_LEVEL_FOR_FILE kLogUserInterface

#import "BearingAnnotationView.h"
#import "MapPin.h"
#import "Icons.h"
#import "DebugLogging.h"
#import "FilledCircleView.h"
#import "LinkResponsiveTextView.h"
#import "NSString+Helper.h"
#import "UIFont+Utility.h"


#define ARROW_TAG 1
#define BLOB_TAG  2
#define HEAD_TAG  3

@implementation BearingAnnotationView

- (instancetype)initWithAnnotation:(nullable id <MKAnnotation>)annotation reuseIdentifier:(nullable NSString *)reuseIdentifier {
    if ((self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier])) {
        self.annotationImage = [MapAnnotationImageFactory autoSingleton];
    }
    
    return self;
}

- (void)updateDirectionalAnnotationView:(MKMapView *)mapView {
    if ([self.annotation conformsToProtocol:@protocol(MapPin)]) {
        id<MapPin> pin = (id<MapPin>)self.annotation;
        
        UIColor *col = pin.pinTint;
        
        UIImage *arrow = [self.annotationImage getImage:pin.pinBearing mapRotation:mapView.camera.heading bus:col == nil named:self.annotationImage.forceRetinaImage ? kIconUp2x : kIconUp];
        
        UIView *oldArrow = [self viewWithTag:ARROW_TAG];
        
        if (oldArrow) {
            [oldArrow removeFromSuperview];
        } else {
            // DEBUG_LOG(@"new arrow\n");
        }
        
        UIView *blob = [self viewWithTag:BLOB_TAG];
        
        if (blob) {
            [blob removeFromSuperview];
        }
        
        UIView *head = [self viewWithTag:HEAD_TAG];
        
        if (head) {
            [head removeFromSuperview];
        }
        
        if (col == nil && self.annotationImage.tintableImage) {
            col = [UIColor modeAwareBusColor];
        }
        
        if (col != nil) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[arrow imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            
            self.frame = imageView.frame;
            imageView.tintColor = col;
            
            imageView.tag = ARROW_TAG;
            
            [self addSubview:imageView];
            
            UIImage *head = [self.annotationImage getImage:pin.pinBearing mapRotation:mapView.camera.heading bus:col == nil named:self.annotationImage.forceRetinaImage ? kIconUpHead2x : kIconUpHead];
            UIImageView *headView = [[UIImageView alloc] initWithImage:[head imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            headView.tintColor = [UIColor darkGrayColor];
            headView.tag = HEAD_TAG;
            [self addSubview:headView];
            
            self.autoresizesSubviews = NO;
        } else {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:arrow ];
            self.frame = imageView.frame;
            imageView.tag = ARROW_TAG;
            [self addSubview:imageView];
            self.autoresizesSubviews = NO;
        }
        
        if ([pin respondsToSelector:@selector(pinBlobColor)]) {
            UIView *arrow = [self viewWithTag:ARROW_TAG];
            UIColor *blockColor = pin.pinBlobColor;
            
            if (blockColor != nil) {
                CGRect blobRect = CGRectInset(arrow.frame, arrow.frame.size.width / 3, arrow.frame.size.height / 3);
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

+ (MKAnnotationView *)viewForPin:(id<MapPin>)pin
                         mapView:(MKMapView *)mapView
                       urlAction:(bool (^__nullable)(id<MapPin>, NSURL *url, UIView *source)) urlAction {
    
    MKAnnotationView *annotationView = nil;
    
    if (!pin.pinHasBearing) {
        NSString *ident = [NSString stringWithFormat:@"stop"];
        MKPinAnnotationView *view = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:ident];
        
        if (view == nil) {
            view = [[MKPinAnnotationView alloc] initWithAnnotation:pin reuseIdentifier:ident];
        }
        
        view.annotation = pin;
        
        if ([view respondsToSelector:@selector(pinTintColor)] && pin.pinTint != nil) {
            view.pinTintColor = pin.pinTint;
        } else {
            
            switch (pin.pinColor) {
                default:
                case MAP_PIN_COLOR_RED:         view.pinTintColor = [UIColor redColor]; break;
                    
                case MAP_PIN_COLOR_GREEN:       view.pinTintColor = [UIColor greenColor]; break;
                    
                case MAP_PIN_COLOR_PURPLE:      view.pinTintColor = [UIColor purpleColor]; break;
                
                case MAP_PIN_COLOR_BLUE:        view.pinTintColor = [UIColor blueColor]; break;
                    
                case MAP_PIN_COLOR_WHITE:       view.pinTintColor = [UIColor whiteColor]; break;
                    
            }
        }
        
        annotationView = view;
    } else {
        NSString *ident = [NSString stringWithFormat:@"bearing"];
        
        BearingAnnotationView *view = (BearingAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:ident];
        
        if (view == nil)
        {
            view = [[BearingAnnotationView alloc] initWithAnnotation:pin reuseIdentifier:ident];
        }
        
        view.annotation = pin;
        
        [view updateDirectionalAnnotationView:mapView];
        
        annotationView = view;
    }
    
    NSMutableString *markedUpSubtitle = [NSMutableString stringWithString:pin.pinMarkedUpType != nil ? pin.pinMarkedUpType : @""];

    if ([pin respondsToSelector:@selector(pinMarkedUpStopId)] && pin.pinMarkedUpStopId != nil)
    {
        [markedUpSubtitle appendFormat:markedUpSubtitle.length > 0 ? @"\n" : @""];
        [markedUpSubtitle appendFormat:@"%@", pin.pinMarkedUpStopId];
    }
    else if ([pin respondsToSelector:@selector(pinStopId)] && pin.pinStopId != nil)
    {
        [markedUpSubtitle appendFormat:markedUpSubtitle.length > 0 ? @"\n" : @""];
        [markedUpSubtitle appendFormat:@"#D%@", pin.pinStopId.markedUpLinkToStopId];
    }
    
    if ([pin respondsToSelector:@selector(pinMarkedUpSubtitle)] && pin.pinMarkedUpSubtitle != nil)
    {
        [markedUpSubtitle appendFormat:markedUpSubtitle.length > 0 ? @"\n" : @""];
        [markedUpSubtitle appendString:pin.pinMarkedUpSubtitle];
    }
    
#ifdef DEBUGLOGGING
    if (DEBUG_ON_FOR_FILE) {
        [markedUpSubtitle appendFormat:@"\n#DDebug - class #b%@#b", NSStringFromClass(pin.class)];
    }
#endif
    
    NSString *actionText = nil;
    
    if ([pin pinActionMenu]) {

        if ([pin respondsToSelector:@selector(pinAction:)]) { //  && [self.tappedAnnot mapTapped])
            if (([pin respondsToSelector:@selector(pinUseAction)] && pin.pinUseAction)
                || !([pin respondsToSelector:@selector(pinUseAction)])) {
                actionText = nil;
                
                if ([pin respondsToSelector:@selector(pinActionText)]) {
                    actionText = [pin pinActionText];
                }
                
                if (actionText == nil) {
                    actionText = NSLocalizedString(@"Choose this stop", @"button text");
                }
            }
        }
    
        if (actionText && actionText.length > 0)
        {
            [markedUpSubtitle appendFormat:markedUpSubtitle.length > 0 ? @"\n" : @""];
            [markedUpSubtitle appendFormat:@"#Laction:tap %@#T", actionText];
        }

    }
        
    if (markedUpSubtitle.length >0) {
        
        //Adding multiline subtitle code
        
        LinkResponsiveTextView *subLabel = (LinkResponsiveTextView *)annotationView.detailCalloutAccessoryView;
        if (subLabel == nil)
        {
            subLabel = [[LinkResponsiveTextView alloc] init];
            annotationView.detailCalloutAccessoryView = subLabel;
            subLabel.backgroundColor = [UIColor clearColor];
        }
   
        subLabel.delegate = subLabel;
        subLabel.linkAction = ^bool(LinkResponsiveTextView * _Nonnull view, NSURL * _Nonnull url, NSRange characterRange, UITextItemInteraction interaction) {
            return urlAction(pin, url, view);
        };
    
        
        subLabel.scrollEnabled = NO;
        subLabel.attributedText = [markedUpSubtitle attributedStringFromMarkUpWithFont:[UIFont monospacedDigitSystemFontOfSize:16.0]];
        
        const CGFloat sizeWidth = 310;
        CGSize sz = [subLabel sizeThatFits:CGSizeMake(sizeWidth, MAXFLOAT)];
        
        NSLayoutConstraint *width =  [NSLayoutConstraint constraintWithItem:subLabel attribute:NSLayoutAttributeWidth  relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:sz.width];
        NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:subLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:sz.height];
        
        // [subLabel setNumberOfLines:0];
        [subLabel addConstraint:width];
        [subLabel addConstraint:height];
    }
   
    return annotationView;
}

@end
