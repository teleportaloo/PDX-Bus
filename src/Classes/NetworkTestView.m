//
//  NetworkTestView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 8/25/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "NetworkTestView.h"
#import "XMLDetours.h"
#import "XMLTrips.h"
#import "XMLStreetcarLocations.h"
#import "ReverseGeoLocator.h"
#import "CLLocation+Helper.h"
#import "NSString+Helper.h"

@implementation NetworkTestView

#define KSectionMaybeError        0
#define kSectionInternet          1
#define kSectionTriMet            2
#define kSectionTriMetTrip        3
#define kSectionNextBus           4
#define kSectionReverseGeoCode    5
#define kSectionDiagnose          6

#define kSections                 7
#define kNoErrorSections          6


#pragma mark Data fetchers

- (void)fetchNetworkStatusAsync:(id<BackgroundTaskController>)task backgroundRefresh:(bool)backgroundRefresh
{
    [task taskRunAsync:^{
        self.backgroundRefresh = backgroundRefresh;
        
        [task taskStartWithItems:5 title:@"checking network"];
        
        self.internetConnectionStatus = [TriMetXML isDataSourceAvailable:YES];
        
        [task taskItemsDone:1];
        
        XMLDetours *detours = [XMLDetours xml];
        
        detours.giveUp = 7;
        
        detours.oneTimeDelegate = task;
        [detours getDetours];
        
        self.trimetQueryStatus = detours.gotData;
        
        
        [task taskItemsDone:2];
        
        XMLTrips *trips = [XMLTrips xml];
        trips.userRequest.dateAndTime = nil;
        trips.userRequest.arrivalTime = NO;
        trips.userRequest.timeChoice  = TripDepartAfterTime;
        trips.userRequest.toPoint.locationDesc   = @"8336"; // Yamhil District
        trips.userRequest.fromPoint.locationDesc = @"8334"; // Pioneer Square South
        trips.giveUp = 7;
        
        trips.oneTimeDelegate = task;
        [trips fetchItineraries:nil];
        
        self.trimetTripStatus = trips.gotData;
        
        [task taskItemsDone:3];
        
        XMLStreetcarLocations *locations = [XMLStreetcarLocations sharedInstanceForRoute:[TriMetInfo streetcarRoutes].anyObject];
        
        locations.giveUp = 7;
        locations.oneTimeDelegate = task;
        [locations getLocations];
    
        self.nextbusQueryStatus = locations.gotData;
        
        [task taskItemsDone:4];
        
        if ([ReverseGeoLocator supported])
        {
            
            ReverseGeoLocator *provider = [[ReverseGeoLocator alloc] init];
            // Pioneer Square!
            
            CLLocation *loc = [CLLocation withLat:45.519077 lng:-122.678602];
            [provider fetchAddress:loc];
            self.reverseGeoCodeStatus = (provider.error == nil);
            self.reverseGeoCodeService = @"Apple Geocoder";
        }
        else {
            self.reverseGeoCodeService = nil;
            self.reverseGeoCodeStatus = YES;
        }
        
        [task taskItemsDone:5];
        
        NSMutableString *diagnosticString = [NSMutableString string];
        
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
        
        if (self.internetConnectionStatus && !self.reverseGeoCodeStatus && self.reverseGeoCodeService!=nil)
        {
            
            [diagnosticString appendFormat:@"\n\nApple's GeoCoding service is not responding."];
        }
        
        self.diagnosticText = diagnosticString;
        
        [self updateRefreshDate:nil];
        return (UIViewController*)self;
    }];
}

#pragma mark View Methods

- (instancetype)init {
    if ((self = [super init]))
    {
        self.title = NSLocalizedString(@"Network", @"page title");
        self.refreshFlags =  kRefreshNoTimer;
    }
    return self;
}

- (NSInteger)adjustSectionNumber:(NSInteger)section
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

#pragma mark Helper functions

- (void)refreshAction:(id)sender
{
    self.backgroundRefresh        = YES;
    self.networkErrorFromQuery    = nil;
    [self fetchNetworkStatusAsync:self.backgroundTask backgroundRefresh:YES];
}

- (UITableViewStyle) style
{
    return UITableViewStyleGrouped;
}

