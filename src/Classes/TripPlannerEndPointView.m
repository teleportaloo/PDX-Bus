//
//  TripPlannerEndPoint.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/27/09.
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

#import "TripPlannerEndPointView.h"

#import "TripPlannerResultsView.h"
#import "TripPlannerLocationListView.h"
#import "RouteView.h"
#import <AddressBookUI/ABPeoplePickerNavigationController.h>
#import <AddressBook/ABPerson.h>
#include "UserFaves.h"
#import "TripPlannerBookmarkView.h"
#import "TripPlannerDateView.h"
#import "TripPlannerOptions.h"
#import "RailMapView.h"
#import "AllRailStationView.h"

#define kTableSectionEnterDestination		 0
#define kTableSectionLocate					 1
#define kTableSectionFaves					 2
#define kTableSectionWalk					 3

#define kTableSections						 4

#define kTableEnterRows						 5
#define kTableEnterRowRailStations			 3
#define kTableEnterRowRailMap				 4
#define kTableEnterRowEnter				     0
#define kTableEnterRowBrowse			     2
#define kTableEnterRowContacts				 1

#define kTableLocateRowHere					 0
#define kTableLocateRows					 1


#define kTableEnterRowText					 0

#define kTableWalkRow						 0


#define kTextFieldId					@"destination"
#define kPlainFieldId					@"triplocplain"
#define kOptionsFieldId					@"options"

#define kStartTextDescPlaceHolder		@"<starting place or ID>"
#define kDestinationTextDescPlaceHolder @"<destination place or ID>"
#define kTextGPSPlaceHolder				@"<using current location (GPS)>"

#define kUIEditHeight			50.0
#define kUIRowHeight			40.0

#define kSegRowWidth			300
#define kSegRowHeight			80
#define kUISegHeight			60
#define kUISegWidth				300


@implementation TripPlannerEndPointView

@synthesize from = _from;
@synthesize placeNameField = _placeNameField;
@synthesize editCell    = _editCell;
@synthesize popBackTo  = _popBackTo;



- (void)dealloc {
	self.placeNameField = nil;
	self.editCell = nil;
	self.popBackTo = nil;
	[super dealloc];
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}


- (void)createToolbarItems
{
	NSArray *items = [NSArray arrayWithObjects: 
					  [self autoDoneButton], 
					  [CustomToolbar autoFlexSpace],
					  [self autoFlashButton], nil];
	[self setToolbarItems:items animated:NO];
}


#pragma mark View methods

