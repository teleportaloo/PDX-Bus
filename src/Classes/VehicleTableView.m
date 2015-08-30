//
//  VehicleTableView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "VehicleTableView.h"
#import "XMLLocateVehicles.h"
#import "RouteColorBlobView.h"
#import "DepartureTimesView.h"
#import "VehicleData.h"
#import "VehicleUI.h"

@implementation VehicleTableView

#define kSectionVehicles   0
#define kSectionDisclaimer 1
#define kSections		   2

#define kRouteCellId @"route"
#define COLOR_STRIPE_TAG 1


@synthesize locator = _locator;
- (void) dealloc
{
    self.locator = nil;
    [super dealloc];
}

- (id)init {
	if ((self = [super init]))
	{
		self.title = @"Nearest Vehicles";
        _firstTime  = YES;
	}
	return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.prompt = @"Which vehicle are you on?";
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationItem.prompt = nil;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_firstTime && self.locator.safeItemCount == 1)
    {
        VehicleUI *vehicle = [VehicleUI createFromData:[self.locator itemAtIndex:0]];
        
        [vehicle mapTapped:self.backgroundTask];
    }
    
    _firstTime = NO;
    

}

- (void)fetchNearestVehicles:(id)arg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSThread *thread = [NSThread currentThread];
	
	[self.backgroundTask.callbackWhenFetching backgroundThread:thread];
	
    
	[self.backgroundTask.callbackWhenFetching backgroundStart:1 title:@"getting vehicles"];
    
	[self.locator findNearestVehicles];
    
    if (self.locator.safeItemCount == 0)
    {
        [thread cancel];
        [self.self.backgroundTask.callbackWhenFetching backgroundSetErrorMsg:kNoVehicles];
    }

    [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
    
    [pool release];
}

- (void)fetchNearestVehiclesInBackground:(id<BackgroundTaskProgress>)background location:(CLLocation *)here maxDistance:(double)dist
{
	self.backgroundTask.callbackWhenFetching = background;
	
	self.locator = [[[XMLLocateVehicles alloc] init] autorelease];
	
	self.locator.location = here;
	self.locator.dist     = dist;
	
	[NSThread detachNewThreadSelector:@selector(fetchNearestVehicles:) toTarget:self withObject:nil];
	
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section)
	{
		case kSectionVehicles:
		{
			return self.locator.safeItemCount;
		}
		case kSectionDisclaimer:
			return 1;
	}
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case kSectionVehicles:
			return [self basicRowHeight] * 1.5;
		case kSectionDisclaimer:
			return kDisclaimerCellHeight;
	}
	return 1;
	
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	
	switch (indexPath.section)
	{
        case kSectionVehicles:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:kRouteCellId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kRouteCellId] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				
                CGRect rect = CGRectMake(0, 0, COLOR_STRIPE_WIDTH, [self tableView:tableView heightForRowAtIndexPath:indexPath]);
                
				RouteColorBlobView *colorStripe = [[RouteColorBlobView alloc] initWithFrame:rect];
				colorStripe.tag = COLOR_STRIPE_TAG;
				[cell.contentView addSubview:colorStripe];
				[colorStripe release];
				
			}
			// Configure the cell
			VehicleData *vehicle = [self.locator itemAtIndex:indexPath.row];
			
            if (LargeScreenStyle(self.screenWidth))
            {
                cell.textLabel.text = vehicle.signMessageLong;
            }
            else
            {
                cell.textLabel.text = vehicle.signMessage;
            }
			cell.textLabel.font = [self getBasicFont];
			cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Distance %.0f yards (%.0f meters)", vehicle.distance * 1.09361,  vehicle.distance];
			RouteColorBlobView *colorStripe = (RouteColorBlobView*)[cell.contentView viewWithTag:COLOR_STRIPE_TAG];
			[colorStripe setRouteColor:vehicle.routeNumber];
		}
            break;
        case kSectionDisclaimer:
            cell = [tableView dequeueReusableCellWithIdentifier:kDisclaimerCellId];
            if (cell == nil) {
                cell = [self disclaimerCellWithReuseIdentifier:kDisclaimerCellId];
            }
			
            [self addTextToDisclaimerCell:cell text:[self.locator displayDate:self.locator.cacheTime]];
			
            if (self.locator.itemArray == nil)
            {
                [self noNetworkDisclaimerCell:cell];
            }
            else
            {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            break;
	}
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section)
	{
		case kSectionVehicles:
		{
            VehicleUI *vehicle = [VehicleUI createFromData:[self.locator itemAtIndex:indexPath.row]];
			 
            [vehicle mapTapped:self.backgroundTask];
			break;
		}
		case kSectionDisclaimer:
		{
			if (self.locator.itemArray == nil)
			{
				[self networkTips:self.locator.htmlError networkError:self.locator.errorMsg];
                [self clearSelection];
			}
			break;
		}
	}
}

#pragma mark View methods

- (void)viewDidLoad {
	[super viewDidLoad];
	// Add the following line if you want the list to be editable
	// self.navigationItem.leftBarButtonItem = self.editButtonItem;
	// self.title = originalName;
	
	// add our custom add button as the nav bar's custom right view
	UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
									  initWithTitle:NSLocalizedString(@"Refresh", @"")
									  style:UIBarButtonItemStyleBordered
									  target:self
									  action:@selector(refreshAction:)];
	self.navigationItem.rightBarButtonItem = refreshButton;
	[refreshButton release];
	self.searchableItems = self.locator.itemArray;
	
	[self reloadData];
	
	if ([self.locator safeItemCount] > 0)
	{
		[self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
						  atScrollPosition:UITableViewScrollPositionTop
								  animated:NO];
	}
    
	
}



#pragma mark UI callbacks

- (void)refreshAction:(id)sender
{
	self.backgroundRefresh = true;
    
    XMLLocateVehicles * locator =[self.locator retain];
    
    [self fetchNearestVehiclesInBackground:self.backgroundTask location:locator.location maxDistance:locator.dist];
    
    [locator release];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    [self updateToolbarItemsWithXml:toolbarItems];
}

-(void) appendXmlData:(NSMutableData *)buffer
{
    [self.locator appendQueryAndData:buffer];
}

@end
