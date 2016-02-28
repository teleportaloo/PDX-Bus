//
//  ProgressModal.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/19/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ProgressModalView.h"
#import "QuartzCore/QuartzCore.h"
#import "DebugLogging.h"

CGPathRef CreatePathWithRoundRect(CGRect rect, CGFloat cornerRadius);

#pragma mark ProgressModalView

@implementation ProgressModalView

@synthesize totalItems			=  totalItems;
@synthesize whirly				= _whirly;
@synthesize progress			= _progress;
@synthesize progressDelegate	= _progressDelegate;
@synthesize subText				= _subText;
@synthesize helpText            = _helpText;
@synthesize helpFrame           = _helpFrame;
@synthesize itemsDone           = _itemsDone;

- (void)dealloc {
	self.whirly = nil;
	self.progress = nil;
	self.progressDelegate = nil;
	self.subText = nil;
    self.helpText = nil;
    self.helpFrame = nil;
    [super dealloc];
}


/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

#define kActivityViewWidth				200
#define kActivityViewHeight				200
#define kProgressWidth					65
#define kProgressHeight					65
#define kTextHeight						25
#define kTextSpaceOffset				(kActivityViewHieght - ((kActivityViewHieght + kProgressHeight)/2))
#define kBarHeight						10
#define kTextWidth						kBarWidth
#define kBarWidth						(kActivityViewWidth - 20)
#define kBarGap							10
#define kMargin							0
#define kTopMargin						(15 + kMargin)
#define kButtonHeight					40
#define kButtonGap						5

- (void)buttonAction:(id)sender
{
	UIButton *button = sender;
	button.hidden = true;
	
	[self.progressDelegate ProgressDelegateCancel]; 
	
}

+ (bool)iOS7style
{
    return [[UIDevice currentDevice].systemVersion floatValue] >= 7.0;
}

+ (bool)iOS8style
{
    return [[UIDevice currentDevice].systemVersion floatValue] >= 8.0;
}

