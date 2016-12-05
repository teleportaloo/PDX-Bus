//
//  CustomToolbar.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/22/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "UIToolbar+Auto.h"
#import "TableViewWithToolbar.h"

@implementation UIToolbar (Auto)


#pragma mark Methods to create common auto-released toolbar buttons


+ (UIBarButtonItem *)autoNoSleepWithTarget:(id)target action:(SEL)action
{
	// create the system-defined "OK or Done" button
	UIBarButtonItem *button = [[[UIBarButtonItem alloc]
							   initWithTitle:NSLocalizedString(@"Device sleep disabled!", @"warning") style:UIBarButtonItemStylePlain
							   target:target action:action] autorelease];
	return button;
	
	
}

+ (UIBarButtonItem *)autoMagnifyButtonWithTarget:(id)target action:(SEL)action
{
	
	// create the system-defined "OK or Done" button
	UIBarButtonItem *mag = [[[UIBarButtonItem alloc]
							 // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
							 initWithImage:[TableViewWithToolbar getToolbarIcon:kIconMagnify]
							 style:UIBarButtonItemStylePlain
							 target:target action:action] autorelease];
	
	mag.style = UIBarButtonItemStylePlain;
	mag.accessibilityLabel = NSLocalizedString(@"Large bus line identifier", @"accessibility text");
	return mag;
}

+ (UIBarButtonItem *)autoMapButtonWithTarget:(id)target action:(SEL)action
{

	// create the system-defined "OK or Done" button
	UIBarButtonItem *map = [[[UIBarButtonItem alloc]
                             initWithImage:[TableViewWithToolbar getToolbarIcon7:kIconMap7 old:kIconMap]
							style:UIBarButtonItemStylePlain
							 target:target action:action] autorelease];

	map.style = UIBarButtonItemStylePlain;
	map.accessibilityLabel = NSLocalizedString(@"Show Map", @"accessibility text");
	
	return map;
}

+ (UIBarButtonItem *)autoFlashButtonWithTarget:(id)target action:(SEL)action
{
	UIBarButtonItem *flash = [[[UIBarButtonItem alloc]
							 // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                               initWithImage:[TableViewWithToolbar getToolbarIcon7:kIconFlash7 old:kIconFlash]
							 style:UIBarButtonItemStylePlain
							 target:target action:action] autorelease];
	
	flash.style = UIBarButtonItemStylePlain;
	flash.accessibilityLabel = NSLocalizedString(@"Flash Screen",@"accessibility text");
	return flash;
	
}

+ (UIBarButtonItem *)autoDoneButtonWithTarget:(id)target action:(SEL)action
{
	// create the system-defined "OK or Done" button
	UIBarButtonItem *back = [[[UIBarButtonItem alloc]
                               initWithImage:[TableViewWithToolbar getToolbarIcon7:kIconHome7 old:kIconHome]
							   style:UIBarButtonItemStylePlain
							   target:target action:action] autorelease];
	
	
	back.style = UIBarButtonItemStylePlain;
    back.accessibilityLabel = NSLocalizedString(@"Home",@"accessibility text");
	back.accessibilityHint = nil;
	
	return back;
}

+ (UIBarButtonItem *)autoRedoButtonWithTarget:(id)target action:(SEL)action
{
	// create the system-defined "OK or Done" button
	UIBarButtonItem *back = [[[UIBarButtonItem alloc]
							  initWithImage:[TableViewWithToolbar getToolbarIcon:kIconRedo]
							  style:UIBarButtonItemStylePlain
							  target:target action:action] autorelease];
	
	
	back.style = UIBarButtonItemStylePlain;
	back.accessibilityLabel = NSLocalizedString(@"Redo",@"accessibility text");
	return back;
}

+ (UIBarButtonItem *)autoCommuteWithTarget:(id)target action:(SEL)action
{
	UIBarButtonItem *back = [[[UIBarButtonItem alloc]
							  // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
							  initWithImage:[TableViewWithToolbar getToolbarIcon7:kIconCommute7 old:kIconCommute]
							  style:UIBarButtonItemStylePlain
							  target:target action:action] autorelease];
	
	
	back.style = UIBarButtonItemStylePlain;
	back.accessibilityLabel = NSLocalizedString(@"Commuter Bookmark", @"acessibility text");
	return back;
	
}

+ (UIBarButtonItem *)autoLocateWithTarget:(id)target action:(SEL)action
{
	UIBarButtonItem *back = [[[UIBarButtonItem alloc]
							  initWithImage:[TableViewWithToolbar getToolbarIcon7:kIconLocateNear7 old:kIconLocateNear]
							  style:UIBarButtonItemStylePlain
							  target:target action:action] autorelease];
	
	
	back.style = UIBarButtonItemStylePlain;
	back.accessibilityLabel = NSLocalizedString(@"Locate Stops",@"acessibility text");
	return back;
	
}

+ (UIBarButtonItem *)autoQRScanner:(id)target action:(SEL)action
{
	UIBarButtonItem *back = [[[UIBarButtonItem alloc]
							  initWithImage:[TableViewWithToolbar getToolbarIcon7:kIconCamera7 old:kIconCamera]
							  style:UIBarButtonItemStylePlain
							  target:target action:action] autorelease];
	
	
	back.style = UIBarButtonItemStylePlain;
	back.accessibilityLabel = NSLocalizedString(@"QR Scanner",@"acessibility text");
	return back;
	
}


+ (UIBarButtonItem *)autoFlexSpace
{
	UIBarButtonItem *space =[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
														  target:nil
															action:nil] autorelease];
	return space;
}




@end
