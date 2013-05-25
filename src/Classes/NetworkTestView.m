//
//  NetworkTestView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 8/25/09.
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

#import "NetworkTestView.h"
#import "CellLabel.h"
#import "XMLDetour.h"
#import "XMLTrips.h"
#import "XMLStreetcarLocations.h"

@implementation NetworkTestView

@synthesize trimetQueryStatus			= _trimetQueryStatus;
@synthesize nextbusQueryStatus			= _nextbusQueryStatus;
@synthesize internetConnectionStatus	= _internetConnectionStatus;
@synthesize diagnosticText				= _diagnosticText;
@synthesize reverseGeoCodeService		= _reverseGeoCodeService;
@synthesize reverseGeoCodeStatus		= _reverseGeoCodeStatus;
@synthesize trimetTripStatus			= _trimetTripStatus;
@synthesize networkErrorFromQuery		= _networkErrorFromQuery;

#define KSectionMaybeError		0
#define kSectionInternet		1
#define kSectionTriMet			2
#define kSectionTriMetTrip		3
#define kSectionNextBus			4
#define kSectionReverseGeoCode	5
#define kSectionDiagnose		6
#define kSections				7
#define kNoErrorSections		6

- (void)dealloc {
	self.diagnosticText			= nil;
	self.reverseGeoCodeService	= nil;
	self.networkErrorFromQuery	= nil;
    [super dealloc];
}

#pragma mark Data fetchers

- (void)fetchData:(id)arg
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self.backgroundTask.callbackWhenFetching backgroundThread:[NSThread currentThread]];
	[self.backgroundTask.callbackWhenFetching backgroundStart:5 title:@"checking network"];
	
	self.internetConnectionStatus = [TriMetXML isDataSourceAvailable:YES];
	
	[self.backgroundTask.callbackWhenFetching backgroundItemsDone:1];
	
	XMLDetour *detours = [[ XMLDetour alloc] init];
	
	NSError *error = nil;
	
	[detours getDetours:&error];
	
	self.trimetQueryStatus = [detours gotData];
	
	[detours release];
	
	[self.backgroundTask.callbackWhenFetching backgroundItemsDone:2];
	
	XMLTrips *trips = [[[XMLTrips alloc] init] autorelease];
	trips.userRequest.dateAndTime = nil;
	trips.userRequest.arrivalTime = NO;
	trips.userRequest.timeChoice  = TripDepartAfterTime;
	trips.userRequest.toPoint.locationDesc   = @"8336"; // Yamhil District
	trips.userRequest.fromPoint.locationDesc = @"8334"; // Pioneer Square South
	
	[trips fetchItineraries:nil]; 
	
	self.trimetTripStatus = [trips gotData];
	
	[self.backgroundTask.callbackWhenFetching backgroundItemsDone:3];
	
	XMLStreetcarLocations *locations = [XMLStreetcarLocations getSingletonForRoute:@"streetcar"];
	
	[locations getLocations:&error];
	
	self.nextbusQueryStatus = [locations gotData];
	
	[self.backgroundTask.callbackWhenFetching backgroundItemsDone:4];
	
	XMLReverseGeoCode *provider = [UserPrefs getSingleton].reverseGeoCodeProvider;
	
	if (provider != nil)
	{
		// Pioneer Square!

		CLLocation *loc = [[[CLLocation alloc] initWithLatitude:45.519077 longitude:-122.678602] autorelease];
		[provider fetchAddress:loc];
		self.reverseGeoCodeStatus = [provider gotData];
		self.reverseGeoCodeService = [provider getServiceName];
	}
	else {
		self.reverseGeoCodeService = nil;
		self.reverseGeoCodeStatus = YES;
	}
	
	[self.backgroundTask.callbackWhenFetching backgroundItemsDone:5];

	NSMutableString *diagnosticString = [[[NSMutableString alloc] init] autorelease];
	
	if (!self.internetConnectionStatus)
	{
		[diagnosticString appendString:@"The Internet is not available. Check you are not in Airplane mode, and not in the Robertson Tunnel.\n\nIf your device is capable, you could also try switching between WiFi, Edge and 3G.\n\nTouch here to start Safari to check your connection. "];
	}
	else if (!self.trimetQueryStatus || !self.nextbusQueryStatus || !self.trimetTripStatus)
	{
		[diagnosticString appendString:@"The Internet is available, but PDX Bus is not able to contact TriMet's or NextBus's servers. Touch here to check if www.trimet.org is working."];
	}
	else
	{
		[diagnosticString appendString:@"The main network services are working at this time. If you are having problems, touch here to load www.trimet.org, then restart PDX Bus."];
	}
	
	if (self.internetConnectionStatus && !self.reverseGeoCodeStatus)
	{
		[diagnosticString appendFormat:@"\n\nThe reverse GeoCoding service, %@, is not responding. This may cause trip planning to take longer. You may wish to disable the closest address service in the PDXBus appliation settings.", self.reverseGeoCodeService];
	}
	
	self.diagnosticText = diagnosticString;
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];

	
	[pool release];
	
}

