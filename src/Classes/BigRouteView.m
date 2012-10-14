//
//  BigRouteView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/26/10.
//  Copyright 2010. All rights reserved.
//

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

#import "BigRouteView.h"
#import "Departure.h"
#import "TriMetRouteColors.h"
#import "TriMetTimesAppDelegate.h"

@implementation BigRouteView

@synthesize departure = _departure;
@synthesize textView  = _textView;

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return YES;
}

// iOS6 methods

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)infoAction:(id)sender
{
	UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Info"
													   message:@"This Bus line identifier screen is intended as an alternative to the large-print book provided to partially sighted travelers to let the operator know which bus they need to board.\n\nNote: the screen will not dim while this is displayed, so this will drain the battery quicker."
													  delegate:nil
											 cancelButtonTitle:@"OK"
											 otherButtonTitles:nil ] autorelease];
	[alert show];
}

- (void)createTextView
{
	UILabel *label;
	
	if (self.textView !=nil)
	{
		[self.textView removeFromSuperview];
	}
	
	CGRect rect = self.view.frame;
	label = [[UILabel alloc] initWithFrame:rect];
	label.font = [UIFont boldSystemFontOfSize:260];
	label.adjustsFontSizeToFitWidth = YES;
	label.numberOfLines = 1;
	label.textAlignment = UITextAlignmentCenter;
	label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	label.highlightedTextColor = [UIColor whiteColor];
	label.textColor = [UIColor blackColor];
	label.backgroundColor = [UIColor clearColor];
	label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:label];
	
	ROUTE_COL *col = [TriMetRouteColors rawColorForRoute:self.departure.route];
	
	if (col == nil)
	{
		label.text = self.departure.route;
	}
	else {
		label.text = col->type;
		label.textColor  = [UIColor colorWithRed:col->r green:col->g blue:col->b alpha:1.0];
	}
	
	self.textView = label;
	[label release];
	
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self createTextView];
}

- (void)viewWillAppear:(BOOL)animated {

	
	self.title = @"Bus line identifier";
	[self createTextView];
	
	UIBarButtonItem *info = [[[UIBarButtonItem alloc]
							  initWithTitle:@"info"
							  style:UIBarButtonItemStyleBordered
							  target:self action:@selector(infoAction:)] autorelease];
	

	self.navigationItem.rightBarButtonItem = info;
	[[self navigationController] setToolbarHidden:NO animated:NO];
		
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	
}

- (void)viewWillDisappear:(BOOL)animated
{
	[UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event { 
	[[self navigationController] popViewControllerAnimated:YES];
}

- (void)dealloc {
	self.departure = nil;
	self.textView = nil;
	
    [super dealloc];
}

- (void)createToolbarItems
{	
	[self setToolbarItems:[NSArray arrayWithObjects: 
						   [self autoDoneButton], 
						   [CustomToolbar autoFlexSpace], 
						   [CustomToolbar autoNoSleepWithTarget:self action:@selector(infoAction:)],  
						   [CustomToolbar autoFlexSpace],  
						   [self autoFlashButton], nil] 
				 animated:NO];
}



@end
