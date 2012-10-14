//
//  TripPlannerResultsView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/28/09.
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

#import "TripPlannerResultsView.h"
#import "CellLabel.h"
#import "DepartureTimesView.h"
#import "MapViewController.h"
#import "SimpleAnnotation.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "TriMetTimesAppDelegate.h"
#import "TripPlannerDateView.h"
#import "DepartureTimesView.h"
#import "NetworkTestView.h"
#import "WebViewController.h"
#import "TripPlannerMap.h"
#include "UserFaves.h"
#include "EditBookMarkView.h"
#include "AppDelegateMethods.h"
#import <MessageUI/MessageUI.h>
#include "TripPlannerEndPointView.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "TripPlannerSummaryView.h"
#import "DetoursView.h"

#define kRowTypeLeg			0
#define kRowTypeDuration	1
#define kRowTypeFare		2
#define kRowTypeMap			3
#define kRowTypeEmail		4
#define kRowTypeSMS			5
#define kRowTypeCal         6
#define kRowTypeClipboard	7
#define kRowTypeArrivals	8
#define kRowTypeDetours		9
#define kRowAdditionalRows  8

#define kRowTypeError		10
#define kRowTypeReverse		11
#define kRowTypeDisclaimer  12
#define kRowTypeFrom		13
#define kRowTypeTo			14
#define kRowTypeOptions		15
#define kRowTypeDateAndTime 16


#define kSectionTypeEndPoints	0
#define kSectionTypeOptions		1
#define kSectionTypeDisclaimer	2

#define kDefaultRowHeight		40.0
#define kRowsInDisclaimerSection 2

#define KDisclosure UITableViewCellAccessoryDisclosureIndicator
#define kScheduledText @"The trip planner shows scheduled service only. Check below to see how detours may affect your trip."

@implementation TripPlannerResultsView

@synthesize tripQuery = _tripQuery;
@synthesize calendarItinerary = _calendarItinerary;

- (void)dealloc {
	self.tripQuery = nil;
	self.calendarItinerary = nil;
	[super dealloc];
}

- (id)init
{
	if ((self = [super init]))
	{
		_recentTripItem = -1;
	}
	
	return self;
	
}

- (id)initWithHistoryItem:(int)item
{
	if ((self = [super init]))
	{
		[self setItemFromHistory:item];
	}
	
	return self;
}
- (void)setItemFromHistory:(int)item
{
	NSDictionary *trip = nil;
	@synchronized (_userData)
	{
		trip = [_userData.recentTrips objectAtIndex:item];
	
		self.tripQuery = [[[XMLTrips alloc] init] autorelease];
	
	
		self.tripQuery.userRequest = [[[TripUserRequest alloc] initFromDict:[trip objectForKey:kUserFavesTrip]] autorelease];
		// trips.rawData     = [trip objectForKey:kUserFavesTripResults];
	

		[self.tripQuery addStopsFromUserFaves:_userData.faves];
	}
	[self.tripQuery fetchItineraries:[trip objectForKey:kUserFavesTripResults]];
	
	_recentTripItem = item;
}

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

- (void)createToolbarItems
{	
	// match each of the toolbar item's style match the selection in the "UIBarButtonItemStyle" segmented control
	UIBarButtonItemStyle style = UIBarButtonItemStylePlain;
	
	
	
	
	// create the system-defined "OK or Done" button
    UIBarButtonItem *bookmark = [[UIBarButtonItem alloc]
								 initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
								 target:self action:@selector(bookmarkButton:)];
	bookmark.style = style;
	
	// create the system-defined "OK or Done" button
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithTitle:@"Redo" 
															 style:UIBarButtonItemStyleBordered 
															target:self 
															action:@selector(showCopy:)];
	
	// create the system-defined "OK or Done" button
	
	NSMutableArray *items = nil;
	
    
	items = [NSMutableArray arrayWithObjects:	[self autoDoneButton],
										[CustomToolbar autoFlexSpace], 
										bookmark,  
										[CustomToolbar autoFlexSpace],
										edit,
                                        [CustomToolbar autoFlexSpace],
                                        nil];
    
    if ([UserPrefs getSingleton].debugXML)
    {
        [items addObject:[self autoXmlButton]];
        [items addObject:[CustomToolbar autoFlexSpace]];
    }
    
    [items addObject:[self autoFlashButton]];
	
	[self setToolbarItems:items animated:NO];
	
	[bookmark release];
	[edit release];
}

- (void)appendXmlData:(NSMutableData *)buffer
{
    [self.tripQuery appendQueryAndData:buffer];
}

#pragma mark View methods


- (void)enableArrows:(UISegmentedControl*)seg
{
	[seg setEnabled:(_recentTripItem > 0) forSegmentAtIndex:0];
	
	[seg setEnabled:(_recentTripItem < (_userData.recentTrips.count-1)) forSegmentAtIndex:1];

}