- (void)fetchNetworkStatusInBackground:(id<BackgroundTaskProgress>)background
{
	self.backgroundTask.callbackWhenFetching = background;
	
	[NSThread detachNewThreadSelector:@selector(fetchData:) toTarget:self withObject:nil];
	
}

#pragma mark View Methods

- (id)init {
	if ((self = [super init]))
	{
		self.title = @"Network";
	}
	return self;
}

- (int)adjustSectionNumber:(int)section
{
	if (self.networkErrorFromQuery==nil)
	{
		return section+1;
	}
	return section;
}

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/



- (void)viewDidLoad {
    [super viewDidLoad];

 
	 // add our custom add button as the nav bar's custom right view
	 UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
									   initWithTitle:NSLocalizedString(@"Refresh", @"")
									   style:UIBarButtonItemStyleBordered
									   target:self
									   action:@selector(refreshAction:)];
	 self.navigationItem.rightBarButtonItem = refreshButton;
	 [refreshButton release];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/



- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

#pragma mark Helper functions

- (void)refreshAction:(id)sender
{
	self.backgroundRefresh		= YES;
	self.networkErrorFromQuery	= nil;
	[self fetchNetworkStatusInBackground:self.backgroundTask];
}

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

- (UITableViewCell *)networkStatusCell
{
	static NSString *CellIdentifier = @"networkstatus";
	UITableViewCell *cell = [self.table dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
	
	// Set up the cell...
	cell.textLabel.adjustsFontSizeToFitWidth = YES;
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.textLabel.font = [self getBasicFont];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	return cell;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (self.networkErrorFromQuery==nil)
	{
		return kNoErrorSections;
	}
    return kSections;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
	
    
	
	switch ([self adjustSectionNumber:indexPath.section])
	{
		case kSectionInternet:
			cell = [self networkStatusCell];
			
			if (!self.internetConnectionStatus)
			{
				cell.textLabel.text = @"Not able to access the Internet";
				cell.textLabel.textColor = [UIColor redColor];
				cell.imageView.image = [TableViewWithToolbar alwaysGetIcon:kIconNetworkBad];
				cell.textLabel.font = [self getBasicFont];
			}
			else
			{
				cell.textLabel.text = @"Internet access is available";
				cell.imageView.image = [TableViewWithToolbar alwaysGetIcon:kIconNetworkOk];
				cell.textLabel.textColor = [UIColor blackColor];
				cell.textLabel.font = [self getBasicFont];
			}
			break;
		case kSectionTriMet:
			cell = [self networkStatusCell];
			
			if (!self.trimetQueryStatus)
			{
				cell.textLabel.text = @"Not able to access TriMet arrival servers";
				cell.textLabel.textColor = [UIColor redColor];
				cell.imageView.image = [TableViewWithToolbar alwaysGetIcon:kIconNetworkBad];
				cell.textLabel.font = [self getBasicFont];
			}
			else
			{
				cell.textLabel.text = @"TriMet arrival servers are available";
				cell.textLabel.textColor = [UIColor blackColor];
				cell.imageView.image = [TableViewWithToolbar alwaysGetIcon:kIconNetworkOk];
				cell.textLabel.font = [self getBasicFont];
			}
			break;
		case kSectionTriMetTrip:
			cell = [self networkStatusCell];
			
			if (!self.trimetTripStatus)
			{
				cell.textLabel.text = @"Not able to access TriMet trip servers";
				cell.textLabel.textColor = [UIColor redColor];
				cell.imageView.image = [TableViewWithToolbar alwaysGetIcon:kIconNetworkBad];
				cell.textLabel.font = [self getBasicFont];
			}
			else
			{
				cell.textLabel.text = @"TriMet trip servers are available";
				cell.textLabel.textColor = [UIColor blackColor];
				cell.imageView.image = [TableViewWithToolbar alwaysGetIcon:kIconNetworkOk];
				cell.textLabel.font = [self getBasicFont];
			}
			break;	
		case kSectionNextBus:
			cell = [self networkStatusCell];
			
			if (!self.nextbusQueryStatus)
			{
				cell.textLabel.text = @"Not able to access NextBus (Streetcar) servers";
				cell.textLabel.textColor = [UIColor redColor];
				cell.imageView.image = [TableViewWithToolbar alwaysGetIcon:kIconNetworkBad];
				cell.textLabel.font = [self getBasicFont];
			}
			else
			{
				cell.textLabel.text = @"NextBus (Streetcar) servers are available";
				cell.textLabel.textColor = [UIColor blackColor];
				cell.imageView.image = [TableViewWithToolbar alwaysGetIcon:kIconNetworkOk];
				cell.textLabel.font = [self getBasicFont];
			}
			break;
		case kSectionReverseGeoCode:
			cell = [self networkStatusCell];
			
			if (self.reverseGeoCodeService == nil)
			{
				cell.textLabel.text = @"No Reverse GeoCoding service has been selected.";
				cell.textLabel.textColor = [UIColor grayColor];
				cell.imageView.image = [TableViewWithToolbar alwaysGetIcon:kIconNetworkOk];
				cell.textLabel.font = [self getBasicFont];
			}
			else  if (!self.reverseGeoCodeStatus)
			{
				cell.textLabel.text = [NSString stringWithFormat:@"Not able to access %@ servers", self.reverseGeoCodeService];
				cell.textLabel.textColor = [UIColor redColor];
				cell.imageView.image = [TableViewWithToolbar alwaysGetIcon:kIconNetworkBad];
				cell.textLabel.font = [self getBasicFont];
			}
			else
			{
				cell.textLabel.text = [NSString stringWithFormat:@"%@ servers are available", self.reverseGeoCodeService];
				cell.textLabel.textColor = [UIColor blackColor];
				cell.imageView.image = [TableViewWithToolbar alwaysGetIcon:kIconNetworkOk];
				cell.textLabel.font = [self getBasicFont];
			}
			break;
		case kSectionDiagnose:
		{
			static NSString *diagsId = @"diags";
			CellLabel *diagCell;
			diagCell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:diagsId];
			if (diagCell == nil) {
				diagCell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:diagsId] autorelease];
				diagCell.view = [self create_UITextView:nil font:[self getParagraphFont]];
				diagCell.view.font =  [self getParagraphFont];
				diagCell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
			
			diagCell.view.text = self.diagnosticText;
			cell = diagCell;
			break;
		}
		case KSectionMaybeError:
		{
			static NSString *diagsId = @"error";
			CellLabel *diagCell;
			diagCell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:diagsId];
			if (diagCell == nil) {
				diagCell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:diagsId] autorelease];
				diagCell.view = [self create_UITextView:nil font:[self getParagraphFont]];
				diagCell.view.font =  [self getParagraphFont];
				diagCell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
			
			diagCell.view.text = self.networkErrorFromQuery;
			cell = diagCell;
			break;
		}
		break;
	}
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch ([self adjustSectionNumber:indexPath.section]) {
		case KSectionMaybeError:
			return [self getTextHeight:self.networkErrorFromQuery font:[self getParagraphFont]];
		case kSectionDiagnose:
			return [self getTextHeight:self.diagnosticText font:[self getParagraphFont]];
		default:
			return [self basicRowHeight];
	}
	return [self basicRowHeight];
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self adjustSectionNumber:indexPath.section] == kSectionDiagnose)
	{
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.trimet.org"]];
	}
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if ([self adjustSectionNumber:section] == KSectionMaybeError)
	{
		return @"There was a network problem:";
	}
	return nil;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/



@end

