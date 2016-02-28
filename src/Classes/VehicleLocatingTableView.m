//
//  VehicleLocatingTableView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "VehicleLocatingTableView.h"
#import "VehicleTableView.h"
#import "NearestVehiclesMap.h"


@implementation VehicleLocatingTableView


#pragma mark Background task callbacks


#pragma mark View callbacks

- (void)viewDidLoad
{
    _accuracy = 200.0;
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.delegate = self;
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.delegate = nil;
    [super viewDidDisappear:animated];
}


- (void)showMap:(id)arg
{
    NearestVehiclesMap *mapView = [[NearestVehiclesMap alloc] init];
    mapView.trimetRoutes    = nil;
    mapView.streetcarRoutes = [NSSet set];
    mapView.title = @"Nearest Vehicles";
    
    [mapView fetchNearestVehiclesInBackground:self.backgroundTask];
    
    [mapView release];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
	[toolbarItems addObject:[CustomToolbar autoMapButtonWithTarget:self action:@selector(showMap:)]];
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}


#pragma mark LocatingTableView callbacks

- (void)locatingViewFinished:(LocatingView *)locatingView
{
    
    if (!locatingView.failed && !locatingView.cancelled)
    {
        VehicleTableView *listView = [[VehicleTableView alloc] init];
    
        [listView fetchNearestVehiclesInBackground:locatingView.backgroundTask location:self.locationManager.location
                                       maxDistance:[UserPrefs getSingleton].vehicleLocatorDistance];
    
        [listView release];
    }
    else if (locatingView.cancelled)
    {
        [locatingView.navigationController popViewControllerAnimated:YES];
    }
}

@end