- (void)upDown:(id)sender
{
	UISegmentedControl *segControl = sender;
	switch (segControl.selectedSegmentIndex)
	{
		case 0:	// UIPickerView
		{
			// Up
			if (_recentTripItem > 0)
			{
				[self setItemFromHistory:_recentTripItem-1];
				[self reloadData];
			}
			break;
		}
		case 1:	// UIPickerView
		{
			if (_recentTripItem < (_userData.recentTrips.count-1) )
			{
				[self setItemFromHistory:_recentTripItem+1];
				[self reloadData];
			}
			break;
		}
	}
	[self enableArrows:segControl];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"Trip";
	
	if (self.tripQuery.resultFrom != nil && self.tripQuery.resultTo != nil)
	{
		itinerarySectionOffset = 1; 
	}
	else
	{
		itinerarySectionOffset = 0;
	}
	
	Class messageClass = (NSClassFromString(@"MFMessageComposeViewController"));
    
    if (messageClass != nil) {          
        // Check whether the current device is configured for sending SMS messages
        if ([messageClass canSendText]) {
            _smsRows = 1;
        }
        else {  
            _smsRows = 0;			
        }
    }
	
	Class eventClass = (NSClassFromString(@"EKEventEditViewController"));
	
	if (eventClass != nil) {
		_calRows = 1;
	}
	else {
		_calRows = 0;
	}
	
	if (_recentTripItem >=0)
	{
		UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects: 
											[TableViewWithToolbar getToolbarIcon:kIconUp],
											[TableViewWithToolbar getToolbarIcon:kIconDown], nil] ];
		seg.frame = CGRectMake(0, 0, 60, 30.0);
		seg.segmentedControlStyle = UISegmentedControlStyleBar;
		seg.momentary = YES;
		[seg addTarget:self action:@selector(upDown:) forControlEvents:UIControlEventValueChanged];
		
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView: seg] autorelease];
		
		[self enableArrows:seg];
		[seg release];
		
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

#pragma mark UI helpers

- (int)sectionType:(int)section
{
	if (section < itinerarySectionOffset)	
	{
		return kSectionTypeEndPoints;
	}
	else if ((section - itinerarySectionOffset) < self.tripQuery.safeItemCount)
	{
		return kSectionTypeOptions;
	}
	return kSectionTypeDisclaimer;
}

- (TripItinerary *)getSafeItinerary:(int)section
{
	if ([self sectionType:section] ==  kSectionTypeOptions)
	{
		return [self.tripQuery itemAtIndex:section - itinerarySectionOffset]; 
	}
	return nil;
}

- (int)legRows:(TripItinerary *)it
{
	return [it.displayEndPoints count];
}

- (int)rowType:(NSIndexPath *)indexPath
{
	int sectionType = [self sectionType:indexPath.section];
	
	switch (sectionType)
	{
		case kSectionTypeEndPoints:
			return indexPath.row + kRowTypeFrom;
		case kSectionTypeOptions:
		{
			TripItinerary *it = [self getSafeItinerary:indexPath.section];
			int legs = [self legRows:it];
			
			if (legs == 0)	
			{
				return kRowTypeError;
			}
			
			if (indexPath.row < legs)
			{
				return kRowTypeLeg;
			}
			else
			{
				int row = 1 + indexPath.row - legs;
				if (row >= kRowTypeFare && ![it hasFare])
				{
					row ++;
				}
				
				if (row >= kRowTypeSMS && _smsRows == 0)
				{
					row ++;
				}
				
				if (row >= kRowTypeCal && _calRows == 0)
				{
					row ++;
				}
				return row;
			}
		}
		case kSectionTypeDisclaimer:
			if (self.tripQuery.reversed)
			{
				return kRowTypeDisclaimer;
			}
			else
			{
				return kRowTypeReverse + indexPath.row;
			}
	}
	return kRowTypeDisclaimer;
}


- (NSString *)getTextForLeg:(NSIndexPath *)indexPath
{
	TripItinerary *it = [self getSafeItinerary:indexPath.section];
	
	if (indexPath.row < [self legRows:it])
	{
		return ((TripLegEndPoint*)[it.displayEndPoints objectAtIndex:indexPath.row]).displayText;
	}
	
	return nil;
	
}

-(void)showCopy:(id)sender
{
	XMLTrips * copy = [self.tripQuery createAuto];
	
	TripPlannerSummaryView *trip = [[TripPlannerSummaryView alloc] init];
	trip.tripQuery = copy;
	
	// Push the detail view controller
	[[self navigationController] pushViewController:trip animated:YES];
	
	[trip release];
	
}


- (NSString*)getFromText
{
	//	if (self.tripQuery.fromPoint.useCurrentPosition)
	//	{
	//		return [NSString stringWithFormat:@"From: %@, %@", self.tripQuery.fromPoint.lat, self.tripQuery.fromPoint.lng];
	//	}	
	return self.tripQuery.resultFrom.xdescription;
}

