//
//  TripPlannerDateView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/2/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripPlannerDateView.h"
#import "TableViewWithToolbar.h"
#import "TripPlannerLocatingView.h"
#import "TripPlannerOptions.h"

#define kSectionDateDeparture 1
#define kSectionDateArrival   2
#define kSectionDateDepartNow 0


@implementation TripPlannerDateView

@synthesize datePickerView = _datePickerView;
@synthesize pickerView = _pickerView;
@synthesize userFaves = _userFaves;
@synthesize popBack = _popBack;

#define kDatePickerSections 1
#define kDatePickerButtonsPerSection 3

- (void)dealloc {
	self.datePickerView = nil;
	self.pickerView = nil;
	self.userFaves = nil;
    [super dealloc];
	
}

- (id)init {
	if ((self = [super init]))
	{
		self.title = @"Date and Time";
	}
	return self;
}

- (CGFloat) heightOffset
{
	// return 150.0;
    return 0;
}

- (void)initializeFromBookmark:(TripUserRequest *)req
{
	self.tripQuery = [[[XMLTrips alloc] init] autorelease];
	self.tripQuery.userRequest = req;
	
	req.dateAndTime = nil;
	
	// Force a getting of the current location
	if (req.fromPoint.useCurrentLocation)
	{
		req.fromPoint.coordinates = nil;
	}
	
	if (req.toPoint.useCurrentLocation)
	{
		req.toPoint.coordinates = nil;
	}
}

#pragma mark TableViewWithToolbar methods



- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}


#pragma mark Picker code

// return the picker frame based on its size, positioned at the bottom of the page
- (CGRect)pickerFrameWithSize:(CGSize)size
{
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	
	
    // This seems so iOS version specific not sure why!
    
    float offset = 20.0;
    
    if (!self.iOS8style)
    {
        if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
            self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
        {
            CGFloat temp = screenRect.size.height;
            screenRect.size.height = screenRect.size.width;
            screenRect.size.width = temp;
            
            if (self.iOS7style)
            {
                offset = 21;
            }
        }
    }
	
    
    
    if (!self.iOS7style)
    {
        offset = 84.0;
    }
    
	
    
	CGRect pickerRect = CGRectMake(	0.0,
								   screenRect.size.height - size.height - offset,
								   screenRect.size.width,
								   size.height);
	return pickerRect;
}

- (void)createDatePicker
{	
	self.datePickerView = [[[UIDatePicker alloc] initWithFrame:CGRectZero] autorelease];
	// self.datePickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth; //UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	self.datePickerView.datePickerMode = UIDatePickerModeDateAndTime;
	
	if (self.tripQuery.userRequest.dateAndTime != nil)
	{
		self.datePickerView.date = self.tripQuery.userRequest.dateAndTime;
	}
	
	// note we are using CGRectZero for the dimensions of our picker view,
	// this is because picker views have a built in optimum size,
	// you just need to set the correct origin in your view.
	//
	// position the picker at the bottom
	CGSize pickerSize = [self.datePickerView sizeThatFits:CGSizeZero];
	self.datePickerView.frame = [self pickerFrameWithSize:pickerSize];
	
	// add this picker to our view controller, initially hidden
	
	
}

#pragma mark UI Helper functions

-(void)showOptions:(id)sender
{
	TripPlannerOptions * options = [[ TripPlannerOptions alloc ] init];
	
	options.tripQuery = self.tripQuery;
	
	[[self navigationController] pushViewController:options animated:YES];
	
	
	[options release];
}


#pragma mark TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kDatePickerSections;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return kDatePickerButtonsPerSection;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 45.0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"DateType";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	switch (indexPath.row)
	{
		case kSectionDateDepartNow:
			cell.textLabel.text = @"Depart now";
			break;
		case kSectionDateDeparture:
			cell.textLabel.text = @"Depart after the time below";
			break;
		case kSectionDateArrival:
			cell.textLabel.text = @"Arrive by the time below";
			break;			
	}
	
	cell.textLabel.font = [self getBasicFont];
	cell.accessoryType = self.popBack ? UITableViewCellAccessoryNone  : UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	
	
	self.tripQuery.userRequest.dateAndTime = self.datePickerView.date;
	
	switch (indexPath.row)
	{
		case kSectionDateDeparture:
			self.tripQuery.userRequest.arrivalTime = false;
			break;
		case kSectionDateArrival:
			self.tripQuery.userRequest.arrivalTime = true;
			break;
		case kSectionDateDepartNow:
			self.tripQuery.userRequest.arrivalTime = false;
			self.tripQuery.userRequest.dateAndTime = nil;
	}
	
	if (self.popBack)
	{
		[self.navigationController popViewControllerAnimated:YES];
	}
	else
	{	
		TripPlannerLocatingView * locView = [[ TripPlannerLocatingView alloc ] init];
	
		locView.tripQuery = self.tripQuery;
	
		[locView nextScreen:[self navigationController] forceResults:NO postQuery:NO 
				orientation:self.interfaceOrientation
			  taskContainer:self.backgroundTask];
	
		[locView release];
	}
}

-(void)nextScreen:(UINavigationController *)controller taskContainer:(BackgroundTaskContainer *)taskContainer
{
	if (self.tripQuery.userRequest.timeChoice == TripAskForTime)
	{
		[controller pushViewController:self animated:YES];
	}
	else 
	{
		self.tripQuery.userRequest.arrivalTime = (self.tripQuery.userRequest.timeChoice == TripArriveBeforeTime);
		self.tripQuery.userRequest.dateAndTime = [NSDate date];
		
		TripPlannerLocatingView * locView = [[ TripPlannerLocatingView alloc ] init];
		
		locView.tripQuery = self.tripQuery;
		
		[locView nextScreen:controller forceResults:NO postQuery:NO orientation:self.interfaceOrientation taskContainer:taskContainer];
		
		[locView release];
	}
}

#pragma mark View Methds

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self.datePickerView removeFromSuperview];
	self.datePickerView = nil;
		
	[self createDatePicker];
	[self.view addSubview:self.datePickerView];
	
	[self reloadData];
}

-(void)loadView
{
	[super loadView];
	
	[self createDatePicker];
	[self.view addSubview:self.datePickerView];
	
}

- (void)viewDidAppear:(BOOL)animated
{
	CGSize pickerSize = [self.datePickerView sizeThatFits:CGSizeZero];
	CGRect frame = [self pickerFrameWithSize:pickerSize];
	
	
	self.datePickerView.frame = frame;
	
	/*
	
	if (self.datePickerView)
	{
		[self.datePickerView removeFromSuperview];
		self.datePickerView = nil;
	}
	
	[self createDatePicker];
	[self.view addSubview:self.datePickerView];
	*/

    [super viewDidAppear:animated];
	[self reloadData];

}


- (void)viewDidLoad {
    [super viewDidLoad];
	
	if (self.tripQuery == nil)
	{
		self.tripQuery = [[[XMLTrips alloc] init] autorelease];
		self.tripQuery.userFaves = self.userFaves;
	}
	
}

@end