- (UITableViewCell *)networkStatusCell
{
    UITableViewCell *cell =  [self tableView:self.table cellWithReuseIdentifier:MakeCellId(networkStatusCell)];
    
    // Set up the cell...
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.font = self.basicFont;
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
        default:
        case kSectionInternet:
            cell = [self networkStatusCell];
            
            if (!self.internetConnectionStatus)
            {
                cell.textLabel.text = NSLocalizedString(@"Not able to access the Internet", @"network error");
                cell.textLabel.textColor = [UIColor redColor];
                cell.imageView.image = [TableViewWithToolbar getIcon:kIconNetworkBad];
                cell.textLabel.font = self.basicFont;
            }
            else
            {
                cell.textLabel.text = NSLocalizedString(@"Internet access is available", @"network error");
                cell.imageView.image = [TableViewWithToolbar getIcon:kIconNetworkOk];
                cell.textLabel.textColor = [UIColor modeAwareText];
                cell.textLabel.font = self.basicFont;
            }
            break;
        case kSectionTriMet:
            cell = [self networkStatusCell];
            
            if (!self.trimetQueryStatus)
            {
                cell.textLabel.text = NSLocalizedString(@"Not able to access TriMet arrival servers", @"network error");
                cell.textLabel.textColor = [UIColor redColor];
                cell.imageView.image = [TableViewWithToolbar getIcon:kIconNetworkBad];
                cell.textLabel.font = self.basicFont;
            }
            else
            {
                cell.textLabel.text = NSLocalizedString(@"TriMet arrival servers are available", @"network errror");
                cell.textLabel.textColor = [UIColor modeAwareText];
                cell.imageView.image = [TableViewWithToolbar getIcon:kIconNetworkOk];
                cell.textLabel.font = self.basicFont;
            }
            break;
        case kSectionTriMetTrip:
            cell = [self networkStatusCell];
            
            if (!self.trimetTripStatus)
            {
                cell.textLabel.text = NSLocalizedString(@"Not able to access TriMet trip servers", @"network errror");
                cell.textLabel.textColor = [UIColor redColor];
                cell.imageView.image = [TableViewWithToolbar getIcon:kIconNetworkBad];
                cell.textLabel.font = self.basicFont;
            }
            else
            {
                cell.textLabel.text = NSLocalizedString(@"TriMet trip servers are available", @"network errror");

                cell.textLabel.textColor = [UIColor modeAwareText];
                cell.imageView.image = [TableViewWithToolbar getIcon:kIconNetworkOk];
                cell.textLabel.font = self.basicFont;
            }
            break;
        case kSectionNextBus:
            cell = [self networkStatusCell];
            
            if (!self.nextbusQueryStatus)
            {
                cell.textLabel.text = NSLocalizedString(@"Not able to access NextBus (Streetcar) servers", @"network errror");
                cell.textLabel.textColor = [UIColor redColor];
                cell.imageView.image = [TableViewWithToolbar getIcon:kIconNetworkBad];
                cell.textLabel.font = self.basicFont;
            }
            else
            {
                cell.textLabel.text = NSLocalizedString(@"NextBus (Streetcar) servers are available", @"network errror");
                cell.textLabel.textColor = [UIColor modeAwareText];
                cell.imageView.image = [TableViewWithToolbar getIcon:kIconNetworkOk];
                cell.textLabel.font = self.basicFont;
            }
            break;
        case kSectionReverseGeoCode:
            cell = [self networkStatusCell];
            
            if (self.reverseGeoCodeService == nil)
            {
                cell.textLabel.text = NSLocalizedString(@"No Reverse GeoCoding service is not supported.", @"network errror");
                cell.textLabel.textColor = [UIColor modeAwareText];
                cell.imageView.image = [TableViewWithToolbar getIcon:kIconNetworkOk];
                cell.textLabel.font = self.basicFont;
            }
            else  if (!self.reverseGeoCodeStatus)
            {
                cell.textLabel.text = NSLocalizedString(@"Not able to access Apple's Geocoding servers.", @"network errror");
                cell.textLabel.textColor = [UIColor redColor];
                cell.imageView.image = [TableViewWithToolbar getIcon:kIconNetworkBad];
                cell.textLabel.font = self.basicFont;
            }
            else
            {
                cell.textLabel.text = NSLocalizedString(@"Apple's Geocoding servers are available.", @"network errror");
                cell.textLabel.textColor = [UIColor modeAwareText];
                cell.imageView.image = [TableViewWithToolbar getIcon:kIconNetworkOk];
                cell.textLabel.font = self.basicFont;
            }
            break;
        case kSectionDiagnose:
        {
            cell = [self tableView:tableView multiLineCellWithReuseIdentifier:@"diags" font:self.paragraphFont];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = self.diagnosticText;
            break;
        }
        case KSectionMaybeError:
        {
            cell = [self tableView:tableView multiLineCellWithReuseIdentifier:@"error" font:self.paragraphFont];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = self.networkErrorFromQuery;
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
        case kSectionDiagnose:
            return UITableViewAutomaticDimension;
        default:
            return [self basicRowHeight];
    }
    return [self basicRowHeight];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self adjustSectionNumber:indexPath.section] == kSectionDiagnose)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.trimet.org"]];
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self adjustSectionNumber:section] == KSectionMaybeError)
    {
        return NSLocalizedString(@"There was a network problem:", @"section title");
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

