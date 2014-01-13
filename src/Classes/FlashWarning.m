//
//  FlashWarning.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/27/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//

#import "FlashWarning.h"
#import "FlashViewController.h"

@implementation FlashWarning

@synthesize parentBase = _parentBase;
@synthesize nav        = _nav;
@synthesize alert      = _alert;

- (void)flashLight
{
    FlashViewController *flash = [[FlashViewController alloc] init];
	[self.nav pushViewController:flash animated:YES];
	[flash release];
}

- (id)initWithNav:(UINavigationController *)newNav {
	if ((self = [super init]))
	{
        self.nav = newNav;
        
        if ([UserPrefs getSingleton].flashingLightWarning)
        {
            self.alert =  [[[ UIAlertView alloc ] initWithTitle:@"Flashing Light"
                                                        message:@"If you have photosensitive epilepsy please be aware that you may be affected by the flashing light. Would you like to disable this feature?"
                                                       delegate:self
                                              cancelButtonTitle:@"Disable"
                                              otherButtonTitles:@"Continue", nil] autorelease];
            
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
    [UserPrefs getSingleton].flashingLightWarning = NO;
    
    if (buttonIndex == 0)
    {
        [UserPrefs getSingleton].flashingLightIcon = NO;
        if (self.parentBase != nil)
        {
            [self.parentBase updateToolbar];
        }
    }
    else
    {
        [UserPrefs getSingleton].flashingLightIcon = YES;
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