+ (ProgressModalView *)initWithSuper:(UIView *)back items:(int)items title:(NSString *)title delegate:(id<ProgressDelegate>)delegate
						 orientation:(UIInterfaceOrientation)orientation
{	
	ProgressModalView *top = [[[ProgressModalView alloc] initWithFrame:[back bounds]] autorelease];

	CGRect backFrame = [back frame];
	CGFloat quarterTurns = 0;
	
    // We don't have to do this in OS 8.  Whatever.
    if (![ProgressModalView iOS8style])
        {
            switch (orientation)
            {
                case UIInterfaceOrientationLandscapeLeft:
                    quarterTurns = 3;
                    break;
                case UIInterfaceOrientationLandscapeRight:
                    quarterTurns = 1;
                    break;
                case UIInterfaceOrientationUnknown:
                case UIInterfaceOrientationPortrait:
                    quarterTurns = 0;
                    break;
                case UIInterfaceOrientationPortraitUpsideDown:
                    quarterTurns = 2;
                    break;
            }
    }
	
	DEBUG_LOG(@"Quarter turns %f\n", quarterTurns);

	
	if (quarterTurns > 0)
	{
#define swap(X,Y) temp = (X); (X) = (Y); Y = temp;
		
		CGAffineTransform trans = CGAffineTransformMakeRotation(quarterTurns * M_PI/2);
		
		
		// top.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
		
		
	
		if (quarterTurns != 2)
		{
			CGFloat temp;
			swap(backFrame.size.height, backFrame.size. width);
			
			// I found these magic numbers by trial and error. I'm not proud!
			trans = CGAffineTransformTranslate(trans, -128, 130);
		//	frame.origin.x = -125;
		//	frame.origin.y = 140;
		}
		[top setTransform:trans];
	}
	
    /*
	RoundedTransparentRect *fullScreen = [[RoundedTransparentRect alloc] initWithFrame:CGRectMake(
																			backFrame.origin.x + kMargin,
																			backFrame.origin.y + kTopMargin,
																			(backFrame.size.width  - kMargin *2),
																			(backFrame.size.height - kTopMargin - kMargin)
																			)];
	
	fullScreen.BACKGROUND_OPACITY  = 0.60;
	fullScreen.R				   = 0.5;
	fullScreen.G				   = 0.5;
	fullScreen.B				   = 0.5;
	
	fullScreen.opaque = NO;
	*/
    
    UIView *fullScreen = [[UIView alloc] initWithFrame:CGRectMake(
                                                                                                  backFrame.origin.x + kMargin,
                                                                                                  backFrame.origin.y + kTopMargin,
                                                                                                  (backFrame.size.width  - kMargin *2),
                                                                                                  (backFrame.size.height - kTopMargin - kMargin)
                                                                                                  )];
    
    fullScreen.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.6];
	
	fullScreen.opaque = NO;
     
     
 	[top addSubview:fullScreen];
	
	[fullScreen release];
	
	CGRect frontFrame = CGRectMake(
								   (backFrame.size.width - kActivityViewWidth) /2,
								   (backFrame.size.height - kActivityViewHeight) /2 - (kButtonGap+kButtonHeight)/2,
								   kActivityViewWidth,
								   kActivityViewHeight										
								   );

	RoundedTransparentRect *frontWin = [[RoundedTransparentRect alloc] initWithFrame:frontFrame];
	
	frontWin.BACKGROUND_OPACITY =  0.80;
	frontWin.R				    =  112.0/255.0;
	frontWin.G				    =  138.0/255.0;
	frontWin.B				    =  144.0/255.0;
	
	frontWin.opaque = NO;
	
	[top addSubview:frontWin];
	
	top.whirly = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
	top.whirly.frame = CGRectMake((kActivityViewWidth - kProgressWidth)/2,
								  (kActivityViewHeight -kProgressHeight)/2,  
								  kProgressWidth,
								  kProgressHeight);
	
	
	
	[frontWin addSubview:top.whirly];
				   
		
	[top.whirly startAnimating];
	
	CGRect subframe = CGRectMake((kActivityViewWidth-kTextWidth)/2, 
								 ((top.whirly.frame.origin.y + kProgressHeight) + (kActivityViewWidth - kBarHeight-kBarGap)) / 2 - kTextHeight/2, 
								 kTextWidth, 
								 kTextHeight);
	
	UILabel *subtextView = [[[UILabel alloc] initWithFrame:subframe] autorelease];
	
	subtextView.text = nil;
	subtextView.opaque = NO;
	subtextView.backgroundColor = [UIColor clearColor];
	subtextView.textColor = [UIColor whiteColor];
	subtextView.textAlignment = NSTextAlignmentCenter;
	subtextView.adjustsFontSizeToFitWidth = NO;
	subtextView.font = [UIFont boldSystemFontOfSize:12];
	top.subText = subtextView;
	
	[frontWin addSubview:subtextView];
	
    top.totalItems = items;
    
    CGRect frame = CGRectMake((kActivityViewWidth-kBarWidth)/2,
                              (kActivityViewHeight - kBarHeight-kBarGap) ,
                              kBarWidth,
                              kBarHeight);
    top.progress = [[[UIProgressView alloc] initWithFrame:frame] autorelease];
    top.progress.progressViewStyle = UIProgressViewStyleDefault;
    top.progress.progress = 0.0;
    
    if (items == 1)
    {
        top.progress.hidden = YES;
    }
    
    [frontWin addSubview:top.progress];
    
    
    [frontWin autorelease];
	
	if (delegate)
	{
		top.progressDelegate = delegate;
	
		UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		
		[cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];	
		

		cancelButton.frame = CGRectMake(
										frontFrame.origin.x,
										frontFrame.origin.y + frontFrame.size.height + kButtonGap,
										kActivityViewWidth,
										kButtonHeight);
    
		[cancelButton addTarget:top action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];	
        
        if ([ProgressModalView iOS7style])
        {
            cancelButton.backgroundColor = [UIColor whiteColor];
        }
		
		[cancelButton setTitleColor:[UIColor colorWithRed:frontWin.R green:frontWin.G blue:frontWin.B alpha:1.0] forState:UIControlStateNormal];
		[top addSubview:cancelButton];
        
        cancelButton.hidden = NO;
        
        [top bringSubviewToFront:cancelButton];
        
	}
    
    double y = frontFrame.origin.y + frontFrame.size.height + 2 * kButtonGap + kButtonHeight;
    double width = kActivityViewWidth * 1.5;
	CGRect helpOuterFrame = CGRectMake(frontFrame.origin.x - (width-kActivityViewWidth)/2,
								 y,
								 width,
								 kButtonHeight * 2 );
    
    CGRect helpInnerFrame = CGRectInset(helpOuterFrame, 5, 5);
    
	
	UILabel *helpTextView = [[[UILabel alloc] initWithFrame:helpInnerFrame] autorelease];
	
	helpTextView.text = nil;
	helpTextView.opaque = NO;
	helpTextView.backgroundColor = [UIColor clearColor];
    helpTextView.lineBreakMode = NSLineBreakByWordWrapping;
    helpTextView.numberOfLines = 10;
	helpTextView.textColor = [UIColor whiteColor];
	helpTextView.textAlignment = NSTextAlignmentCenter;
	helpTextView.adjustsFontSizeToFitWidth = NO;
	helpTextView.font = [UIFont boldSystemFontOfSize:16];
    helpTextView.hidden = YES;
	top.helpText = helpTextView;
    helpTextView.layer.masksToBounds = YES;
    helpTextView.layer.cornerRadius = 5.0;
	
	[top addSubview:helpTextView];

	
	if (title !=nil)
	{
		CGRect titleFrame = CGRectMake((kActivityViewWidth-kTextWidth)/2, (kBarGap) , kTextWidth, kTextHeight);
		
		UILabel *textView = [[[UILabel alloc] initWithFrame:titleFrame] autorelease];
		
		textView.text = title;
		textView.opaque = NO;
		textView.backgroundColor = [UIColor clearColor];
		textView.textColor = [UIColor whiteColor];
		textView.textAlignment = NSTextAlignmentCenter;
		textView.adjustsFontSizeToFitWidth = YES;
		textView.font = [UIFont boldSystemFontOfSize:17];
		// top.subText = textView;
		
		[frontWin addSubview:textView];
		
	}

	return top;
}