- (NSString*)getToText
{
	//	if (self.tripQuery.toPoint.useCurrentPosition)
	//	{
	//		return [NSString stringWithFormat:@"To: %@, %@", self.tripQuery.toPoint.lat, self.tripQuery.toPoint.lng];
	//	}
	return self.tripQuery.resultTo.xdescription;
}




-(void)selectLeg:(TripLegEndPoint *)leg
{
	NSString *stopId = [leg stopId];
	
	if (stopId != nil)
	{
		DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
		
		departureViewController.displayName = @"";
		[departureViewController fetchTimesForLocationInBackground:self.backgroundTask loc:stopId];
		[departureViewController release];
	}
	else if (leg.xlat !=0 && leg.xlon !=0)
	{
		MapViewController *mapPage = [[MapViewController alloc] init];
		SimpleAnnotation *pin = [[[SimpleAnnotation alloc] init] autorelease];
		mapPage.callback = self.callback;
		[pin setCoordinateLat:leg.xlat lng:leg.xlon ];
		pin.pinTitle = leg.xdescription;
		pin.pinColor = MKPinAnnotationColorPurple;
		
		
		[mapPage addPin:pin];
		mapPage.title = leg.xdescription; 
		[[self navigationController] pushViewController:mapPage animated:YES];
		[mapPage release];	
	}	
	
	
}

#pragma mark UI Callback methods

-(void)bookmarkButton:(id)sender
{
	NSString *desc = nil;
	@synchronized (_userData)
	{
		int i;
	
		_bookmarkItem = kNoBookmark;
		TripUserRequest * req = [[[TripUserRequest alloc] init] autorelease];
	
		for (i=0; _userData.faves!=nil &&  i< [_userData.faves count]; i++)
		{
			NSDictionary *bm = [_userData.faves objectAtIndex:i];
			NSDictionary * faveTrip = (NSDictionary *)[bm objectForKey:kUserFavesTrip];
		
			if (bm!=nil && faveTrip != nil)
			{
				[req fromDictionary:faveTrip];
				if ([req equalsTripUserRequest:self.tripQuery.userRequest])
				{
					_bookmarkItem = i;
					desc = [bm objectForKey:kUserFavesChosenName];
					break;
				}
			}
		
		}
	}
	
	if (_bookmarkItem == kNoBookmark)
	{
		UIActionSheet *actionSheet = [[[ UIActionSheet alloc ] initWithTitle:@"Bookmark Trip"
																	delegate:self
														   cancelButtonTitle:@"Cancel" 
													  destructiveButtonTitle:nil
														   otherButtonTitles:@"Add new bookmark", nil] autorelease];
		actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
		[actionSheet showFromToolbar:self.navigationController.toolbar]; // show from our table view (pops up in the middle of the table)
	}
	else {
		UIActionSheet *actionSheet = [[[ UIActionSheet alloc ] initWithTitle:desc
																	delegate:self
														   cancelButtonTitle:@"Cancel"
													  destructiveButtonTitle:@"Delete this bookmark"
														   otherButtonTitles:@"Edit this bookmark",
									   @"Add new bookmark", nil] autorelease];
		actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
		[actionSheet showFromToolbar:self.navigationController.toolbar]; // show from our table view (pops up in the middle of the table)
	}	
}

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (_bookmarkItem == kNoBookmark)
	{
		if (buttonIndex == 0)
		{
			EditBookMarkView *edit = [[EditBookMarkView alloc] init];
			// [edit addBookMarkFromStop:self.bookmarkDesc location:self.bookmarkLoc];
			[edit addBookMarkFromUserRequest:self.tripQuery];
			// Push the detail view controller
			[[self navigationController] pushViewController:edit animated:YES];
			[edit release];
		}
	}	
	else {
		switch (buttonIndex)
		{
			case 0:  // Delete this bookmark
			{
				@synchronized (_userData)
				{
					[_userData.faves removeObjectAtIndex:_bookmarkItem];
					_userData.favesChanged = YES;
					[_userData cacheAppData];
					break;
				}
			}
			case 1:  // Edit this bookmark
			{
				EditBookMarkView *edit = [[EditBookMarkView alloc] init];
				[edit editBookMark:[_userData.faves objectAtIndex:_bookmarkItem] item:_bookmarkItem];
				// Push the detail view controller
				[[self navigationController] pushViewController:edit animated:YES];
				[edit release];
				break;
				
			}
			case 2:  // Add new bookmark
			{
				EditBookMarkView *edit = [[EditBookMarkView alloc] init];
				// [edit addBookMarkFromStop:self.bookmarkDesc location:self.bookmarkLoc];
				[edit addBookMarkFromUserRequest:self.tripQuery];
				
				// Push the detail view controller
				[[self navigationController] pushViewController:edit animated:YES];
				[edit release];
				break;
			}
			case 3:  // Cancel
				break;
		}
	}
	
}



#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.tripQuery.safeItemCount+1+itinerarySectionOffset;
}



// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	TripItinerary *it = [self getSafeItinerary:section];
	
	switch ([self sectionType:section])
	{
		case kSectionTypeEndPoints:
			return 4;
		case kSectionTypeOptions:
			if ([self legRows:it] > 0)
			{
				return [self legRows:it] + kRowAdditionalRows - ([it hasFare] ? 0 : 1) -1 + _smsRows + _calRows;
			}
			return 1;
		case kSectionTypeDisclaimer:
			if (self.tripQuery.reversed)
			{
				return 1;
			}
			return 2;
	}

	// Disclaimer row
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch ([self sectionType:section])
	{
	case kSectionTypeEndPoints:	
		return @"The trip planner shows scheduled service only. Check below to see how detours may affect your trip.\n\nYour trip:";
		break;
	case kSectionTypeOptions:
		{
			TripItinerary *it = [self getSafeItinerary:section];

			int legs = [self legRows:it];
	
			if (legs > 0)
			{
				return [NSString stringWithFormat:@"Option %d - %@", section + 1 - itinerarySectionOffset, [it getShortTravelTime]];
			}
			else
			{
				return @"No route was found:";
			}
		}
	case kSectionTypeDisclaimer:
		// return @"Other options";
		break;
	}
	return nil;
}



// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	int rowType = [self rowType:indexPath];
	
	switch (rowType)
	{
		case kRowTypeError:
		case kRowTypeLeg:
		case kRowTypeDuration:
		case kRowTypeFare:
		case kRowTypeFrom:
		case kRowTypeTo:
		case kRowTypeDateAndTime:
		case kRowTypeOptions:
		{
			CGFloat h = [self tableView:[self table] heightForRowAtIndexPath:indexPath];

			NSString *cellIdentifier = [NSString stringWithFormat:@"TripLeg%f+%d", h,[self screenWidth]];
			TripItinerary *it = [self getSafeItinerary:indexPath.section];
	
			UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			if (cell == nil) {
				
				
				cell = [TripLeg tableviewCellWithReuseIdentifier: cellIdentifier 
													   rowHeight: h 
													 screenWidth: [self screenWidth]];
			}
	
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.accessoryType = UITableViewCellAccessoryNone;
    

			switch (rowType)
			{
				case kRowTypeError:
					[TripLeg populateCell:cell body:it.xmessage mode:@"No" time:@"Route" leftColor:nil route:nil];
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					
					if (![self.tripQuery gotData])
					{
						cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					}
					
					// [TripLeg populateCell:cell body:it.xmessage mode:nil time:nil];
					// cell.view.text = it.xmessage;
					break;
				case kRowTypeLeg:
					{
						TripLegEndPoint * ep = [it.displayEndPoints objectAtIndex:indexPath.row];
						[TripLeg populateCell:cell body:ep.displayText mode:ep.displayModeText time:ep.displayTimeText leftColor:ep.leftColor
										route:ep.xnumber];
						
						//[TripLeg populateCell:cell body:@"l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l l" 
						//				 mode:ep.displayModeText time:ep.displayTimeText leftColor:ep.leftColor
						//				route:ep.xnumber];
									
						
						if (ep.xstopId!=nil || ep.xlat !=nil)
						{
							cell.selectionStyle = UITableViewCellSelectionStyleBlue;	
							cell.accessoryType = KDisclosure; 
						}
						else
						{
							cell.selectionStyle = UITableViewCellSelectionStyleNone;	
							cell.accessoryType = UITableViewCellAccessoryNone;
						}
					}
					// cell.view.text = [self getTextForLeg:indexPath];
			
				//printf("width: %f\n", cell.view.frame.size.width);
					break;
				case kRowTypeDuration:
					[TripLeg populateCell:cell body:[it getTravelTime] mode:@"Travel" time:@"time" leftColor:nil route:nil];
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					cell.accessoryType = UITableViewCellAccessoryNone;
					// justText = [it getTravelTime];
					break;
				case kRowTypeFare:
					[TripLeg populateCell:cell body:it.fare mode:@"Fare" time:nil leftColor:nil route:nil];
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					cell.accessoryType = UITableViewCellAccessoryNone;
					// justText = it.fare;
					break;
				case kRowTypeFrom:
					[TripLeg populateCell:cell body:[self getFromText] mode:@"From" time:nil leftColor:nil route:nil];
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				case kRowTypeOptions:
					[TripLeg populateCell:cell body:[self.tripQuery.userRequest optionsDisplayText] mode:@"Options" time:nil 
								leftColor:nil
									route:nil];
					
					[cell setAccessibilityLabel: [self.tripQuery.userRequest optionsAccessability]];
					
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					cell.accessoryType = UITableViewCellAccessoryNone;
					break;
				case kRowTypeTo:
					[TripLeg populateCell:cell body:[self getToText] mode:@"To" time:nil leftColor:nil route:nil];
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				
				case kRowTypeDateAndTime:
					[TripLeg populateCell:cell body:[self.tripQuery.userRequest getDateAndTime] 
									 mode:[self.tripQuery.userRequest getTimeType] 
									 time:nil 
								leftColor:nil
									route:nil];
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					cell.accessoryType = UITableViewCellAccessoryNone;
					break;					
			}
			[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:NO];
			return cell;
		}
		case kRowTypeDisclaimer:
		{
			UITableViewCell *cell  = [tableView dequeueReusableCellWithIdentifier:kDisclaimerCellId];
			if (cell == nil) {
				cell = [self disclaimerCellWithReuseIdentifier:kDisclaimerCellId];
			}
		
			if (self.tripQuery.xdate != nil && self.tripQuery.xtime!=nil)
			{
				[self addTextToDisclaimerCell:cell text:[NSString stringWithFormat:@"Updated %@ %@", self.tripQuery.xdate, self.tripQuery.xtime]];
			}
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:NO];
			return cell;
		}
		case kRowTypeMap:
		case kRowTypeEmail:
		case kRowTypeSMS:
		case kRowTypeCal:
		case kRowTypeClipboard:
		case kRowTypeReverse:
		case kRowTypeArrivals:
		case kRowTypeDetours:
		{
			static NSString *CellIdentifier = @"TripAction";
			
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			}	
			switch (rowType)
			{
				case kRowTypeDetours:
					cell.textLabel.text = @"Check detours";
					cell.imageView.image = [self getActionIcon:kIconDetour];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				case kRowTypeMap:
					cell.textLabel.text = @"Show on map";
					cell.imageView.image = [self getActionIcon:kIconMapAction];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				case kRowTypeEmail:
					cell.textLabel.text = @"Send by email";
					cell.imageView.image = [self getActionIcon:kIconEmail];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				case kRowTypeSMS:
					cell.textLabel.text = @"Send by text message";
					cell.imageView.image = [self getActionIcon:kIconCell];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				case kRowTypeCal:
					cell.textLabel.text = @"Add to calendar";
					cell.imageView.image = [self getActionIcon:kIconCal];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				case kRowTypeClipboard:
					cell.textLabel.text = @"Copy to clipboard";
					cell.imageView.image = [self getActionIcon:kIconCut];
					cell.accessoryType = UITableViewCellAccessoryNone;
					break;
				case kRowTypeReverse:
					cell.textLabel.text = @"Reverse trip";
					cell.imageView.image = [self getActionIcon:kIconReverse];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				case kRowTypeArrivals:
					cell.textLabel.text = @"Arrivals for all stops";
					cell.imageView.image = [self getActionIcon:kIconArrivals];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;

			}
			cell.textLabel.textColor = [ UIColor grayColor];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.textLabel.font = [self getBasicFont];
			[self updateAccessibility:cell indexPath:indexPath text:cell.textLabel.text alwaysSaySection:NO];
			return cell;
		}
	}
	
	return nil;
}