- (void)viewDidLoad {
    [super viewDidLoad];
	
		
	if (self.from)
	{
		self.title = @"Start"; // @"Start & Options";
	}
	else
	{
		self.title = @"Destination";
	}

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	if (self.editCell != nil)
	{
	
		if ([self endPoint] != nil && [self endPoint].locationDesc!= nil)
		{
			self.editCell.view.text = [self endPoint].locationDesc;
		}
		else
		{
			self.editCell.view.text = @"";
		}
	}
	
	if (self.from)
	{
		[self reloadData];
	}
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

#pragma mark UI Helper functions

- (void)hideKeyboard
{
	if (keyboardUp)
	{
		keyboardUp = false;
		if ([self.placeNameField isFirstResponder] && [self.placeNameField canResignFirstResponder])
		{
			[self.placeNameField resignFirstResponder];
		}
		self.navigationItem.rightBarButtonItem = nil;
		
	}
}



- (UITextField *)createTextField_Rounded
{
	CGRect frame = CGRectMake(0.0, 0.0, 80.0, [CellTextField editHeight]);
	UITextField *returnTextField = [[[UITextField alloc] initWithFrame:frame] autorelease];
    
	returnTextField.borderStyle = UITextBorderStyleRoundedRect;
    returnTextField.textColor = [UIColor blackColor];
	returnTextField.font = [CellTextField editFont];
    returnTextField.placeholder = @"";
    returnTextField.backgroundColor = [UIColor whiteColor];
	returnTextField.autocorrectionType = UITextAutocorrectionTypeNo;	// no auto correction support
	
	returnTextField.keyboardType = UIKeyboardTypeASCIICapable;
	returnTextField.returnKeyType = UIReturnKeyDone;
	
	returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
	self.placeNameField = returnTextField;
	
	return returnTextField;
}

- (void)nextScreen
{
	if (self.popBackTo)
	{
		[self.navigationController popToViewController:self.popBackTo animated:YES];
	}
	else
	{
		[[self navigationController] popViewControllerAnimated:YES];
	}
}

- (void)addDescription:(NSString *)desc
{
	if (desc.length !=0)
	{
		if (self.endPoint == nil)
		{
			[self endPoint].additionalInfo = desc;
		}
	}
}


- (void)gotPlace:(NSString *)place setUiText:(bool)setText additionalInfo:(NSString *)info
{
	if (place.length !=0)
	{
		if (self.from)
		{
			self.placeNameField.placeholder=kStartTextDescPlaceHolder;
		} else {
			self.placeNameField.placeholder=kDestinationTextDescPlaceHolder;
		}
		
		if (setText && self.placeNameField!=nil)
		{
			self.placeNameField.text = place;
		}
		
		if (self.endPoint == nil || ![place isEqualToString:[self endPoint].locationDesc])
		{
			[self initEndPoint];
			[self endPoint].locationDesc = place;
			[self endPoint].additionalInfo = info;
		}
		[self nextScreen];
	}
}


- (void)cancelAction:(id)sender
{
	[self hideKeyboard];
}

- (TripEndPoint *)endPoint
{
	if (self.from) return self.tripQuery.userRequest.fromPoint;
	
	return self.tripQuery.userRequest.toPoint;
}


- (void)initEndPoint
{
	if (self.from) 
	{
		self.tripQuery.userRequest.fromPoint = [[[TripEndPoint alloc] init] autorelease];
	}
	else
	{
		self.tripQuery.userRequest.toPoint = [[[TripEndPoint alloc] init] autorelease];
	}
}

- (void)cellDidEndEditing:(EditableTableViewCell *)cell
{
	UITextView *textView = (UITextView*)[(CellTextField*)cell view];
	
	if (keyboardUp)
	{
		[self gotPlace:textView.text setUiText:NO additionalInfo:nil];
		self.navigationItem.rightBarButtonItem = nil;
		keyboardUp = NO;
	}
	else
	{
		[self reloadData];
	}
}

// Invoked before editing begins. The delegate may return NO to prevent editing.
- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{
	// add our custom add button as the nav bar's custom right view
	UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc]
									  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
									  target:self
									  action:@selector(cancelAction:)] autorelease];
	self.navigationItem.rightBarButtonItem = cancelButton;
	keyboardUp = true;
	
	[self.table scrollToRowAtIndexPath:[NSIndexPath 
										indexPathForRow:kTableEnterRowEnter 
										inSection:kTableSectionEnterDestination] atScrollPosition:UITableViewScrollPositionTop animated:YES];
	
	return YES;
}

- (void) selectFromRailStations
{
	AllRailStationView *rmView = [[AllRailStationView alloc] init];
	
	rmView.callback = self;
	
	// Push the detail view controller
	[[self navigationController] pushViewController:rmView animated:YES];
	[rmView release];
}


- (void) selectFromRailMap
{
	RailMapView *railMapView = [[RailMapView alloc] init];
	
	railMapView.callback = self;
	
	railMapView.from = self.from;
	
	// Push the detail view controller
	[[self navigationController] pushViewController:railMapView animated:YES];
	[railMapView release];
}

- (void) browseForStop
{
	RouteView *routeViewController = [[RouteView alloc] init];
	
	routeViewController.callback = self;
	
	[routeViewController fetchRoutesInBackground:self.backgroundTask];
	[routeViewController release];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kTableSections;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section)
	{
		case kTableSectionWalk:
			if (self.from)
			{
				// return 1;
			}
			return 0;
		case kTableSectionLocate:
			if (self.from || !self.tripQuery.userRequest.fromPoint.useCurrentLocation)
			{
				return kTableLocateRows;
			}
			return 0;
		case kTableSectionEnterDestination:
			return kTableEnterRows;
		case kTableSectionFaves:
			if (self.tripQuery.userFaves!=nil)
			{
				return [self.tripQuery.userFaves count];
			}
	}
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section)
	{
		case kTableSectionEnterDestination:
			if (self.from)
			{
				return @"Choose starting address, or stop:";
			}
			else
			{
				return @"Choose destination, or stop:";
			}
		case kTableSectionFaves:
			if (self.tripQuery.userFaves!=nil && [self.tripQuery.userFaves count] > 0)
			{
				return @"Bookmarks:";
			}
		case kTableSectionWalk:
			if (self.from)
			{
				// return @"Options:";
			}
			return nil;
	}
	return nil;
}