- (void) addSubtext:(NSString *)subtext
{
	if (self.subText)
	{
		self.subText.text = subtext;
	}
}

- (void) addHelpText:(NSString *)helpText
{
    self.helpText.text = helpText;
    
    if (helpText == nil)
    {
        self.helpText.hidden = YES;
        self.helpFrame.hidden = YES;
    }
    else
    {
                
        CGRect rect = self.helpText.frame;
        
        rect.size =[helpText sizeWithFont:self.helpText.font constrainedToSize:self.helpText.frame.size lineBreakMode:NSLineBreakByWordWrapping];
        rect.size.height += 10;
        
        self.helpText.frame = rect;
        
        self.helpText.hidden = NO;
        self.helpFrame.hidden = NO;
        
    }
    

}

- (void)totalItems:(int)total
{
    self.totalItems = total;
    
    if (total == 0)
    {
        self.totalItems = 1;
    }
    
    if (self.totalItems > 1)
    {
        self.progress.hidden = NO;
    }
    else
    {
        self.progress.hidden = YES;
    }
    
    [self itemsDone:self.itemsDone];
}

- (void) itemsDone:(int)done
{
    self.itemsDone = done;
	self.progress.progress = (float)done/(float)self.totalItems;
}


@end

#pragma mark -
#pragma mark RoundedTransparentRect

@implementation RoundedTransparentRect

@synthesize BACKGROUND_OPACITY;
@synthesize R;
@synthesize G;
@synthesize B;


- (id)initWithFrame:(CGRect)frame
{
	return [super initWithFrame:frame];
}


CGPathRef CreatePathWithRoundRect(CGRect rect, CGFloat cornerRadius)
{

	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL,
					  rect.origin.x,
					  rect.origin.y + rect.size.height - cornerRadius);
	
	// Top left
	CGPathAddArcToPoint(path, NULL,
						rect.origin.x,
						rect.origin.y,
						rect.origin.x + rect.size.width,
						rect.origin.y,
						cornerRadius);
	
	// Top right
	CGPathAddArcToPoint(path, NULL,
						rect.origin.x + rect.size.width,
						rect.origin.y,
						rect.origin.x + rect.size.width,
						rect.origin.y + rect.size.height,
						cornerRadius);
	
	// Bottom right
	CGPathAddArcToPoint(path, NULL,
						rect.origin.x + rect.size.width,
						rect.origin.y + rect.size.height,
						rect.origin.x,
						rect.origin.y + rect.size.height,
						cornerRadius);
	
	// Bottom left
	CGPathAddArcToPoint(path, NULL,
						rect.origin.x,
						rect.origin.y + rect.size.height,
						rect.origin.x,
						rect.origin.y,
						cornerRadius);
	
	CGPathCloseSubpath(path);
	
	return path;
}

- (void)drawRect:(CGRect)rect
{
    const CGFloat ROUND_RECT_CORNER_RADIUS = 10.0;
    CGPathRef roundRectPath =
        CreatePathWithRoundRect(rect, ROUND_RECT_CORNER_RADIUS);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextSetRGBFillColor(context, R, G, B, BACKGROUND_OPACITY);
    CGContextAddPath(context, roundRectPath);
    CGContextFillPath(context);
	
    const CGFloat STROKE_OPACITY = 0.25;
    CGContextSetRGBStrokeColor(context, 1, 1, 1, STROKE_OPACITY);
    CGContextAddPath(context, roundRectPath);
    CGContextStrokePath(context);
	
    CGPathRelease(roundRectPath);
}

@end