- (CGFloat)fieldWidth
{
	return [TripLeg bodyTextWidthForScreenWidth:[self screenWidth]];
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	int rowType = [self rowType:indexPath];
	TripItinerary *it = [self getSafeItinerary:indexPath.section];
	// CGFloat width = [self variableTextFieldWidth];
	CGFloat shorterWidth = [self fieldWidth];

	switch (rowType)
	{
		case kRowTypeOptions:
			return [TripLeg getTextHeight:[self.tripQuery.userRequest optionsDisplayText] width:shorterWidth];
		case kRowTypeError:
			return [TripLeg getTextHeight:it.xmessage width:shorterWidth];
		case kRowTypeLeg:
			return [TripLeg getTextHeight:[self getTextForLeg:indexPath] width:shorterWidth];
		case kRowTypeDuration:
			return [TripLeg getTextHeight:[it getTravelTime] width:shorterWidth];
		case kRowTypeFare:
			return [TripLeg getTextHeight:it.fare width:shorterWidth];
		case kRowTypeFrom:
			return [TripLeg getTextHeight:[self getFromText] width:shorterWidth];
		case kRowTypeTo:
			return [TripLeg getTextHeight:[self getToText] width:shorterWidth];
			break;
		case kRowTypeEmail:
		case kRowTypeClipboard:
		case kRowTypeMap:
		case kRowTypeReverse:
		case kRowTypeArrivals:
		case kRowTypeSMS:
		case kRowTypeCal:
		case kRowTypeDetours:
			return [self basicRowHeight];
	}
	return kDisclaimerCellHeight;
}

