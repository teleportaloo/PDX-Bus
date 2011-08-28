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


@implementation FlashViewController
@synthesize flashTimer = _flashTimer;

#define kColors 4

- (void)dealloc {
	self.flashTimer = nil;
    [super dealloc];
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
	switch (color)
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
	color = ( color +1 ) % kColors;
	[self.view setNeedsDisplay];
}

- (void)viewWillAppear:(BOOL)animated {

    NSDate *date = [NSDate date];
    color = 0;
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
	
	CGRect frame = self.view.frame;
	CGRect rect = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height - TEXT_HEIGHT, frame.size.width, TEXT_HEIGHT);
	
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

}

- (void)viewWillDisappear:(BOOL)animated
{
	[UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

@end

