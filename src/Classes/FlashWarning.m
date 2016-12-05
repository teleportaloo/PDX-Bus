//
//  FlashWarning.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/27/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "FlashWarning.h"
#import "FlashViewController.h"

@implementation FlashWarning

@synthesize parentBase = _parentBase;
@synthesize nav        = _nav;
@synthesize alert      = _alert;

- (void)flashLight
{
	[self.nav pushViewController:[FlashViewController viewController] animated:YES];
}

- (instancetype)initWithNav:(UINavigationController *)newNav {
	if ((self = [super init]))
	{
        self.nav = newNav;
        
        if ([UserPrefs singleton].flashingLightWarning)
        {
            self.alert =  [[[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Flashing Light", @"Alert title")
                                                        message:NSLocalizedString(@"If you have photosensitive epilepsy please be aware that you may be affected by the flashing light. Would you like to disable this feature?", @"Warning text")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Disable", @"Button text")
                                              otherButtonTitles:NSLocalizedString(@"Continue", @"Buttin text"), nil] autorelease];
            
            [self.alert show];
            
            // The reference is weak - so retain ourselves
            [self retain];
        }
        else
        {
            [self flashLight];
        }
        
        
    }
	return self;
}

- (void)dealloc
{
    self.parentBase = nil;
    self.alert      = nil;
    self.nav        = nil;
    
    [super dealloc];
}


// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [UserPrefs singleton].flashingLightWarning = NO;
    
    if (buttonIndex == 0)
    {
        [UserPrefs singleton].flashingLightIcon = NO;
        if (self.parentBase != nil)
        {
            [self.parentBase updateToolbar];
        }
    }
    else
    {
        [UserPrefs singleton].flashingLightIcon = YES;
        if (self.parentBase != nil)
        {
            [self.parentBase updateToolbar];
        }
        [self flashLight];
    }
    [self autorelease];
}

// Called when we cancel a view (eg. the user clicks the Home button). This is not called when the user clicks the cancel button.
// If not defined in the delegate, we simulate a click in the cancel button
- (void)alertViewCancel:(UIAlertView *)alertView
{
    [self autorelease];
}


@end