- (NSString *)plainText:(TripItinerary *)it
{
	NSMutableString *trip = [[[NSMutableString alloc] init] autorelease];
	
//	TripItinerary *it = [self getSafeItinerary:indexPath.section];
	
	if (self.tripQuery.resultFrom != nil)
	{
		[trip appendFormat:@"From: %@\n",
		 self.tripQuery.resultFrom.xdescription
		 ];
	}
	
	if (self.tripQuery.resultTo != nil)
	{
		[trip appendFormat:@"To: %@\n",
		 self.tripQuery.resultTo.xdescription
		 ];
	}
	
	[trip appendFormat:@"%@: %@\n\n", [self.tripQuery.userRequest getTimeType], [self.tripQuery.userRequest getDateAndTime]];
	
	/*
	 [trip appendFormat:@"Max walk: %0.1f miles<br>Travel by: %@<br>Show the: %@<br><br>", self.tripQuery.walk,
	 [self.tripQuery getMode], [self.tripQuery getMin]];
	 */
	
	NSString *htmlText = [it startPointText:TripTextTypeClip];
	[trip appendString:htmlText];
	
	int i;
	for (i=0; i< [it legCount]; i++)
	{
		TripLeg *leg = [it getLeg:i];
		htmlText = [leg createFromText:(i==0) textType:TripTextTypeClip];
		[trip appendString:htmlText];
		htmlText = [leg createToText:(i==[it legCount]-1) textType:TripTextTypeClip];
		[trip appendString:htmlText];
	}
	
	[trip appendFormat:@"Scheduled travel time: %@\n\n",[it getTravelTime] ];
	
	if ([it fare] != nil)
	{
		[trip appendFormat:@"Fare: %@",[it fare] ];
	}
	
	return trip;
}

