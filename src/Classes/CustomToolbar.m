//
//  CustomToolbar.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/22/09.
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

#import "CustomToolbar.h"
#import "TableViewWithToolbar.h"

@implementation CustomToolbar

- (void)dealloc {
    [super dealloc];
}

#pragma mark Methods to create common auto-released toolbar buttons

- (UIBarButtonItem *)autoBigFlashButton
{
	// create the system-defined "OK or Done" button
	UIBarButtonItem *flash = [[[UIBarButtonItem alloc]
							   initWithTitle:@"Night Visibility Flashing Light" style:UIBarButtonItemStyleBordered 
							   target:self action:@selector(flashButton:)] autorelease];
	return flash;
}

+ (UIBarButtonItem *)autoNoSleepWithTarget:(id)target action:(SEL)action
{
	// create the system-defined "OK or Done" button
	UIBarButtonItem *button = [[[UIBarButtonItem alloc]
							   initWithTitle:@"Device sleep disabled!" style:UIBarButtonItemStylePlain
							   target:target action:action] autorelease];
	return button;
	
	
}

+ (UIBarButtonItem *)autoMagnifyButtonWithTarget:(id)target action:(SEL)action
{
	
	// create the system-defined "OK or Done" button
	UIBarButtonItem *map = [[[UIBarButtonItem alloc]
							 // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
							 initWithImage:[TableViewWithToolbar getToolbarIcon:kIconMagnify]
							 style:UIBarButtonItemStylePlain
							 target:target action:action] autorelease];
	
	
	// map.style = UIBarButtonItemStylePlain; */
	
	map.style = UIBarButtonItemStylePlain;
	map.title = @"Magnify";
	map.accessibilityHint = @"Large bus line identifier";
	return map;
}

+ (UIBarButtonItem *)autoMapButtonWithTarget:(id)target action:(SEL)action
{

	// create the system-defined "OK or Done" button
	UIBarButtonItem *map = [[[UIBarButtonItem alloc]
							// initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
							initWithImage:[TableViewWithToolbar getToolbarIcon:kIconMap]
							style:UIBarButtonItemStylePlain
							 target:target action:action] autorelease];

		
	// map.style = UIBarButtonItemStylePlain; */
	
	map.style = UIBarButtonItemStylePlain;
	map.title = @"Map";
	map.accessibilityHint = @"map";
	
	return map;
}

+ (UIBarButtonItem *)autoFlashButtonWithTarget:(id)target action:(SEL)action
{
	UIBarButtonItem *flash = [[[UIBarButtonItem alloc]
							 // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
							 initWithImage:[TableViewWithToolbar getToolbarIcon:kIconFlash]
							 style:UIBarButtonItemStylePlain
							 target:target action:action] autorelease];
	
	flash.style = UIBarButtonItemStylePlain;
	flash.title = @"Flash";
	flash.accessibilityHint = @"flash screen";

	return flash;
	
}

+ (UIBarButtonItem *)autoDoneButtonWithTarget:(id)target action:(SEL)action
{
	// create the system-defined "OK or Done" button
	UIBarButtonItem *back = [[[UIBarButtonItem alloc]
							   // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
							   initWithImage:[TableViewWithToolbar getToolbarIcon:kIconHome]
							   style:UIBarButtonItemStylePlain
							   target:target action:action] autorelease];
	
	
	back.style = UIBarButtonItemStylePlain;
	back.title = @"Home";
	back.accessibilityHint = @"home";
	
	return back;
}

+ (UIBarButtonItem *)autoRedoButtonWithTarget:(id)target action:(SEL)action
{
	// create the system-defined "OK or Done" button
	UIBarButtonItem *back = [[[UIBarButtonItem alloc]
							  // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
							  initWithImage:[TableViewWithToolbar getToolbarIcon:kIconRedo]
							  style:UIBarButtonItemStylePlain
							  target:target action:action] autorelease];
	
	
	back.style = UIBarButtonItemStylePlain;
	back.title = @"Redo";
	back.accessibilityHint = @"redo";
	
	return back;
}

+ (UIBarButtonItem *)autoCommuteWithTarget:(id)target action:(SEL)action
{
	UIBarButtonItem *back = [[[UIBarButtonItem alloc]
							  // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
							  initWithImage:[TableViewWithToolbar getToolbarIcon:kIconCommute]
							  style:UIBarButtonItemStylePlain
							  target:target action:action] autorelease];
	
	
	back.style = UIBarButtonItemStylePlain;
	back.title = @"Commute";
	back.accessibilityHint = @"Commute";
	return back;
	
}

+ (UIBarButtonItem *)autoLocateWithTarget:(id)target action:(SEL)action
{
	UIBarButtonItem *back = [[[UIBarButtonItem alloc]
							  // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
							  initWithImage:[TableViewWithToolbar getToolbarIcon:kIconLocateNear]
							  style:UIBarButtonItemStylePlain
							  target:target action:action] autorelease];
	
	
	back.style = UIBarButtonItemStylePlain;
	back.title = @"Locate";
	back.accessibilityHint = @"Locate";
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
