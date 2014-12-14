//
//  BigRouteView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/26/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BigRouteView.h"
#import "Departure.h"
#import "TriMetRouteColors.h"

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
	UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Info", @"alert title")
													   message:NSLocalizedString(@"This Bus line identifier screen is intended as an alternative to the large-print book provided to partially sighted travelers to let the operator know which bus they need to board.\n\nNote: the screen will not dim while this is displayed, so this will drain the battery quicker.",@"feature information")
													  delegate:nil
											 cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
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
	label.textColor = [UIColor whiteColor];
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

	
	self.title = NSLocalizedString(@"Bus line identifier", @"screen title");
	[self createTextView];

    ROUTE_COL *col = [TriMetRouteColors rawColorForRoute:self.departure.route];
	
    
    if (col == nil)
    {
        self.view.backgroundColor = [UIColor redColor];
    }
    else
    {
        self.view.backgroundColor = [UIColor colorWithRed:col->back_r green:col->back_g blue:col->back_b alpha:1.0];
    }
    
    
	
	UIBarButtonItem *info = [[[UIBarButtonItem alloc]
							  initWithTitle:NSLocalizedString(@"info", @"button text")
							  style:UIBarButtonItemStyleBordered
							  target:self action:@selector(infoAction:)] autorelease];
	

	self.navigationItem.rightBarButtonItem = info;
	[[self navigationController] setToolbarHidden:NO animated:NO];
		
	[UIApplication sharedApplication].idleTimerDisabled = YES;
    [super viewWillAppear:animated];
	
}

- (void)viewWillDisappear:(BOOL)animated
{
	[UIApplication sharedApplication].idleTimerDisabled = NO;
    [super viewWillDisappear:animated];
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event { 
	[[self navigationController] popViewControllerAnimated:YES];
}

- (void)dealloc {
	self.departure = nil;
	self.textView = nil;
	
    [super dealloc];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    [toolbarItems addObject:[CustomToolbar autoNoSleepWithTarget:self action:@selector(infoAction:)]];
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}



@end
