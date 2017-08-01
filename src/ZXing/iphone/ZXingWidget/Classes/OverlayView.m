// -*- Mode: ObjC; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

/**
 * Copyright 2009 Jeff Verkoeyen
 *
 * PDX Bus changes (c) 2012 Andrew Wallace
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OverlayView.h"
#import <AVFoundation/AVFoundation.h>

static const CGFloat kPadding = 10;
// static const CGFloat kLicenseButtonPadding = 10;

@interface OverlayView()
@property (nonatomic,retain) UILabel *instructionsLabel;
@end


@implementation OverlayView

@synthesize delegate, oneDMode;
@synthesize points = _points;
@synthesize toolbar;
@synthesize cropRect;
@synthesize instructionsLabel;
@synthesize displayedMessage;


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)theFrame cancelEnabled:(BOOL)isCancelEnabled oneDMode:(BOOL)isOneDModeEnabled {
  return [self initWithFrame:theFrame cancelEnabled:isCancelEnabled oneDMode:isOneDModeEnabled showLicense:YES];
}

- (UIImage*) getImage7:(NSString*)name old:(NSString *)old
{
    UIImage *icon = [UIImage imageNamed:name];
    
    return icon != nil ? icon :[UIImage imageNamed:old];
}

- (id) initWithFrame:(CGRect)theFrame cancelEnabled:(BOOL)isCancelEnabled oneDMode:(BOOL)isOneDModeEnabled showLicense:(BOOL)showLicenseButton {
    self = [super initWithFrame:theFrame];
    if( self ) {
        
        CGFloat rectSize = self.frame.size.width - kPadding * 2;
        if (!oneDMode) {
            cropRect = CGRectMake(kPadding, (self.frame.size.height - rectSize) / 2, rectSize, rectSize);
        } else {
            CGFloat rectSize2 = self.frame.size.height - kPadding * 2;
            cropRect = CGRectMake(kPadding, kPadding, rectSize, rectSize2);		
        }
        
        self.backgroundColor = [UIColor clearColor];
        self.oneDMode = isOneDModeEnabled;
        
        toolbar = [UIToolbar new];
        toolbar.barStyle = UIBarStyleDefault;
        
        // size up the toolbar and set its frame
        [toolbar sizeToFit];
        CGFloat toolbarHeight = [toolbar frame].size.height;
        CGRect mainViewBounds = self.bounds;
        [toolbar setFrame:CGRectMake(CGRectGetMinX(mainViewBounds),
                                     CGRectGetMinY(mainViewBounds) + CGRectGetHeight(mainViewBounds) - (toolbarHeight) + 2.0,
                                     CGRectGetWidth(mainViewBounds),
                                     toolbarHeight)];
        
        [self addSubview:toolbar];
        
        NSMutableArray *toolbarItems = [[[NSMutableArray alloc] init] autorelease];
        
        [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithImage:[self getImage7:@"750-home.png" old:@"53-house.png"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(cancel:)] autorelease]]; 
        
        if (showLicenseButton) {
            [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil] autorelease]]; 
            [toolbarItems addObject:[[[UIBarButtonItem alloc]
                                      initWithImage:[self getImage7:@"724-info.png" old:@"info_icon.png"]
                                      style:UIBarButtonItemStylePlain
                                      target:self action:@selector(showLicenseAlert:)] autorelease]];
            
        }
        
        [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                               target:nil
                                                                               action:nil] autorelease]]; 
        
        [toolbarItems addObject:[[[UIBarButtonItem alloc]
                                  initWithTitle:NSLocalizedString(@"Help", @"button text")
                                  style:UIBarButtonItemStylePlain
                                  target:self action:@selector(help:)] autorelease]];
        
        
        if (isCancelEnabled) {
            [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil] autorelease]]; 
            
            
            [toolbarItems addObject:[[[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                      target:self action:@selector(cancel:)] autorelease]];
            
        }
        // PDX Bus - add a flash button
        if ([OverlayView torchSupported])
        {
            [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil] autorelease]]; 
            [toolbarItems addObject:[[[UIBarButtonItem alloc]
                                      initWithImage:[UIImage imageNamed:@"61-brightness.png"]
                                      style:UIBarButtonItemStylePlain
                                      target:self action:@selector(flash:)] autorelease]];
        }
        self.toolbar.items = toolbarItems;
        
    }
    return self;
}

+(bool)torchSupported
{
    static bool checkDone = NO;
    static bool supported = NO;
    
    if (!checkDone)
    {
        Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
        if (captureDeviceClass != nil)
        {
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            
            if ([device hasTorch] && [device hasFlash])
            {
                supported = YES;
            }
        }
        checkDone = YES;
    }
    return supported;
}


- (void)setTorch:(BOOL)status {

    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        
        AVCaptureDevice *device = [captureDeviceClass defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        [device lockForConfiguration:nil];
        if ( [device hasTorch] ) {
            if ( status ) {
                [device setTorchMode:AVCaptureTorchModeOn];
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
            }
        }
        [device unlockForConfiguration];
        
    }
}


- (void)toggleTorch {
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        
        AVCaptureDevice *device = [captureDeviceClass defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        [device lockForConfiguration:nil];
        if ( [device hasTorch] ) {
            if ( [device torchMode] != AVCaptureTorchModeOn ) {
                [device setTorchMode:AVCaptureTorchModeOn];
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
            }
        }
        [device unlockForConfiguration];
        
    }
}

- (BOOL)torchIsOn {

    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        
        AVCaptureDevice *device = [captureDeviceClass defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if ( [device hasTorch] ) {
            return [device torchMode] == AVCaptureTorchModeOn;
        }
        [device unlockForConfiguration];
    }
    return NO;
}


- (void)flash:(id)sender {
    [self toggleTorch];
}

- (void)cancel:(id)sender {
	// call delegate to cancel this scanner
	if (delegate != nil) {
		[delegate cancelled];
	}
}

#define QR_CODES_TITLE NSLocalizedString(@"QR Codes", @"button title")

- (void)help:(id)sender {
    NSString *title = QR_CODES_TITLE;
    NSString *message = NSLocalizedString(@"TriMet has placed QR Codes at most stops and stations, just scan the code to see the arrivals.", @"help text for QR coddes");
    NSString *cancelTitle = NSLocalizedString(@"OK",@"button text");
    // NSString *viewTitle = NSLocalizedString(@"TriMet web site", @"button text");
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:nil];
    [av show];
    [av release];
}

- (void)showLicenseAlert:(id)sender {
    NSString *title = NSLocalizedStringWithDefaultValue(@"OverlayView license alert title", nil, [NSBundle mainBundle], @"License", @"License");
    NSString *message = NSLocalizedStringWithDefaultValue(@"OverlayView license alert message", nil, [NSBundle mainBundle], @"Scanning functionality provided by ZXing library, licensed under Apache 2.0 license.", @"Scanning functionality provided by ZXing library, licensed under Apache 2.0 license.");
    NSString *cancelTitle = NSLocalizedStringWithDefaultValue(@"OverlayView license alert cancel title", nil, [NSBundle mainBundle], @"OK", @"OK");
    NSString *viewTitle = NSLocalizedStringWithDefaultValue(@"OverlayView license alert view title", nil, [NSBundle mainBundle], @"View License", @"View License");

    UIAlertView *av = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:viewTitle, nil];
    [av show];
    [av release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if ([alertView.title isEqualToString:QR_CODES_TITLE] && buttonIndex == [alertView firstOtherButtonIndex])
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://trimet.org/qrcodes/index.htm"]];
    }
    else if (buttonIndex == [alertView firstOtherButtonIndex]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.apache.org/licenses/LICENSE-2.0.html"]];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) dealloc {
	[imageView release];
	[_points release];
    [instructionsLabel release];
    [displayedMessage release];
    [self setTorch:FALSE];
    [toolbar release];
	[super dealloc];
}


- (void)drawRect:(CGRect)rect inContext:(CGContextRef)context {
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
	CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y);
	CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
	CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y + rect.size.height);
	CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y);
	CGContextStrokePath(context);
}

- (CGPoint)map:(CGPoint)point {
    CGPoint center;
    center.x = cropRect.size.width/2;
    center.y = cropRect.size.height/2;
    float x = point.x - center.x;
    float y = point.y - center.y;
    int rotation = 90;
    switch(rotation) {
    case 0:
        point.x = x;
        point.y = y;
        break;
    case 90:
        point.x = -y;
        point.y = x;
        break;
    case 180:
        point.x = -x;
        point.y = -y;
        break;
    case 270:
        point.x = y;
        point.y = -x;
        break;
    }
    point.x = point.x + center.x;
    point.y = point.y + center.y;
    return point;
}

#define kTextMargin 10

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    if (displayedMessage == nil) {
        // PDXBus: changed this text
        self.displayedMessage = NSLocalizedStringWithDefaultValue(@"OverlayView displayed message", nil, [NSBundle mainBundle], @"Position a TriMet QR Code inside the viewfinder rectangle to scan it and show the arrivals.",  @"Position a TriMet QR Code inside the viewfinder rectangle to scan it and show the arrivals.");
    }
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    if (nil != _points) {
        //		[imageView.image drawAtPoint:cropRect.origin];
    }
    
    CGFloat white[4] = {1.0f, 1.0f, 1.0f, 1.0f};
    CGContextSetStrokeColor(c, white);
    CGContextSetFillColor(c, white);
    [self drawRect:cropRect inContext:c];
    
    //	CGContextSetStrokeColor(c, white);
    //	CGContextSetStrokeColor(c, white);
    CGContextSaveGState(c);
    if (oneDMode) {
        NSString *text = NSLocalizedStringWithDefaultValue(@"OverlayView 1d instructions", nil, [NSBundle mainBundle], @"Place a red line over the bar code to be scanned.", @"Place a red line over the bar code to be scanned.");
        UIFont *helvetica15 = [UIFont fontWithName:@"Helvetica" size:15];
        // CGSize textSize = [text sizeWithFont:helvetica15];
        CGSize textSize = [text sizeWithAttributes:@{NSFontAttributeName:helvetica15}];
        
        CGContextRotateCTM(c, M_PI/2);
        // Invert height and width, because we are rotated.
        CGPoint textPoint = CGPointMake(self.bounds.size.height / 2 - textSize.width / 2, self.bounds.size.width * -1.0f + 20.0f);
        // [text drawAtPoint:textPoint withFont:helvetica15];
        [text drawAtPoint:textPoint withAttributes:@{NSFontAttributeName:helvetica15}];
    }
    else {
        UIFont *font = [UIFont systemFontOfSize:18];
        CGSize constraint = CGSizeMake(rect.size.width  - 2 * kTextMargin, cropRect.origin.y);
        // CGSize displaySize = [self.displayedMessage sizeWithFont:font constrainedToSize:constraint];
        
        
        CGSize displaySize = [self.displayedMessage boundingRectWithSize:constraint
                                                                 options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin
                                                              attributes:@{NSFontAttributeName: font}
                                                                 context:nil].size;
        
        CGRect displayRect = CGRectMake((rect.size.width - displaySize.width) / 2 , cropRect.origin.y - displaySize.height, displaySize.width, displaySize.height);
        //[self.displayedMessage drawInRect:displayRect withFont:font lineBreakMode:UILineBreakModeWordWrap alignment:NSTextAlignmentCenter];
        [self.displayedMessage drawWithRect:displayRect
                                    options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin
                                 attributes:@{ NSFontAttributeName:font }
                                    context:nil];
        
        
    }
    CGContextRestoreGState(c);
    int offset = rect.size.width / 2;
    if (oneDMode) {
        CGFloat red[4] = {1.0f, 0.0f, 0.0f, 1.0f};
        CGContextSetStrokeColor(c, red);
        CGContextSetFillColor(c, red);
        CGContextBeginPath(c);
        //		CGContextMoveToPoint(c, rect.origin.x + kPadding, rect.origin.y + offset);
        //		CGContextAddLineToPoint(c, rect.origin.x + rect.size.width - kPadding, rect.origin.y + offset);
        CGContextMoveToPoint(c, rect.origin.x + offset, rect.origin.y + kPadding);
        CGContextAddLineToPoint(c, rect.origin.x + offset, rect.origin.y + rect.size.height - kPadding);
        CGContextStrokePath(c);
    }
    if( nil != _points ) {
        CGFloat blue[4] = {0.0f, 1.0f, 0.0f, 1.0f};
        CGContextSetStrokeColor(c, blue);
        CGContextSetFillColor(c, blue);
        if (oneDMode) {
            CGPoint val1 = [self map:[[_points objectAtIndex:0] CGPointValue]];
            CGPoint val2 = [self map:[[_points objectAtIndex:1] CGPointValue]];
            CGContextMoveToPoint(c, offset, val1.x);
            CGContextAddLineToPoint(c, offset, val2.x);
            CGContextStrokePath(c);
        }
        else {
            CGRect smallSquare = CGRectMake(0, 0, 10, 10);
            for( NSValue* value in _points ) {
                CGPoint point = [self map:[value CGPointValue]];
                smallSquare.origin = CGPointMake(
                                                 cropRect.origin.x + point.x - smallSquare.size.width / 2,
                                                 cropRect.origin.y + point.y - smallSquare.size.height / 2);
                [self drawRect:smallSquare inContext:c];
            }
        }
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 - (void) setImage:(UIImage*)image {
 //if( nil == imageView ) {
// imageView = [[UIImageView alloc] initWithImage:image];
// imageView.alpha = 0.5;
// } else {
 imageView.image = image;
 //}
 
 //CGRect frame = imageView.frame;
 //frame.origin.x = self.cropRect.origin.x;
 //frame.origin.y = self.cropRect.origin.y;
 //imageView.frame = CGRectMake(0,0, 30, 50);
 
 //[_points release];
 //_points = nil;
 //self.backgroundColor = [UIColor clearColor];
 
 //[self setNeedsDisplay];
 }
 */

////////////////////////////////////////////////////////////////////////////////////////////////////
- (UIImage*) image {
	return imageView.image;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) setPoints:(NSMutableArray*)pnts {
    [pnts retain];
    [_points release];
    _points = pnts;
	
    if (pnts != nil) {
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    }
    [self setNeedsDisplay];
}

- (void) setPoint:(CGPoint)point {
    if (!_points) {
        _points = [[NSMutableArray alloc] init];
    }
    if (_points.count > 3) {
        [_points removeObjectAtIndex:0];
    }
    [_points addObject:[NSValue valueWithCGPoint:point]];
    [self setNeedsDisplay];
}




@end
