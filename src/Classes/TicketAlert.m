//
//  AlertViewRoutingDelegate.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/24/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TicketAlert.h"

@implementation TicketAlert

@synthesize parent = _parent;
@synthesize sheet  = _sheet;

- (instancetype)initWithParent:(ViewControllerBase *)newParent {
	if ((self = [super init]))
	{
		self.sheet = [[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"TriMet Tickets App", @"alert title")
                                                  delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"button text")
                                    destructiveButtonTitle:nil otherButtonTitles:
                                                                    NSLocalizedString(@"Get TriMet Tickets App" , @"button text"),
                                                                    NSLocalizedString(@"Hide toolbar icon",@"button text"),  nil]  autorelease];
        
        // The reference is weak - so retain ourselves
        [self retain];
        
        self.parent = newParent;
    }
	return self;
}

- (void)dealloc
{
    self.parent = nil;
    self.sheet  = nil;
    
    [super dealloc];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
{
    switch (buttonIndex)
    {
        case 0:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://www.itunes.com/apps/TriMetTickets"]];
            break;
        case 1:
            [UserPrefs singleton].ticketAppIcon = NO;
            [self.parent updateToolbar];
            break;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
     [self autorelease];
}

@end
