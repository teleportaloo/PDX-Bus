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
                                initWithImage:[TableViewWithToolbar getToolbarIcon7:kIconFlash7 old:kIconFlash]
                               style:UIBarButtonItemStylePlain
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
	UIBarButtonItem *mag = [[[UIBarButtonItem alloc]
							 // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
							 initWithImage:[TableViewWithToolbar getToolbarIcon:kIconMagnify]
							 style:UIBarButtonItemStylePlain
							 target:target action:action] autorelease];
	
	mag.style = UIBarButtonItemStylePlain;
	mag.accessibilityLabel = @"Large bus line identifier";
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
	map.accessibilityLabel = @"Show Map";
	
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
	flash.accessibilityLabel = @"Flash Screen";
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
    back.accessibilityLabel = @"Home";
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
	back.accessibilityLabel = @"Redo";	
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
	back.accessibilityLabel = @"Commuter Bookmark";
	return back;
	
}

+ (UIBarButtonItem *)autoLocateWithTarget:(id)target action:(SEL)action
{
	UIBarButtonItem *back = [[[UIBarButtonItem alloc]
							  initWithImage:[TableViewWithToolbar getToolbarIcon7:kIconLocateNear7 old:kIconLocateNear]
							  style:UIBarButtonItemStylePlain
							  target:target action:action] autorelease];
	
	
	back.style = UIBarButtonItemStylePlain;
	back.accessibilityLabel = @"Locate Stops";
	return back;
	
}

+ (UIBarButtonItem *)autoQRScanner:(id)target action:(SEL)action
{
	UIBarButtonItem *back = [[[UIBarButtonItem alloc]
							  initWithImage:[TableViewWithToolbar getToolbarIcon7:kIconCamera7 old:kIconCamera]
							  style:UIBarButtonItemStylePlain
							  target:target action:action] autorelease];
	
	
	back.style = UIBarButtonItemStylePlain;
	back.accessibilityLabel = @"QR Scanner";
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
