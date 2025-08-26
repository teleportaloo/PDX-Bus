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


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "BearingAnnotationView.h"
#import "DebugLogging.h"
#import "FilledCircleView.h"
#import "Icons.h"
#import "LinkResponsiveTextView.h"
#import "MapPin.h"
#import "MarginLabel.h"
#import "NSString+MoreMarkup.h"
#import "TaskDispatch.h"
#import "UIColor+MoreDarkMode.h"
#import "UIFont+Utility.h"

#define ARROW_TAG 11
#define BLOB_TAG 12
#define OUTLINE_TAG 13
#define TEXT_TAG 14

@implementation BearingAnnotationView

- (instancetype)initWithAnnotation:(nullable id<MKAnnotation>)annotation
                   reuseIdentifier:(nullable NSString *)reuseIdentifier {
    if ((self = [super initWithAnnotation:annotation
                          reuseIdentifier:reuseIdentifier])) {
        self.autoresizesSubviews = NO;
    }
    return self;
}

- (void)removeOldView:(NSInteger)tag {
    UIView *oldItem = [self viewWithTag:tag];

    if (oldItem) {
        [oldItem removeFromSuperview];
    }
}

CGFloat TruncatingRemainder(CGFloat x, CGFloat dividingBy) {
    return x - dividingBy * floor(x / dividingBy);
}

+ (CGAffineTransform)arrowTransformdForPin:(id<MapPin>)pin
                                  rotation:(CGFloat)mapRotation {
    CGFloat rotationDegrees =
        TruncatingRemainder(pin.pinBearing - mapRotation, 360);
    CGAffineTransform transform = CGAffineTransformRotate(
        CGAffineTransformIdentity, (rotationDegrees * M_PI) / 180.0);
    return transform;
}

+ (void)rotateText:(MarginLabel *)label
               pin:(id<MapPin>)pin
          rotation:(CGFloat)mapRotation {
    CGFloat rotationDegrees =
        TruncatingRemainder(pin.pinBearing - mapRotation, 360);
    // Normalize
    if (rotationDegrees < -180) {
        rotationDegrees += 360;
    }

    // Flip if upside down
    if (rotationDegrees <= 182) {
        rotationDegrees -= 180;
        label.rightInset = 6;
        label.leftInset = 0;
    } else {
        label.leftInset = 6;
        label.rightInset = 0;
    }

    label.bottomInset = 1;

    // Rotate to align with arrow
    rotationDegrees += 90;
    label.transform = CGAffineTransformRotate(CGAffineTransformIdentity,
                                              (rotationDegrees * M_PI) / 180.0);
}

- (void)updateDirectionInPlace:(MKMapView *)mapView {

    if ([self.annotation conformsToProtocol:@protocol(MapPin)]) {
        id<MapPin> pin = (id<MapPin>)self.annotation;
        CGAffineTransform transform = [BearingAnnotationView
            arrowTransformdForPin:(id<MapPin>)pin
                         rotation:mapView.camera.heading];
        UIView *view = [self viewWithTag:ARROW_TAG];

        if (view) {
            view.transform = transform;
        }

        view = [self viewWithTag:OUTLINE_TAG];

        if (view) {
            view.transform = transform;
        }

        view = [self viewWithTag:TEXT_TAG];

        if (view) {
            [BearingAnnotationView rotateText:(MarginLabel *)view
                                          pin:pin
                                     rotation:mapView.camera.heading];
        }
    }
}