-(bool)multipleStopsForFave:(int)index
{
	NSMutableDictionary * item = (NSMutableDictionary *)[self.tripQuery.userFaves objectAtIndex:index];
	NSString *location = [item valueForKey:kUserFavesLocation];
	
	NSCharacterSet *comma = [NSCharacterSet characterSetWithCharactersInString:@","];
	NSRange commas = [location rangeOfCharacterFromSet:comma];
	
	return (commas.location != NSNotFound);
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section)
	{
		case kTableSectionEnterDestination:
		{
			switch (indexPath.row)
			{
				case kTableEnterRowEnter:
				{
	
					if (self.editCell == nil)
					{
						self.editCell =  [[[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kTextFieldId] autorelease];	
						self.editCell.view = [self createTextField_Rounded];
						self.editCell.delegate = self;
						self.placeNameField = self.editCell.view;
						// self.editCell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
						self.editCell.imageView.image = [TableViewWithToolbar alwaysGetIcon:kIconEnterStopID]; 
						self.editCell.cellLeftOffset = 40.0;
						
						if ([self endPoint].useCurrentLocation)
						{
							self.editCell.view.placeholder=kTextGPSPlaceHolder;
						}
						else
						{
							if (self.from)
							{
								self.editCell.view.placeholder=kStartTextDescPlaceHolder;
							} else {
								self.editCell.view.placeholder=kDestinationTextDescPlaceHolder;
							}
						}
					}
			
					if ([self endPoint] != nil && [self endPoint].locationDesc!= nil && ![self endPoint].useCurrentLocation)
					{
						self.editCell.view.text = [self endPoint].locationDesc;
					}
					else
					{
						self.editCell.view.text = @"";
					}
					return self.editCell;
				}
				case kTableEnterRowBrowse:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPlainFieldId];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kPlainFieldId] autorelease];
					}
					if (self.from)
					{
						cell.textLabel.text = @"Browse for starting stop";
					}
					else
					{
						cell.textLabel.text = @"Browse for destination stop";
					}
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.imageView.image = [self getActionIcon:kIconBrowse]; 
					cell.textLabel.font = [self getBasicFont];
					cell.textLabel.adjustsFontSizeToFitWidth = YES;
					
					return cell;
				}
				case kTableEnterRowRailMap:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPlainFieldId];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kPlainFieldId] autorelease];
					}
					if (self.from)
					{
						cell.textLabel.text = @"Select from rail maps";
					}
					else
					{
						cell.textLabel.text = @"Select from rail maps";
					}
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.imageView.image = [self getActionIcon:kIconMaxMap];
					cell.textLabel.font = [self getBasicFont];
					
					return cell;
				}
				case kTableEnterRowRailStations:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPlainFieldId];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kPlainFieldId] autorelease];
					}
					cell.textLabel.text = @"Search rail stations";
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.imageView.image = [self getActionIcon:KIconRailStations]; 
					cell.textLabel.font = [self getBasicFont];
					
					return cell;
				}
				case kTableEnterRowContacts:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPlainFieldId];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kPlainFieldId] autorelease];
					}	
					cell.textLabel.text = @"Address from contacts";
					
					if (self.from)
					{
						[cell setAccessibilityLabel:@"Choose starting address from contacts"];
					}
					else
					{
						[cell setAccessibilityLabel:@"Choose destination address from contacts"];
					}
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.imageView.image = [self getActionIcon:kIconContacts];
					cell.textLabel.font = [self getBasicFont];
					return cell;
				}
			}
			break;
		}
		case kTableSectionFaves:
		{	
			static NSString *faveId = @"fave";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:faveId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:faveId] autorelease];
			}
			
			if ([self multipleStopsForFave:indexPath.row])
			{
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
			else {
				cell.accessoryType = UITableViewCellAccessoryNone;
			}

			
			// Set up the cell
			NSDictionary *item = (NSDictionary *)[self.tripQuery.userFaves objectAtIndex:indexPath.row];
			// printf("item %p\n", item);
			
			cell.textLabel.text = [item valueForKey:kUserFavesChosenName];
			cell.textLabel.font = [self getBasicFont];
			[self updateAccessibility:cell indexPath:indexPath text:cell.textLabel.text alwaysSaySection:YES];
			cell.imageView.image = [self getFaveIcon:kIconFave];
			return cell;
		}
		case kTableSectionLocate:
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kPlainFieldId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kPlainFieldId] autorelease];
			}
			
			if (self.from)
			{
				cell.textLabel.text = @"Start from current location (GPS)";
			}
			else
			{
				cell.textLabel.text = @"Go to current location (GPS)";
			}
			cell.textLabel.font = [self getBasicFont];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.imageView.image = [self getActionIcon:kIconLocate];
			cell.textLabel.adjustsFontSizeToFitWidth = YES;
			return cell;
		}
		case kTableSectionWalk:
		{
			
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kOptionsFieldId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kOptionsFieldId] autorelease];
			}
			
            NSString *walk =
                [[XMLTrips distanceMapSingleton] objectAtIndex:
                 [XMLTrips distanceToIndex:self.tripQuery.userRequest.walk]];
			
			cell.textLabel.text = [NSString stringWithFormat:@"Max walking distance: %@ miles\nTravel by: %@\nShow me the: %@", 
								   walk,
								   [self.tripQuery.userRequest getMode], [self.tripQuery.userRequest getMin]];
			[cell setAccessibilityLabel:[NSString stringWithFormat:@"Max walking distance: %@ miles, Travel by: %@, Show me the:%@", 
										 walk,
										 [self.tripQuery.userRequest getMode], [self.tripQuery.userRequest getMin]]];
			cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
			cell.textLabel.numberOfLines = 0;
			cell.textLabel.font = [self getBasicFont];;
		
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			return cell;
		
		}
	}
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case kTableSectionEnterDestination:
		{
			switch (indexPath.row) {
				case kTableEnterRowEnter:
					return [CellTextField cellHeight];
				default:
					return [self basicRowHeight];
			}
		}
		case kTableSectionWalk:
			return kSegRowHeight;
		default:
			break;
				
	}
	return kUIRowHeight;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	
	[self hideKeyboard];
	
	switch (indexPath.section)
	{
		case kTableSectionEnterDestination:
		{
			switch (indexPath.row) {
				case kTableEnterRowRailMap:
					// self.navigationItem.rightBarButtonItem = nil;
					[self selectFromRailMap];
					break;
				case kTableEnterRowRailStations:
					// self.navigationItem.rightBarButtonItem = nil;
					[self selectFromRailStations];
					break;	
				case kTableEnterRowBrowse:
					// self.navigationItem.rightBarButtonItem = nil;
					[self browseForStop];
					break;
				case kTableEnterRowContacts:
				{					
					// self.navigationItem.rightBarButtonItem = nil;
					ABPeoplePickerNavigationController *contactPicker = [[ABPeoplePickerNavigationController alloc] init];
			
					contactPicker.peoplePickerDelegate = self;
			
					contactPicker.displayedProperties = [[[NSArray alloc] initWithObjects:[NSNumber numberWithInt:kABPersonAddressProperty], nil] autorelease];
			
					[self presentModalViewController:contactPicker animated:YES];
					[contactPicker release];
					break;
				}
			}
			break;
		}
		case kTableSectionFaves:
		{
			
			NSMutableDictionary * item = (NSMutableDictionary *)[self.tripQuery.userFaves objectAtIndex:indexPath.row];
			NSString *location = [item valueForKey:kUserFavesLocation];
			
						
			if (![self multipleStopsForFave:indexPath.row])
			{
				// Set up the cell
				NSDictionary *item = (NSDictionary *)[self.tripQuery.userFaves objectAtIndex:indexPath.row];
				// printf("item %p\n", item);
				
				[self gotPlace:location setUiText:YES additionalInfo:[item valueForKey:kUserFavesChosenName]];
				
			}
			else
			{
				TripPlannerBookmarkView *bmView = [[TripPlannerBookmarkView alloc] init];
				bmView.callback = self;
				bmView.from = self.from;
			
				// bmView.displayName = [item valueForKey:kUserFavesOriginalName];
				[bmView fetchNamesForLocationsInBackground:self.backgroundTask loc:location];
				[bmView release];
			}
			break;
		}
		case kTableSectionLocate:
		{
			[self initEndPoint];
			[self endPoint].useCurrentLocation = YES;
			self.placeNameField.text =@"";
			self.placeNameField.placeholder=kTextGPSPlaceHolder;
			
			[self nextScreen];
			break;
		}
		case kTableSectionWalk:
		{
			TripPlannerOptions * options = [[ TripPlannerOptions alloc ] init];
			
			options.tripQuery = self.tripQuery;
			
			[[self navigationController] pushViewController:options animated:YES];

			
			[options release];
			break;
		}
			
	}
}




- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	UITextView *textView = (UITextView*)[self.editCell view];
	
	if (keyboardUp)
	{
		[self.placeNameField resignFirstResponder];
	}
	else
	{
		if ([textView.text length] == 0 && [self endPoint].useCurrentLocation)
		{
			[self nextScreen];
		}
		else
		{
			[self gotPlace:textView.text setUiText:NO additionalInfo:nil];
		}
	}	
}

#pragma mark ReturnStopID methods

- (NSString *)actionText
{
	if (self.from)
	{
		return @"Set as starting stop";
	}
	return @"Set as destination";
	
}

- (void) selectedStop:(NSString *)stopId
{
	
}

-(void) selectedStop:(NSString *)stopId desc:(NSString*)stopDesc
{
	if (stopId !=nil)
	{
		[self gotPlace:stopId setUiText:YES additionalInfo:stopDesc];
	}
}

- (UIViewController*) getController
{
	return self;
}

#pragma mark People Picker methods

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
	[self dismissModalViewControllerAnimated:YES];
}

// Called after a person has been selected by the user.
// Return YES if you want the person to be displayed.
// Return NO  to do nothing (the delegate is responsible for dismissing the peoplePicker).
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
//	[self dismissModalViewControllerAnimated:YES];
	return YES;
}

- (void)delayedCompletion:(NSTimer *)timer
{
    NSString *address = (NSString *)[timer userInfo];
    
    [self gotPlace:address setUiText:YES additionalInfo:nil];
}

