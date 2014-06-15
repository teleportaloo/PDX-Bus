//
//  AppSettingsCustomController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/22/11.
//  Copyright 2011 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "AppSettingsCustomController.h"
#import "CustomToolbar.h"
#import "FlashViewController.h"
#import "FlashWarning.h"

@implementation AppSettingsCustomController

#pragma Mark PDX Bus additions

- (UIColor*)htmlColor:(int)val
{
	return [UIColor colorWithRed:((CGFloat)((val >> 16) & 0xFF))/255.0
						   green:((CGFloat)((val >> 8) & 0xFF))/255.0
							blue:((CGFloat)(val & 0xFF))/255.0 alpha:1.0];
    
}


- (void)setTheme
{
	int color = [UserPrefs getSingleton].toolbarColors;
	
	if (color == 0xFFFFFF)
	{
        if ([self.navigationController.toolbar respondsToSelector:@selector(setBarTintColor:)])
        {
            self.navigationController.toolbar.barTintColor = nil;
            self.navigationController.navigationBar.barTintColor = nil;
            self.navigationController.toolbar.tintColor = nil;
            self.navigationController.navigationBar.tintColor = nil;
        }
        else
        {
            self.navigationController.toolbar.tintColor = nil;
            self.navigationController.navigationBar.tintColor = nil;
        }
	}
	else
	{
        if ([self.navigationController.toolbar respondsToSelector:@selector(setBarTintColor:)])
        {
            self.navigationController.toolbar.barTintColor = [self htmlColor:color];
            self.navigationController.navigationBar.barTintColor = [self htmlColor:color];
            self.navigationController.toolbar.tintColor = [UIColor whiteColor];
            self.navigationController.navigationBar.tintColor = [UIColor whiteColor];;
        }
        else
        {
            self.navigationController.toolbar.tintColor = [self htmlColor:color];
            self.navigationController.navigationBar.tintColor = [self htmlColor:color];
        }
        
	}
}

-(void)backButton:(id)sender
{
	[[self navigationController] popToRootViewControllerAnimated:YES];
}

-(void)flashButton:(id)sender
{
    FlashWarning *flash = [[FlashWarning alloc] initWithNav:[self navigationController]];
    
	[flash release];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [[self navigationController] setToolbarHidden:NO animated:NO];

    NSMutableArray *items = [[[NSMutableArray alloc] init] autorelease];
    
    if ((self.navigationController == nil) || ([self.navigationController.viewControllers objectAtIndex:0] != self))
    {
        [items addObject:[CustomToolbar autoDoneButtonWithTarget:self action:@selector(backButton:)]];
    }
    
    if ([UserPrefs getSingleton].flashingLightIcon)
    {
        [items addObject:[CustomToolbar autoFlexSpace]];
        [items addObject:[CustomToolbar autoFlashButtonWithTarget:self action:@selector(flashButton:)]];
    }
    
	[self setToolbarItems:items animated:NO];
    
    [self setTheme];
 	
	[super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(userDefaultsDidChange:)
												 name:NSUserDefaultsDidChangeNotification
											   object:[NSUserDefaults standardUserDefaults]];
}




- (void) userDefaultsDidChange:(id)obj
{
    [self setTheme];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
