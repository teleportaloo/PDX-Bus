//
//  LocatingTableView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/4/09.
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

#import "LocatingTableView.h"
#import "RootViewController.h"
#import "debug.h"

#define kLocatingRowHeight		60.0
#define MAX_AGE					-30.0
#define TEXT_TAG 1

@implementation LocatingTableView

@synthesize progressInd			= _progressInd;
@synthesize locationManager		= _locationManager;
@synthesize lastLocation		= _lastLocation;
@synthesize progressCell		= _progressCell;
@synthesize timeStamp			= _timeStamp;

- (void)dealloc {
	self.locationManager.delegate	= nil;
	self.locationManager			= nil;
	self.progressInd				= nil;
	self.lastLocation				= nil;
	self.progressCell				= nil;
	self.timeStamp					= nil;
	
    [super dealloc];
}


- (id) init
{
	if ((self = [super init]))
	{
		self.locationManager = [[[CLLocationManager alloc] init] autorelease];
		self.locationManager.delegate = self; // Tells the location manager to send updates to this object
		failed = false;
	}
	return self;
}

#pragma mark Check the last location

- (bool)checkLocation
{
	
    DEBUG_LOG(@"Timeinterval %f\n",[self.timeStamp timeIntervalSinceNow] );
    // This line may be confusing - MAX_AGE is negative, so something older is even more negative
	if (self.timeStamp == nil || [self.timeStamp timeIntervalSinceNow] < MAX_AGE)
	{
		return false;
	}
	
	if (waitingForLocation)
	{
		[[(RootViewController *)[self.navigationController topViewController] table] reloadData];
	}

	
	if (self.lastLocation.horizontalAccuracy > accuracy)
	{		
		return false;
	}

	if (waitingForLocation)
	{
		waitingForLocation = NO;
		[self reinit];
		[self stopAnimating:YES];
	}
	
	[self.locationManager stopUpdatingLocation];

	NSDate *soon = [[NSDate date] addTimeInterval:0.1];
	NSTimer *timer = [[[NSTimer alloc] initWithFireDate:soon interval:0.1 target:self selector:@selector(delayedCompletion:) userInfo:nil repeats:NO] autorelease];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	
	return true;
}

#pragma mark ViewControllerBase methods

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

- (void)createToolbarItems
{
	
	NSArray *items = [NSArray arrayWithObjects: [self autoDoneButton], [CustomToolbar autoFlexSpace], nil];
	[self setToolbarItems:items animated:NO];
}

#pragma mark View methods

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

#pragma mark Subclass methods

- (void)reinit
{
	
}

- (void)located
{
	
}

#pragma mark UI helper functions

- (int)LocationTextTag
{
	return TEXT_TAG;
}

-(NSString *)formatDistance:(double)distance
{
	NSString *str = nil;
	if (distance < 500)
	{
		str = [NSString stringWithFormat:@"%d ft (%d meters)", (int)(distance * 3.2808398950131235),
			   (int)(distance) ];
	}
	else
	{
		str = [NSString stringWithFormat:@"%.2f miles (%.2f km)", (float)(distance / 1609.344),
			   (float)(distance / 1000) ];
	}	
	return str;
}

- (UITableViewCell *)accuracyCellWithReuseIdentifier:(NSString *)identifier {
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, local time, and quarter image of the time zone.
	 */
	CGRect rect;
	
	rect = CGRectMake(0.0, 0.0, 320.0, kLocatingRowHeight);
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:rect reuseIdentifier:identifier] autorelease];
	
#define LEFT_COLUMN_OFFSET 20.0
#define LEFT_COLUMN_WIDTH 30.0
#define LEFT_COLUMN_HEIGHT 35.0
	
#define MAIN_FONT_SIZE 16.0
#define LABEL_HEIGHT (kLocatingRowHeight - 10.0)
#define LABEL_COLUMN_OFFSET (LEFT_COLUMN_OFFSET + LEFT_COLUMN_WIDTH + 5.0)
#define LABEL_COLUMN_WIDTH  (260.0 - LEFT_COLUMN_WIDTH)
	
	CGRect frame = CGRectMake(LEFT_COLUMN_OFFSET, (kLocatingRowHeight - LEFT_COLUMN_HEIGHT) / 2.0, LEFT_COLUMN_WIDTH, LEFT_COLUMN_HEIGHT);
	self.progressInd = [[[UIActivityIndicatorView alloc] initWithFrame:frame] autorelease];
	self.progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
	self.progressInd.hidesWhenStopped = YES;
	[self.progressInd sizeToFit];
	self.progressInd.autoresizingMask =  (UIViewAutoresizingFlexibleTopMargin |
										 UIViewAutoresizingFlexibleBottomMargin);
	[cell.contentView addSubview:self.progressInd];
	
	
	/*
	 Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
	 */
	UILabel *label;
	
	rect = CGRectMake(LABEL_COLUMN_OFFSET, (kLocatingRowHeight - LABEL_HEIGHT) / 2.0, LABEL_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = TEXT_TAG;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	label.adjustsFontSizeToFitWidth = NO;
	label.numberOfLines = 0;
	label.lineBreakMode = UILineBreakModeWordWrap;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	label.textColor  = [UIColor blackColor];
	label.autoresizingMask =  (UIViewAutoresizingFlexibleWidth);
	label.backgroundColor = [UIColor clearColor];
	[label release];
	
	[cell.contentView layoutSubviews];
	
	self.progressCell = cell;
	
	return cell;
}

- (void)delayedCompletion:(NSTimer*)theTimer
{
	[self located];
}

- (void)stopAnimating:(bool)refresh
{
	[self.progressInd stopAnimating];
	
	if (refresh)
	{
		[[(RootViewController *)[self.navigationController topViewController] table] reloadData];
	}
	
}

- (void)startAnimating:(bool)refresh
{
	[self.progressInd startAnimating];
	
	if (refresh)
	{
		[[(RootViewController *)[self.navigationController topViewController] table] reloadData];
	}
}

#pragma mark Location Manager callbacks

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
	
	
	if ([newLocation.timestamp timeIntervalSinceNow] < MAX_AGE)
	{
		// too old!
		return;
	}
	
	self.lastLocation = newLocation;
	self.timeStamp    = newLocation.timestamp;
	
	if (!waitingForLocation)
	{
		return;
	}
	
	[self checkLocation];
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	DEBUG_LOG(@"location error %@\n", [error localizedDescription]);
    
    switch (error.code)
    {
        default:
        case kCLErrorLocationUnknown:
            break;
        case kCLErrorDenied:
            [self failedToLocate];
            waitingForLocation = NO;
            failed = YES;
            [self stopAnimating:YES];
            [self reinit];
            [self reloadData];
            break;
    }
}

- (void) failedToLocate
{
	UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Locate stops"
													   message:@"Unable to find location"
													  delegate:nil
											 cancelButtonTitle:@"OK"
											 otherButtonTitles:nil] autorelease];
	[alert show];
	
	[[self navigationController] popViewControllerAnimated:YES];
	
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:YES];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[self.locationManager stopUpdatingLocation];
}

- (void)didEnterBackground {
	[self.locationManager stopUpdatingLocation];
}




@end

