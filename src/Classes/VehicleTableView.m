//
//  VehicleTableView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Andrew Wallace
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
#define kSections           2


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

- (void)fetchNearestVehiclesAsync:(id<BackgroundTaskController>)task location:(CLLocation *)here maxDistance:(double)dist backgroundRefresh:(bool)backgroundRefresh
{
    [task taskRunAsync:^{
        self.backgroundRefresh = backgroundRefresh;
        
        self.locator = [XMLLocateVehicles xml];
        
        self.locator.location = here;
        self.locator.dist     = dist;
        
        [task taskStartWithItems:1 title:@"getting vehicles"];
        
        [self.locator findNearestVehicles:nil direction:nil blocks:nil vehicles:nil];
        
        if (self.locator.count == 0)
        {
            [task taskCancel];
            [task taskSetErrorMsg:kNoVehicles];
        }
        return self;
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
            DepartureCell *dcell = [DepartureCell tableView:tableView genericWithReuseIdentifier:MakeCellId(kSectionVehicles)];
            cell = dcell;
 
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

            dcell.timeLabel.text = [NSString stringWithFormat:@"Vehicle ID %@ Distance %@", vehicle.vehicleID ? vehicle.vehicleID : @"none", [FormatDistance formatMetres:vehicle.distance ]];
            [dcell.routeColorView setRouteColor:vehicle.routeNumber];
            dcell.blockColorView.color = [[BlockColorDb sharedInstance] colorForBlock:vehicle.block];
            dcell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
           
        default:
        case kSectionDisclaimer:
            cell = [self disclaimerCell:tableView];
            
            [self addTextToDisclaimerCell:cell text:[self.locator displayDate:self.locator.cacheTime]];
            
            if (self.locator.items == nil)
            {
                [self noNetworkDisclaimerCell:cell];
            }
            else
            {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            [self updateDisclaimerAccessibility:cell];
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
            if (self.locator.items == nil)
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
    self.searchableItems = self.locator.items;
    
    [self reloadData];
    
    if (self.locator.count> 0)
    {
        [self safeScrollToTop];
    }
    
    
}



#pragma mark UI callbacks

- (void)refreshAction:(id)sender
{
    if (!self.backgroundTask.running)
    {
        XMLLocateVehicles * locator =self.locator;
    
        [self fetchNearestVehiclesAsync:self.backgroundTask location:locator.location maxDistance:locator.dist backgroundRefresh:YES];
    
    }
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
