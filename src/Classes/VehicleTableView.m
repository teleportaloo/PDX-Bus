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
#import "VehicleData+iOSUI.h"
#import "FormatDistance.h"
#import "BlockColorDb.h"
#import "DepartureCell.h"

@implementation VehicleTableView

#define kSectionVehicles   0
#define kSectionDisclaimer 1
#define kSections		   2

@synthesize locator = _locator;

- (void) dealloc
{
    self.locator = nil;
    [super dealloc];
}

- (instancetype)init {
	if ((self = [super init]))
	{
        self.title = NSLocalizedString(@"Nearest Vehicles", @"page title");
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
    self.navigationItem.prompt = NSLocalizedString(@"Which vehicle are you on?", @"page prompt");
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationItem.prompt = nil;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_firstTime && self.locator.count == 1)
    {
        VehicleData *vehicle = self.locator[0];
        
        [vehicle mapTapped:self.backgroundTask];
    }
    
    _firstTime = NO;
    
}

- (void)fetchNearestVehiclesAsync:(id<BackgroundTaskProgress>)background location:(CLLocation *)here maxDistance:(double)dist
{
	self.backgroundTask.callbackWhenFetching = background;
	
    self.locator = [XMLLocateVehicles xml];
	
	self.locator.location = here;
	self.locator.dist     = dist;
    
    [self runAsyncOnBackgroundThread:^{
        NSThread *thread = [NSThread currentThread];
        
        [self.backgroundTask.callbackWhenFetching backgroundStart:1 title:@"getting vehicles"];
        
        [self.locator findNearestVehicles:nil direction:nil blocks:nil];
        
        if (self.locator.count == 0)
        {
            [thread cancel];
            [self.self.backgroundTask.callbackWhenFetching backgroundSetErrorMsg:kNoVehicles];
        }
        
        [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
        
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section)
	{
		case kSectionVehicles:
		{
			return self.locator.count;
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
            return DEPARTURE_CELL_HEIGHT;
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
			cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionVehicles)];
			if (cell == nil) {
                cell = [DepartureCell genericWithReuseIdentifier:MakeCellId(kSectionVehicles)];
            }
            DepartureCell *dcell = (DepartureCell *)cell;
            
			// Configure the cell
			VehicleData *vehicle = self.locator[indexPath.row];
			
            if (LARGE_SCREEN)
            {
                dcell.routeLabel.text = vehicle.signMessageLong;
            }
            else
            {
                dcell.routeLabel.text = vehicle.signMessage;
            }

            
            dcell.timeLabel.text = [NSString stringWithFormat:@"Distance %@", [FormatDistance formatMetres:vehicle.distance ]];
			[dcell.routeColorView setRouteColor:vehicle.routeNumber];
            dcell.blockColorView.color = [[BlockColorDb sharedInstance] colorForBlock:vehicle.block];
            dcell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		}
            break;
        default:
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
            VehicleData *vehicle = self.locator[indexPath.row];
			 
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
									  style:UIBarButtonItemStylePlain
									  target:self
									  action:@selector(refreshAction:)];
	self.navigationItem.rightBarButtonItem = refreshButton;
	[refreshButton release];
	self.searchableItems = self.locator.itemArray;
	
	[self reloadData];
	
	if (self.locator.count> 0)
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
    
    [self fetchNearestVehiclesAsync:self.backgroundTask location:locator.location maxDistance:locator.dist];
    
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