// Called after a value has been selected by the user.
// Return YES if you want default action to be performed.
// Return NO to do nothing (the delegate is responsible for dismissing the peoplePicker).
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	//[self dismissModalViewControllerAnimated:YES];
	NSMutableString *address = [[[NSMutableString alloc] init] autorelease];
	CFDictionaryRef dict     = nil;
	
	if (person != 0 && property != 0)
	{
		ABMutableMultiValueRef multiValue = ABRecordCopyValue(person, property);
	
		if (multiValue !=nil)
		{
			dict = ABMultiValueCopyValueAtIndex(multiValue, identifier);
			CFRelease(multiValue);
		}
	}
	
	if (dict != nil)
	{

		NSString* item = (NSString *)CFDictionaryGetValue(dict, kABPersonAddressStreetKey);
		
		if (item && [item length] > 0)
		{
			[address appendString:item];
		}
		
		item = (NSString *)CFDictionaryGetValue(dict,  kABPersonAddressCityKey);
		
		if (item && [item length] > 0)
		{
			if ([address length] > 0)
			{
				[address appendString:@", "];
			}
			[address appendString:item];
		}
		/*
		 if (item)
		 {
		 [item release];
		 }
		 */
		
		item = (NSString *)CFDictionaryGetValue(dict, kABPersonAddressStateKey);
		
		if (item && [item length] > 0)
		{
			if ([address length] > 0)
			{
				[address appendString:@","];
			}
			[address appendString:item];
		}
		/*
		 if (item)
		 {
		 [item release];
		 }
		 */
		[self dismissModalViewControllerAnimated:YES];
		
#ifdef ORIGINAL_IPHONE
        NSDate *soon = [[NSDate date] addTimeInterval:0.1];
#else
        NSDate *soon = [[NSDate date] dateByAddingTimeInterval:0.1];
#endif
        NSTimer *timer = [[[NSTimer alloc] initWithFireDate:soon interval:0.1 target:self selector:@selector(delayedCompletion:) userInfo:address repeats:NO] autorelease];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
		
		CFRelease(dict);
	}

	return NO;
}

@end

