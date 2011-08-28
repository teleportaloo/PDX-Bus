//
//  AddNewStopToBookMark.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/25/09.

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


#import "AddNewStopToBookMark.h"
#import "CellTextView.h"
#import "CellTextField.h"

#define kRowEnter	0
#define kRowDone	1
#define kDoneId		@"DoneCell"
#define kUIEditHeight			50.0
#define kUIRowHeight			40.0

@implementation AddNewStopToBookMark
@synthesize editWindow	= _editWindow;

- (void)dealloc {
	self.editWindow = nil;
    [super dealloc];
}

#pragma mark Helper functions


- (UITextField *)createTextField_Rounded
{
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, [CellTextField editHeight]);
	UITextField *returnTextField = [[[UITextField alloc] initWithFrame:frame] autorelease];
    
	returnTextField.borderStyle = UITextBorderStyleRoundedRect;
    returnTextField.textColor = [UIColor blackColor];
	returnTextField.font = [CellTextField editFont];
    returnTextField.placeholder = @"<enter stop ID>";
    returnTextField.backgroundColor = [UIColor whiteColor];
	returnTextField.autocorrectionType = UITextAutocorrectionTypeNo;	// no auto correction support
	
	returnTextField.keyboardType = UIKeyboardTypeNumberPad;
	returnTextField.returnKeyType = UIReturnKeyDone;
	
	returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
	self.editWindow = returnTextField;
	
	return returnTextField;
}

#pragma mark TableViewWithToolbar functions

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}


#pragma mark View functions

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
    [super viewDidLoad];
	UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc]
									  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
									  target:self
									  action:@selector(cancelAction:)] autorelease];
	self.navigationItem.rightBarButtonItem = cancelButton;

}

- (void)viewWillAppear:(BOOL)animated {
	[self.editWindow becomeFirstResponder];
}

#pragma mark TableView methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return @"Enter stop ID:";
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [CellTextField cellHeight];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SimpleEdit";
    
	switch (indexPath.row)
	{
		case kRowEnter:
		{	
    
			CellTextField *sourceCell = (CellTextField*) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (sourceCell == nil)
			{
				sourceCell =  [[[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];	
				((CellTextField *)sourceCell).view = [self createTextField_Rounded];
				((CellTextField *)sourceCell).delegate = self;
				self.editWindow = sourceCell.view;
				[self.editWindow becomeFirstResponder];
				sourceCell.cellLeftOffset = 40.0;
				sourceCell.imageView.image = [self alwaysGetIcon:kIconEnterStopID];
				return sourceCell;
			}
			break;
		}
		case kRowDone:
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDoneId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDoneId] autorelease];
				cell.textLabel.textAlignment = UITextAlignmentLeft;
			}
			
			// Set up the cell
			cell.textLabel.text = @"Add this stop ID";
			cell.imageView.image = [self getActionIcon:kIconAdd];
			// [self maybeAddSectionToAccessibility:cell indexPath:indexPath];
			cell.textLabel.font = [self getBasicFont];
			return cell;
		}
			
	}
		
	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITextView *textView = (UITextView*)self.editWindow;
	NSString *editText =[self justNumbers:textView.text];
	
	if (indexPath.row == kRowDone && [editText length] !=0)
	{
		[self.editWindow resignFirstResponder];
	}
	else
	{
		NSIndexPath *ip = [self.table indexPathForSelectedRow];
		if (ip!=nil)
		{
			[self.table deselectRowAtIndexPath:ip animated:YES];
		}
	}
}

#pragma mark Editing functions

// Invoked before editing begins. The delegate may return NO to prevent editing.
- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{
	// add our custom add button as the nav bar's custom right view
	return YES;
}
// Invoked after editing ends.


- (void)cellDidEndEditing:(EditableTableViewCell *)cell
{
	
	UITextView *textView = (UITextView*)[(CellTextField*)cell view];
	NSString *editText =[self justNumbers:textView.text];
	if (editText.length !=0 && self.navigationItem.rightBarButtonItem != nil )
	{
		if ([self.callback getController] != nil)
		{
			[[self navigationController] popToViewController:[self.callback getController] animated:YES];
		}
		[self.callback selectedStop:editText];
	}
	self.navigationItem.rightBarButtonItem = nil;
	
}

- (void)cancelAction:(id)sender
{
	self.navigationItem.rightBarButtonItem = nil;
	[self.editWindow resignFirstResponder];
	[[self navigationController] popToViewController:[self.callback getController] animated:YES];
}

@end

