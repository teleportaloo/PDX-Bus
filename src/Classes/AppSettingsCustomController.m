//
//  AppSettingsCustomController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/22/11.
//  Copyright 2011 Teleportaloo. All rights reserved.
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


#import "AppSettingsCustomController.h"
#import "CustomToolbar.h"
#import "FlashViewController.h"


@implementation AppSettingsCustomController

#pragma Mark PDX Bus additions

-(void)backButton:(id)sender
{
	[[self navigationController] popToRootViewControllerAnimated:YES];
}

-(void)flashButton:(id)sender
{
    FlashViewController *flash = [[FlashViewController alloc] init];
	[[self navigationController] pushViewController:flash animated:YES];
	[flash release];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [[self navigationController] setToolbarHidden:NO animated:NO];
    NSArray *items = [NSArray arrayWithObjects: 
                      [CustomToolbar autoDoneButtonWithTarget:self action:@selector(backButton:)], 
                      [CustomToolbar autoFlexSpace], 
                      [CustomToolbar autoFlashButtonWithTarget:self action:@selector(flashButton:)],
                      nil];
	[self setToolbarItems:items animated:NO];
	
	[super viewWillAppear:animated];
}

@end