-(void)addCalendarItem:(EKEventStore *)eventStore
{
    if (eventStore==nil)
    {
        eventStore = [[[EKEventStore alloc] init] autorelease];
    }
    
    EKEvent *event  = [EKEvent eventWithEventStore:eventStore];
    event.title     = [NSString stringWithFormat:@"TriMet Trip\n%@", [self.tripQuery mediumName]];
    event.notes     = [NSString stringWithFormat:@"Note: ensure you leave early enough to arrive in time for the first connection.\n\n%@"
                       "\nRoute and arrival data provided by permission of TriMet.",
                       [self plainText:self.calendarItinerary]];
    
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    NSLocale *enUS = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
    [dateFormatter setLocale:enUS];
    
    [dateFormatter setDateFormat:@"M/d/yy hh:mm a"];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    NSString *fullDateStr = [NSString stringWithFormat:@"%@ %@", self.calendarItinerary.xdate, self.calendarItinerary.xstartTime];
    NSDate *start = [dateFormatter dateFromString:fullDateStr];
    
    
    
    // The start time does not include the inital walk so take it off...
    for (int i=0; i< [self.calendarItinerary legCount]; i++)
    {
        TripLeg *leg = [self.calendarItinerary getLeg:i];
        
        if (leg.mode == nil)
        {
            continue;
        }
        if ([leg.mode isEqualToString:kModeWalk])
        {
#ifdef ORIGINAL_IPHONE
            start = [start addTimeInterval: -([leg.xduration intValue] * 60)];
#else
            start = [start dateByAddingTimeInterval: -([leg.xduration intValue] * 60)];;
#endif
            
            
        }
        else {
            break;
        }
    }
#ifdef ORIGINAL_IPHONE
    NSDate *end   = [start addTimeInterval: [self.calendarItinerary.xduration intValue] * 60];
#else
    NSDate *end   = [start dateByAddingTimeInterval: [self.calendarItinerary.xduration intValue] * 60];
#endif
    
    
    event.startDate = start;
    event.endDate   = end;
    
    [event setCalendar:[eventStore defaultCalendarForNewEvents]];
    NSError *err;
    if ([eventStore saveEvent:event span:EKSpanThisEvent error:&err])
    {
        // Upon selecting an event, create an EKEventViewController to display the event.
        EKEventViewController *detailViewController = [[EKEventViewController alloc] initWithNibName:nil bundle:nil];
        detailViewController.event = event;
        detailViewController.title = @"Calendar Event";
        
        // Allow event editing.
        detailViewController.allowsEditing = YES;
        
        //	Push detailViewController onto the navigation controller stack
        //	If the underlying event gets deleted, detailViewController will remove itself from
        //	the stack and clear its event property.
        [self.navigationController pushViewController:detailViewController animated:YES];
        [detailViewController release];
    }
}
	
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	if (buttonIndex == 0)
	{
		NSIndexPath *ip = [self.table indexPathForSelectedRow];
		if (ip!=nil)
		{
			[self.table deselectRowAtIndexPath:ip animated:YES];
		}
	}
	else
	{
		EKEventStore *eventStore = [[[EKEventStore alloc] init] autorelease];
        
        
        // maybe check for access
        
        if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)])
        {
            
            [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
                
                if (granted)
                {
                    // [self addCalendarItem:nil];
                    [self performSelectorOnMainThread:@selector(addCalendarItem:) withObject:nil waitUntilDone:FALSE];
                }
                
            }];
        }
        else
        {
            [self addCalendarItem:eventStore];
        }
            
    }
		
}
	
	

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	switch ([self rowType:indexPath])
	{
		case kRowTypeError:
			if (![self.tripQuery gotData])
			{
				
				[self networkTips:self.tripQuery.htmlError networkError:self.tripQuery.errorMsg];
				
			}
			break;
		case kRowTypeTo:
		case kRowTypeFrom:
		{
			TripLegEndPoint *ep = nil;
			
			if ([self rowType:indexPath] == kRowTypeTo)
			{
				ep = self.tripQuery.resultTo;
			}
			else
			{
				ep = self.tripQuery.resultFrom;
			}
			
			[self selectLeg:ep];
			break;
		}
			
		case kRowTypeLeg:
			{
				TripItinerary *it = [self getSafeItinerary:indexPath.section];
				TripLegEndPoint *leg = [it.displayEndPoints objectAtIndex:indexPath.row];
				[self selectLeg:leg];
			}
			
			break;
		case kRowTypeDuration:
		case kRowTypeDisclaimer:
		case kRowTypeFare:
			break;
		case kRowTypeClipboard:
		{
			TripItinerary *it = [self getSafeItinerary:indexPath.section];
			[self.table deselectRowAtIndexPath:indexPath animated:YES];
			UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
			pasteboard.string = [self plainText:it];
			break;
		}
		case kRowTypeSMS:
		{
			TripItinerary *it = [self getSafeItinerary:indexPath.section];
			MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
			picker.messageComposeDelegate = self;
			
			picker.body = [self plainText:it];
			
			[self presentModalViewController:picker animated:YES];
			[picker release];
			break;
		}
		case kRowTypeCal:
		{
			self.calendarItinerary = [self getSafeItinerary:indexPath.section];
			
			UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Calendar"
															   message:@"Are you sure you want to add this to your default calendar?"
															  delegate:self
													 cancelButtonTitle:@"No"
													 otherButtonTitles:@"Yes", nil ] autorelease];
			[alert show];
			
				
	
		}
		break;
		case kRowTypeEmail:
		{
			
			
			NSMutableString *trip = [[NSMutableString alloc] init];
			
			TripItinerary *it = [self getSafeItinerary:indexPath.section];
			
			if (self.tripQuery.resultFrom != nil)
			{
				if (self.tripQuery.resultFrom.xlat!=nil)
				{
					[trip appendFormat:@"From: <a href=\"http://map.google.com/?q=location@%@,%@\">%@<br></a>",
							self.tripQuery.resultFrom.xlat, self.tripQuery.resultFrom.xlon,
							self.tripQuery.resultFrom.xdescription
					 ];
				}
				else
				{
					[trip appendFormat:@"%@<br>", [self getFromText]];
				}
			}
		
			if (self.tripQuery.resultTo != nil)
			{
				if (self.tripQuery.resultTo.xlat)
				{
					[trip appendFormat:@"To: <a href=\"http://map.google.com/?q=location@%@,%@\">%@<br></a>",
					 self.tripQuery.resultTo.xlat, self.tripQuery.resultTo.xlon,
					 self.tripQuery.resultTo.xdescription
					 ];
				}
				else
				{
					[trip appendFormat:@"%@<br>", [self getToText]];
				}
			}
			
			[trip appendFormat:@"%@:%@<br><br>", [self.tripQuery.userRequest getTimeType], [self.tripQuery.userRequest getDateAndTime]];
			
			/*
			[trip appendFormat:@"Max walk: %0.1f miles<br>Travel by: %@<br>Show the: %@<br><br>", self.tripQuery.walk,
					[self.tripQuery getMode], [self.tripQuery getMin]];
			 */
			
			NSString *htmlText = [it startPointText:TripTextTypeHTML];
			[trip appendString:htmlText];
			
			int i;
			for (i=0; i< [it legCount]; i++)
			{
				TripLeg *leg = [it getLeg:i];
				htmlText = [leg createFromText:(i==0) textType:TripTextTypeHTML];
				[trip appendString:htmlText];
				htmlText = [leg createToText:(i==[it legCount]-1) textType:TripTextTypeHTML];
				[trip appendString:htmlText];
			}
			
			[trip appendFormat:@"Travel time: %@<br><br>",[it getTravelTime] ];
			
			if ([it fare] != nil)
			{
				[trip appendFormat:@"Fare: %@<br><br>",[it fare] ];
			}
			
			MFMailComposeViewController *email = [[MFMailComposeViewController alloc] init];
			
			email.mailComposeDelegate = self;
			
			if (![MFMailComposeViewController canSendMail])
			{
				UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"email"
																   message:@"Cannot send email on this device"
																  delegate:nil
														 cancelButtonTitle:@"OK"
														 otherButtonTitles:nil] autorelease];
				[alert show];
				[email release];
				[trip release];
				break;
			}
			
			[email setSubject:@"TriMet Trip"];
			
			[email setMessageBody:trip isHTML:YES];
			
			[self presentModalViewController:email animated:YES];
			[email release];

			
			[trip release];
		}
		break;
		case kRowTypeMap:
		{
			TripPlannerMap *mapPage = [[TripPlannerMap alloc] init];
			mapPage.callback = self.callback;
			mapPage.lines = YES;
			TripItinerary *it = [self getSafeItinerary:indexPath.section];
			NSMutableArray *lineCoords = [[[NSMutableArray alloc] init] autorelease];
			
	
			int i,j = 0;
			for (i=0; i< [it legCount]; i++)
			{
				TripLeg *leg = [it getLeg:i];
				[leg createFromText:(i==0) textType:TripTextTypeMap];
				
				if (leg.from.mapText != nil)
				{
					j++;
					leg.from.index = j;
					
					[mapPage addPin:leg.from];
				}
				
				[leg createToText:(i==([it legCount]-1)) textType:TripTextTypeMap];
				if (leg.to.mapText != nil)
				{
					j++;
					leg.to.index = j;
					
					[mapPage addPin:leg.to];
				}
				
				if (leg.legShape && leg.legShape.shapeCoords)
				{
					[lineCoords addObjectsFromArray:leg.legShape.shapeCoords];
					[lineCoords addObject:[ShapeCoord makeEnd]];
				}
				
			}
			
			mapPage.it = it;
			
			if (![mapPage fetchShapesInBackground:self.backgroundTask])
			{
				mapPage.lineCoords = lineCoords;
				[[self navigationController] pushViewController:mapPage animated:YES];
			}
			
			[mapPage release];
		}
		break;
		case kRowTypeReverse:
		{
			XMLTrips * reverse = [self.tripQuery createReverse];
			
			TripPlannerDateView *tripDate = [[TripPlannerDateView alloc] init];
			
			tripDate.userFaves = reverse.userFaves;
			tripDate.tripQuery = reverse;
			
			// Push the detail view controller
			[tripDate nextScreen:[self navigationController] taskContainer:self.backgroundTask];
			[tripDate release];
			/*
			 TripPlannerEndPointView *tripStart = [[TripPlannerEndPointView alloc] init];
			 
			 // Push the detail view controller
			 [[self navigationController] pushViewController:tripStart animated:YES];
			 [tripStart release];
			 */
			break;
			
		}
		case kRowTypeDetours:
		{
			NSMutableArray *allRoutes = [[[NSMutableArray alloc] init] autorelease];
			NSString *route = nil;
			NSMutableSet *allRoutesSet = [[[NSMutableSet alloc] init] autorelease];
			
			TripItinerary *it = [self getSafeItinerary:indexPath.section];
			
			
			int i = 0;
			for (i=0; i< [it legCount]; i++)
			{
				TripLeg *leg = [it getLeg:i];
				
				route = [leg xinternalNumber];
				
				if (route && ![allRoutesSet containsObject:route])
				{
					[allRoutesSet addObject:route];
					
					[allRoutes addObject:route];
				}
				
			}
			
			if ([allRoutes count] >0 )
			{
				DetoursView *detourView = [[DetoursView alloc] init];
				[detourView fetchDetoursInBackground:self.backgroundTask routes:allRoutes];
				[detourView release];
			}
			break;
		}
		case kRowTypeArrivals:
		{
			NSMutableString *allstops = [[[NSMutableString alloc] init] autorelease];
			NSString *lastStop = nil;
			NSString *nextStop = nil;
			
			TripItinerary *it = [self getSafeItinerary:indexPath.section];
			
			
			int i = 0;
			int j = 0;
			for (i=0; i< [it legCount]; i++)
			{
				TripLeg *leg = [it getLeg:i];
				
				nextStop = [leg.from stopId];
				
				for (j=0; j<2; j++)
				{
					if (nextStop !=nil && (lastStop==nil || ![nextStop isEqualToString:lastStop]))
					{
						if ([allstops length] > 0)
						{
							[allstops appendFormat:@","];
						}
						[allstops appendFormat:@"%@", nextStop];
						lastStop = nextStop;
					}
					nextStop = [leg.to stopId];
				}
			}
			
			if ([allstops length] >0 )
			{
				DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
				

				[departureViewController fetchTimesForLocationInBackground:self.backgroundTask loc:allstops];
				[departureViewController release];
			}
			break;
		}
			
	}
}

#pragma mark Mail composer delegate

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark SMS composer delegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark EKEventEditViewDelegate

// Overriding EKEventEditViewDelegate method to update event store according to user actions.
- (void)eventEditViewController:(EKEventEditViewController *)controller 
		  didCompleteWithAction:(EKEventEditViewAction)action {
	
	NSError *error = nil;
	EKEvent *thisEvent = controller.event;
	
	switch (action) {
		case EKEventEditViewActionCanceled:
			// Edit action canceled, do nothing. 
			break;
			
		case EKEventEditViewActionSaved:
			[controller.eventStore saveEvent:controller.event span:EKSpanThisEvent error:&error];
			break;
			
		case EKEventEditViewActionDeleted:
			[controller.eventStore removeEvent:thisEvent span:EKSpanThisEvent error:&error];
			break;
			
		default:
			break;
	}
	// Dismiss the modal view controller
	[controller dismissModalViewControllerAnimated:YES];
	
}





@end

