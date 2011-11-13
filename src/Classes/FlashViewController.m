//
//  FlashViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/31/09.

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import "FlashViewController.h"
#import "TorchController.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"


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
	UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Info"
													   message:@"This flashing screen is intended to be used to catch the attention of a bus operator at night.\n\nNote: the screen will not dim while this is displayed, so this will drain the battery quicker."
													  delegate:nil
											 cancelButtonTitle:@"OK"
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
    NSDate *oneSecondFromNow = [date addTimeInterval:0.1];
	self.flashTimer = [[[NSTimer alloc] initWithFireDate:oneSecondFromNow interval:0.25 target:self selector:@selector(changeColor:) userInfo:nil repeats:YES] autorelease];

    [[NSRunLoop currentRunLoop] addTimer:self.flashTimer forMode:NSDefaultRunLoopMode];
	self.title = @"Flashing Light";
	
	UIBarButtonItem *info = [[[UIBarButtonItem alloc]
							  initWithTitle:@"info"
							  style:UIBarButtonItemStyleBordered
							  target:self action:@selector(infoAction:)] autorelease];
	
	
	self.navigationItem.rightBarButtonItem = info;
	
	[[self navigationController] setToolbarHidden:YES animated:YES];

	[UIApplication sharedApplication].idleTimerDisabled = YES;
	
	
	UILabel *label;
		
#define TEXT_HEIGHT 20
#define TOOLBAR_HEIGHT 40
	
	CGRect frame = self.view.frame;
	CGRect rect = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height - TEXT_HEIGHT - TOOLBAR_HEIGHT, frame.size.width, TEXT_HEIGHT);
	
	label = [[UILabel alloc] initWithFrame:rect];
	label.font = [UIFont boldSystemFontOfSize:20];
	label.adjustsFontSizeToFitWidth = YES;
	label.numberOfLines = 1;
	label.textAlignment = UITextAlignmentCenter;
	label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	label.highlightedTextColor = [UIColor redColor];
	label.textColor = [UIColor redColor];
	label.backgroundColor = [UIColor clearColor];
	label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:label];
	label.text = @"Device sleep disabled!";
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
            _prefs.flashLed = YES;
            break;
		}
		case 1:	
		{
			_prefs.flashLed = NO;
			break;
		}
	}
    
}

- (void)createToolbarItems
{
    NSArray *items = nil;
    if (_torch)
    {
        // add a segmented control to the button bar
        UISegmentedControl	*buttonBarSegmentedControl;
        buttonBarSegmentedControl = [[UISegmentedControl alloc] initWithItems:
								 [NSArray arrayWithObjects:@"Flash LED", @"LED Off", nil]];
        [buttonBarSegmentedControl addTarget:self action:@selector(toggleLed:) forControlEvents:UIControlEventValueChanged];
    
        if (_prefs.flashLed)
        {
            buttonBarSegmentedControl.selectedSegmentIndex = 0.0;	// start by showing the normal picker
        }
        else
        {
            buttonBarSegmentedControl.selectedSegmentIndex = 1.0;
        }
        buttonBarSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    
        int color = _prefs.toolbarColors;
	
        if (color == 0xFFFFFF)
        {
            buttonBarSegmentedControl.tintColor = [UIColor darkGrayColor];
        }
        else {
            buttonBarSegmentedControl.tintColor = [self htmlColor:color];
        }
    
        buttonBarSegmentedControl.backgroundColor = [UIColor clearColor];
	
        UIBarButtonItem *segItem = [[UIBarButtonItem alloc] initWithCustomView:buttonBarSegmentedControl];	
	
        items = [NSArray arrayWithObjects: [self autoDoneButton], [CustomToolbar autoFlexSpace], 
                 segItem, [CustomToolbar autoFlexSpace], nil];

        [segItem release];
        [buttonBarSegmentedControl release];
    }
    else
    {
        items = [NSArray arrayWithObjects: [self autoDoneButton], nil];
    }
    
     [self setToolbarItems:items animated:NO];
}
    

@end

