//
//  FlashViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/31/09.



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "FlashViewController.h"
#import "TorchController.h"



@implementation FlashViewController
@synthesize flashTimer = _flashTimer;


#define kColors 4

- (void)dealloc {
    if (self.flashTimer)
    {
        [self.flashTimer invalidate];
    }
	self.flashTimer = nil;
    if (_torch)
    {
        [_torch release];
    }
    [super dealloc];
}

- (id)init
{
    if ((self = [super init]))
    {
        if ([TorchController supported])
        {
            _torch = [[TorchController alloc] init];
        }
    }
    
    return self;
}

- (void)infoAction:(id)sender
{
    UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Info", @"Alert title")
                                                       message:NSLocalizedString(@"This flashing screen is intended to be used to catch the attention of a bus operator at night.\n\nNote: the screen will not dim while this is displayed, so this will drain the battery quicker.", @"Warning text")
													  delegate:nil
											 cancelButtonTitle:NSLocalizedString(@"OK", @"Button text")
											 otherButtonTitles:nil ] autorelease];
	[alert show];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event { 
	[[self navigationController] popViewControllerAnimated:YES];
}

- (void)changeColor:(NSTimer *)timer {
	switch (_color)
	{
		case 0:
			self.view.backgroundColor = [UIColor blackColor];
			break;
		case 1:
			self.view.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:1.0];
			break;
		case 2:
			self.view.backgroundColor = [UIColor blackColor];
			break;
		case 3:
			self.view.backgroundColor = [UIColor whiteColor];
			break;
	}
	_color = ( _color +1 ) % kColors;
	[self.view setNeedsDisplay];
    if (_torch)
    {
        [_torch toggle];
    }
}

- (void)viewWillAppear:(BOOL)animated 
{

    NSDate *date = [NSDate date];
    _color = 0;
#ifdef ORIGINAL_IPHONE
    NSDate *oneSecondFromNow = [date addTimeInterval:0.1];
#else
    NSDate *oneSecondFromNow = [date dateByAddingTimeInterval:0.1];
#endif
	self.flashTimer = [[[NSTimer alloc] initWithFireDate:oneSecondFromNow interval:0.25 target:self selector:@selector(changeColor:) userInfo:nil repeats:YES] autorelease];

    [[NSRunLoop currentRunLoop] addTimer:self.flashTimer forMode:NSDefaultRunLoopMode];
    self.title = NSLocalizedString(@"Flashing Light", @"Screen title");
	
	UIBarButtonItem *info = [[[UIBarButtonItem alloc]
                              initWithTitle:NSLocalizedString(@"info", @"Button text")
							  style:UIBarButtonItemStyleBordered
							  target:self action:@selector(infoAction:)] autorelease];
	
	
	self.navigationItem.rightBarButtonItem = info;
	
	//[[self navigationController] setToolbarHidden:YES animated:YES];

	[UIApplication sharedApplication].idleTimerDisabled = YES;
	
	
	UILabel *label;
		
#define TEXT_HEIGHT 20
#define TOOLBAR_HEIGHT 40
	
	CGRect frame = self.view.frame;
	CGRect rect = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height - TEXT_HEIGHT - TOOLBAR_HEIGHT*2, frame.size.width, TEXT_HEIGHT);
	
	label = [[UILabel alloc] initWithFrame:rect];
	label.font = [UIFont boldSystemFontOfSize:20];
	label.adjustsFontSizeToFitWidth = YES;
	label.numberOfLines = 1;
	label.textAlignment = NSTextAlignmentCenter;
	label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	label.highlightedTextColor = [UIColor redColor];
	label.textColor = [UIColor redColor];
	label.backgroundColor = [UIColor clearColor];
	label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:label];
    label.text = NSLocalizedString(@"Device sleep disabled!", @"Button warning");
	[label release];
    
    if (_torch)
    {
        [_torch on];
    }
    [super viewWillAppear:animated];

}

- (void)viewWillDisappear:(BOOL)animated
{
	[UIApplication sharedApplication].idleTimerDisabled = NO;
    
    if (self.flashTimer)
    {
        [self.flashTimer invalidate];
        self.flashTimer = nil;
    }
    
    if (_torch)
    {
        [_torch off];
    }
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)toggleLed:(id)sender
{
    UISegmentedControl *segControl = sender;
	switch (segControl.selectedSegmentIndex)
	{
		case 0:	
		{
            [UserPrefs getSingleton].flashLed = YES;
            break;
		}
		case 1:	
		{
			[UserPrefs getSingleton].flashLed = NO;
			break;
		}
	}
    
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    if (_torch)
    {
        // add a segmented control to the button bar
        UISegmentedControl	*buttonBarSegmentedControl;
        buttonBarSegmentedControl = [[UISegmentedControl alloc] initWithItems:
								 [NSArray arrayWithObjects:
                                        NSLocalizedString(@"Flash LED", @"Short segment button text"),
                                        NSLocalizedString(@"LED Off",   @"Short segment button text"),
                                            nil]
                                    ];
        [buttonBarSegmentedControl addTarget:self action:@selector(toggleLed:) forControlEvents:UIControlEventValueChanged];
    
        if ([UserPrefs getSingleton].flashLed)
        {
            buttonBarSegmentedControl.selectedSegmentIndex = 0.0;	// start by showing the normal picker
        }
        else
        {
            buttonBarSegmentedControl.selectedSegmentIndex = 1.0;
        }
        buttonBarSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        
        [self setSegColor:buttonBarSegmentedControl];
        
        UIBarButtonItem *segItem = [[UIBarButtonItem alloc] initWithCustomView:buttonBarSegmentedControl];	
	
        [toolbarItems addObject:segItem];
        [toolbarItems addObject:[CustomToolbar autoFlexSpace]];
       
        [segItem release];
        [buttonBarSegmentedControl release];
    }
    
    if ([UserPrefs getSingleton].ticketAppIcon)
    {
        [toolbarItems addObject:[self autoTicketAppButton]];
    }
}
    

@end