- (void)updateDirectionalAnnotationView:(MKMapView *)mapView {
    if ([self.annotation conformsToProtocol:@protocol(MapPin)]) {
        id<MapPin> pin = (id<MapPin>)self.annotation;

        static UIImage *outlineImage;
        static UIImage *arrowImage;
        static UIFont *smallTextFont;

        DoOnce(^{
          outlineImage = [[UIImage imageNamed:kIconUpHead]
              imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
          arrowImage = [[UIImage imageNamed:kIconUp]
              imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
          smallTextFont = [UIFont boldMonospacedDigitSystemFontOfSize:10.0];
        });

        UIColor *col = pin.pinTint;

        if (col == nil) {
            col = [UIColor modeAwareBusColor];
        }

        [self removeOldView:ARROW_TAG];
        [self removeOldView:BLOB_TAG];
        [self removeOldView:OUTLINE_TAG];
        [self removeOldView:TEXT_TAG];

        CGAffineTransform transform = [BearingAnnotationView
            arrowTransformdForPin:(id<MapPin>)pin
                         rotation:mapView.camera.heading];

        UIColor *blockColor = nil;

        if ([pin respondsToSelector:@selector(pinBlobColor)]) {
            blockColor = pin.pinBlobColor;
        }

        UIImageView *arrowView = [[UIImageView alloc] initWithImage:arrowImage];
        self.frame = arrowView.frame;
        arrowView.transform = transform;
        arrowView.tintColor = col;
        arrowView.tag = ARROW_TAG;
        [self addSubview:arrowView];

        UIImageView *outlineView =
            [[UIImageView alloc] initWithImage:outlineImage];
        outlineView.transform = transform;
        outlineView.tintColor = [UIColor blackColor];
        outlineView.tag = OUTLINE_TAG;
        [self addSubview:outlineView];

        if (blockColor != nil) {
            CGRect blobRect =
                CGRectInset(arrowView.frame, arrowView.frame.size.width / 3,
                            arrowView.frame.size.height / 3);
            FilledCircleView *view =
                [[FilledCircleView alloc] initWithFrame:blobRect];

            view.fillColor = blockColor;
            view.backgroundColor = [UIColor clearColor];
            view.tag = BLOB_TAG;
            [self addSubview:view];
        }

        if ([pin respondsToSelector:@selector(pinSmallText)]) {
            NSString *text = pin.pinSmallText;

            if (text != nil) {
                MarginLabel *textLabel = [[MarginLabel alloc] init];
                textLabel.textColor = [UIColor modeAwareBusText];
                textLabel.backgroundColor = [UIColor clearColor];

                CGFloat textHeight =
                    arrowView.frame.size.height / 2.2; // A size that works!

                textLabel.frame = CGRectMake(
                    arrowView.frame.origin.x,
                    arrowView.frame.origin.y +
                        (arrowView.frame.size.height - textHeight) / 2.0,
                    arrowView.frame.size.width, textHeight);

                textLabel.text = text;
                textLabel.adjustsFontSizeToFitWidth = YES;
                textLabel.font = smallTextFont;
                textLabel.textAlignment = NSTextAlignmentCenter;
                textLabel.numberOfLines = 1;
                textLabel.tag = TEXT_TAG;

                [BearingAnnotationView rotateText:textLabel
                                              pin:pin
                                         rotation:mapView.camera.heading];

                [self addSubview:textLabel];
            }
        }

        [self layoutIfNeeded];
    }
}

+ (MKAnnotationView *)viewForPin:(id<MapPin>)pin
                         mapView:(MKMapView *)mapView
                       urlAction:(bool (^__nullable)(id<MapPin>, NSURL *url,
                                                     UIView *source))urlAction {

    MKAnnotationView *annotationView = nil;

    if (!pin.pinHasBearing) {
        NSString *ident = [NSString stringWithFormat:@"stop"];
        MKPinAnnotationView *view = (MKPinAnnotationView *)[mapView
            dequeueReusableAnnotationViewWithIdentifier:ident];

        if (view == nil) {
            view = [[MKPinAnnotationView alloc] initWithAnnotation:pin
                                                   reuseIdentifier:ident];
        }

        view.annotation = pin;

        if ([view respondsToSelector:@selector(pinTintColor)] &&
            pin.pinTint != nil) {
            view.pinTintColor = pin.pinTint;
        } else {

            switch (pin.pinColor) {
            default:
            case MAP_PIN_COLOR_RED:
                view.pinTintColor = [UIColor redColor];
                break;

            case MAP_PIN_COLOR_GREEN:
                view.pinTintColor = [UIColor greenColor];
                break;

            case MAP_PIN_COLOR_PURPLE:
                view.pinTintColor = [UIColor purpleColor];
                break;

            case MAP_PIN_COLOR_BLUE:
                view.pinTintColor = [UIColor blueColor];
                break;

            case MAP_PIN_COLOR_WHITE:
                view.pinTintColor = [UIColor whiteColor];
                break;
            }
        }

        annotationView = view;
    } else {
        NSString *ident = [NSString stringWithFormat:@"bearing"];

        BearingAnnotationView *view = (BearingAnnotationView *)[mapView
            dequeueReusableAnnotationViewWithIdentifier:ident];

        if (view == nil) {
            view = [[BearingAnnotationView alloc] initWithAnnotation:pin
                                                     reuseIdentifier:ident];
        }

        view.annotation = pin;

        [view updateDirectionalAnnotationView:mapView];

        annotationView = view;
    }

    NSMutableString *markedUpSubtitle = [NSMutableString
        stringWithString:pin.pinMarkedUpType != nil ? pin.pinMarkedUpType
                                                    : @""];

    if ([pin respondsToSelector:@selector(pinMarkedUpStopId)] &&
        pin.pinMarkedUpStopId != nil) {
        [markedUpSubtitle
            appendFormat:markedUpSubtitle.length > 0 ? @"\n" : @""];
        [markedUpSubtitle appendFormat:@"%@", pin.pinMarkedUpStopId];
    } else if ([pin respondsToSelector:@selector(pinStopId)] &&
               pin.pinStopId != nil) {
        [markedUpSubtitle
            appendFormat:markedUpSubtitle.length > 0 ? @"\n" : @""];
        [markedUpSubtitle
            appendFormat:@"#D%@", pin.pinStopId.markedUpLinkToStopId];
    }

    if ([pin respondsToSelector:@selector(pinMarkedUpSubtitle)] &&
        pin.pinMarkedUpSubtitle != nil) {
        [markedUpSubtitle
            appendFormat:markedUpSubtitle.length > 0 ? @"\n" : @""];
        [markedUpSubtitle appendString:pin.pinMarkedUpSubtitle];
    }

#ifdef DEBUGLOGGING
    if (DEBUG_ON_FOR_FILE) {
        [markedUpSubtitle appendFormat:@"\n#DDebug - class #b%@#b",
                                       NSStringFromClass(pin.class)];
    }
#endif

    NSString *actionText = nil;

    if ([pin pinActionMenu]) {

        if ([pin respondsToSelector:@selector
                 (pinAction:)]) { //  && [self.tappedAnnot mapTapped])
            if (([pin respondsToSelector:@selector(pinUseAction)] &&
                 pin.pinUseAction) ||
                !([pin respondsToSelector:@selector(pinUseAction)])) {
                actionText = nil;

                if ([pin respondsToSelector:@selector(pinActionText)]) {
                    actionText = [pin pinActionText];
                }

                if (actionText == nil) {
                    actionText =
                        NSLocalizedString(@"Choose this stop", @"button text");
                }
            }
        }

        if (actionText && actionText.length > 0) {
            [markedUpSubtitle
                appendFormat:markedUpSubtitle.length > 0 ? @"\n" : @""];
            [markedUpSubtitle appendFormat:@"#Laction:tap %@#T", actionText];
        }
    }

    if (markedUpSubtitle.length > 0) {

        // Adding multiline subtitle code

        LinkResponsiveTextView *subLabel =
            (LinkResponsiveTextView *)annotationView.detailCalloutAccessoryView;
        if (subLabel == nil) {
            subLabel = [[LinkResponsiveTextView alloc] init];
            annotationView.detailCalloutAccessoryView = subLabel;
            subLabel.backgroundColor = [UIColor clearColor];
        }

        subLabel.delegate = subLabel;
        subLabel.linkAction =
            ^bool(LinkResponsiveTextView *_Nonnull view, NSURL *_Nonnull url,
                  NSRange characterRange, UITextItemInteraction interaction) {
              return urlAction(pin, url, view);
            };

        subLabel.scrollEnabled = NO;
        subLabel.attributedText = [markedUpSubtitle
            attributedStringFromMarkUpWithFont:
                [UIFont monospacedDigitSystemFontOfSize:16.0]];

        const CGFloat sizeWidth = 310;
        CGSize sz = [subLabel sizeThatFits:CGSizeMake(sizeWidth, MAXFLOAT)];

        NSLayoutConstraint *width = [NSLayoutConstraint
            constraintWithItem:subLabel
                     attribute:NSLayoutAttributeWidth
                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                        toItem:nil
                     attribute:NSLayoutAttributeNotAnAttribute
                    multiplier:1
                      constant:sz.width];
        NSLayoutConstraint *height = [NSLayoutConstraint
            constraintWithItem:subLabel
                     attribute:NSLayoutAttributeHeight
                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                        toItem:nil
                     attribute:NSLayoutAttributeNotAnAttribute
                    multiplier:1
                      constant:sz.height];

        // [subLabel setNumberOfLines:0];
        [subLabel addConstraint:width];
        [subLabel addConstraint:height];
    }
    
    [annotationView setNeedsLayout];

    return annotationView;
}

@end
