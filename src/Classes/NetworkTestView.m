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
#import "TaskState.h"
#import "Icons.h"
#import "UIApplication+Compat.h"
#import "RunParallelBlocks.h"
#import "WebViewController.h"

@interface NetworkTestView ()

@property (nonatomic, copy)   NSString *diagnosticText;
@property (nonatomic, copy)   NSString *reverseGeoCodeService;

@property bool trimetQueryStatus;
@property bool nextbusQueryStatus;
@property bool internetConnectionStatus;
@property bool reverseGeoCodeStatus;
@property bool trimetTripStatus;

@end

@implementation NetworkTestView

enum SECTION_ROW {
    kSectionHtmlError,
    kSectionInternet,
    kSectionTriMet,
    kSectionTriMetTrip,
    kSectionNextBus,
    kSectionReverseGeoCode,
    kSectionDiagnose,
};


#pragma mark Data fetchers

- (void)subTaskCheckDepartures:(TaskState *)taskState {
    [taskState taskSubtext:NSLocalizedString(@"checking departure server", @"progress message")];
    XMLDetours *detours = [XMLDetours xmlWithOneTimeDelegate:taskState];
    detours.giveUp = 7;
    [detours getDetours];
    
    self.trimetQueryStatus = detours.gotData;
    
    [taskState incrementItemsDoneAndDisplay];
}

- (void)subTaskCheckTripServer:(TaskState *)taskState {
    [taskState taskSubtext:NSLocalizedString(@"checking trip server", @"progress message")];
    
    XMLTrips *trips = [XMLTrips xmlWithOneTimeDelegate:taskState];
    trips.userRequest.dateAndTime = nil;
    trips.userRequest.arrivalTime = NO;
    trips.userRequest.timeChoice  = TripDepartAfterTime;
    trips.userRequest.toPoint.locationDesc   = @"8336";// Yamhil District
    trips.userRequest.fromPoint.locationDesc = @"8334"; // Pioneer Square South
    trips.giveUp = 7;
    [trips fetchItineraries:nil];
    
    self.trimetTripStatus = trips.gotData;
    
    [taskState incrementItemsDoneAndDisplay];
}

- (void)subTaskCheckNextBus:(TaskState *)taskState {
    [taskState taskSubtext:NSLocalizedString(@"checking NextBus server", @"progress message")];
    
    XMLStreetcarLocations *locations = [XMLStreetcarLocations sharedInstanceForRoute:[TriMetInfo streetcarRoutes].anyObject];
    locations.giveUp = 7;
    locations.oneTimeDelegate = taskState;
    [locations getLocations];
    
    self.nextbusQueryStatus = locations.gotData;
    
    [taskState incrementItemsDoneAndDisplay];
}

- (void)subTaskCheckGeoLocator:(TaskState *)taskState {
    if ([ReverseGeoLocator supported]) {
        [taskState taskSubtext:NSLocalizedString(@"checking geocoder server", @"progress message")];
        
        ReverseGeoLocator *provider = [[ReverseGeoLocator alloc] init];
        // Pioneer Square!
        
        CLLocation *loc = [CLLocation withLat:45.519077 lng:-122.678602];
        [provider fetchAddress:loc];
        self.reverseGeoCodeStatus = (provider.error == nil);
        self.reverseGeoCodeService = @"Apple Geocoder";
    } else {
        self.reverseGeoCodeService = nil;
        self.reverseGeoCodeStatus = YES;
    }
    
    [taskState incrementItemsDoneAndDisplay];
}

- (void)subTaskCheckConnectivity:(TaskState *)taskState {
    [taskState taskSubtext:NSLocalizedString(@"checking connection", @"progress message")];
    self.internetConnectionStatus = [TriMetXML isDataSourceAvailable:YES];
    
    [taskState incrementItemsDoneAndDisplay];
}

- (void)fetchNetworkStatusAsync:(id<TaskController>)taskController backgroundRefresh:(bool)backgroundRefresh {
    [taskController taskRunAsync:^(TaskState *taskState) {
        self.backgroundRefresh = backgroundRefresh;
        
        [taskState taskStartWithTotal:5 title:NSLocalizedString(@"checking network", @"progress message")];
        
        RunParallelBlocks *parallelBlocks = [RunParallelBlocks instance];
        
        [parallelBlocks startBlock:^{
            [self subTaskCheckConnectivity:taskState];
        }];
        
        [parallelBlocks startBlock:^{
            [self subTaskCheckDepartures:taskState];
        }];
        
        [parallelBlocks startBlock:^{
            [self subTaskCheckTripServer:taskState];
        }];
        
        [parallelBlocks startBlock:^{
            [self subTaskCheckNextBus:taskState];
        }];
        
        [parallelBlocks startBlock:^{
            [self subTaskCheckGeoLocator:taskState];
        }];
        
        [parallelBlocks waitForBlocks];
        
        NSMutableString *diagnosticString = [NSMutableString string];
        
        if (!self.internetConnectionStatus) {
            [diagnosticString appendString:NSLocalizedString(@"The Internet is not available. Check you are not in Airplane mode, and not in the Robertson Tunnel.\n\nIf your device is capable, you could also try switching between WiFi, Edge and 3G.\n\nTouch here to start Safari to check your connection. ", @"error message")];
        } else if (!self.trimetQueryStatus || !self.nextbusQueryStatus || !self.trimetTripStatus) {
            [diagnosticString appendString:NSLocalizedString(@"The Internet is available, but PDX Bus is not able to contact TriMet's or NextBus's servers. Touch here to check if www.trimet.org is working.", @"error message")];
        } else {
            [diagnosticString appendString:NSLocalizedString(@"The main network services are working at this time. If you are having problems, touch here to load www.trimet.org, then restart PDX Bus.", @"error message")];
        }
        
        if (self.internetConnectionStatus && !self.reverseGeoCodeStatus && self.reverseGeoCodeService != nil) {
            [diagnosticString appendFormat:NSLocalizedString(@"\n\nApple's GeoCoding service is not responding.", @"error message")];
        }
        
        self.diagnosticText = diagnosticString;
        
        [self updateSections];
        
        [self updateRefreshDate:nil];
        return (UIViewController *)self;
    }];
}

- (void)updateSections {
    
    [self clearSectionMaps];
    
    if (self.networkErrorFromQuery != nil) {
        [self addSectionTypeWithRow:kSectionHtmlError];
    }
    
    [self addSectionTypeWithRow:kSectionInternet];
    
    [self addSectionTypeWithRow:kSectionTriMet];
    
    [self addSectionTypeWithRow:kSectionTriMetTrip];
    
    [self addSectionTypeWithRow:kSectionNextBus];
    
    [self addSectionTypeWithRow:kSectionReverseGeoCode];
    
    [self addSectionTypeWithRow:kSectionDiagnose];
}

#pragma mark View Methods

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Network", @"page title");
        self.refreshFlags = kRefreshNoTimer;
    }
    
    return self;
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

- (void)refreshAction:(id)sender {
    self.backgroundRefresh = YES;
    self.networkErrorFromQuery = nil;
    [self fetchNetworkStatusAsync:self.backgroundTask backgroundRefresh:YES];
}

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

- (UITableViewCell *)networkStatusCell {
    UITableViewCell *cell = [self tableView:self.table cellWithReuseIdentifier:MakeCellId(networkStatusCell)];
    
    // Set up the cell...
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.font = self.basicFont;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark Table view methods

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    switch ([self rowType:indexPath]) {
        default:
        case kSectionInternet:
            cell = [self networkStatusCell];
            
            if (!self.internetConnectionStatus) {
                cell.textLabel.text = NSLocalizedString(@"Not able to access the Internet", @"network error");
                cell.textLabel.textColor = [UIColor redColor];
                cell.imageView.image = [Icons getIcon:kIconNetworkBad];
                cell.textLabel.font = self.basicFont;
            } else {
                cell.textLabel.text = NSLocalizedString(@"Internet access is available", @"network error");
                cell.imageView.image = [Icons getIcon:kIconNetworkOk];
                cell.textLabel.textColor = [UIColor modeAwareText];
                cell.textLabel.font = self.basicFont;
            }
            
            break;
            
        case kSectionTriMet:
            cell = [self networkStatusCell];
            
            if (!self.trimetQueryStatus) {
                cell.textLabel.text = NSLocalizedString(@"Not able to access TriMet departure servers", @"network error");
                cell.textLabel.textColor = [UIColor redColor];
                cell.imageView.image = [Icons getIcon:kIconNetworkBad];
                cell.textLabel.font = self.basicFont;
            } else {
                cell.textLabel.text = NSLocalizedString(@"TriMet departure servers are available", @"network errror");
                cell.textLabel.textColor = [UIColor modeAwareText];
                cell.imageView.image = [Icons getIcon:kIconNetworkOk];
                cell.textLabel.font = self.basicFont;
            }
            
            break;
            
        case kSectionTriMetTrip:
            cell = [self networkStatusCell];
            
            if (!self.trimetTripStatus) {
                cell.textLabel.text = NSLocalizedString(@"Not able to access TriMet trip servers", @"network errror");
                cell.textLabel.textColor = [UIColor redColor];
                cell.imageView.image = [Icons getIcon:kIconNetworkBad];
                cell.textLabel.font = self.basicFont;
            } else {
                cell.textLabel.text = NSLocalizedString(@"TriMet trip servers are available", @"network errror");
                
                cell.textLabel.textColor = [UIColor modeAwareText];
                cell.imageView.image = [Icons getIcon:kIconNetworkOk];
                cell.textLabel.font = self.basicFont;
            }
            
            break;
            
        case kSectionNextBus:
            cell = [self networkStatusCell];
            
            if (!self.nextbusQueryStatus) {
                cell.textLabel.text = NSLocalizedString(@"Not able to access Umo IQ (Streetcar) servers", @"network errror");
                cell.textLabel.textColor = [UIColor redColor];
                cell.imageView.image = [Icons getIcon:kIconNetworkBad];
                cell.textLabel.font = self.basicFont;
            } else {
                cell.textLabel.text = NSLocalizedString(@"Umo IQ (Streetcar) servers are available", @"network errror");
                cell.textLabel.textColor = [UIColor modeAwareText];
                cell.imageView.image = [Icons getIcon:kIconNetworkOk];
                cell.textLabel.font = self.basicFont;
            }
            
            break;
            
        case kSectionReverseGeoCode:
            cell = [self networkStatusCell];
            
            if (self.reverseGeoCodeService == nil) {
                cell.textLabel.text = NSLocalizedString(@"No Reverse GeoCoding service is not supported.", @"network errror");
                cell.textLabel.textColor = [UIColor modeAwareText];
                cell.imageView.image = [Icons getIcon:kIconNetworkOk];
                cell.textLabel.font = self.basicFont;
            } else if (!self.reverseGeoCodeStatus) {
                cell.textLabel.text = NSLocalizedString(@"Not able to access Apple's Geocoding servers.", @"network errror");
                cell.textLabel.textColor = [UIColor redColor];
                cell.imageView.image = [Icons getIcon:kIconNetworkBad];
                cell.textLabel.font = self.basicFont;
            } else {
                cell.textLabel.text = NSLocalizedString(@"Apple's Geocoding servers are available.", @"network errror");
                cell.textLabel.textColor = [UIColor modeAwareText];
                cell.imageView.image = [Icons getIcon:kIconNetworkOk];
                cell.textLabel.font = self.basicFont;
            }
            
            break;
            
        case kSectionDiagnose: {
            cell = [self tableView:tableView multiLineCellWithReuseIdentifier:@"diags" font:self.smallFont];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = self.diagnosticText;
            break;
        }
            
        case kSectionHtmlError: {
            cell = [self tableView:tableView multiLineCellWithReuseIdentifier:@"error" font:self.smallFont];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = self.networkErrorFromQuery;
            break;
        }
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self rowType:indexPath]) {
        case kSectionHtmlError:
        case kSectionDiagnose:
            return UITableViewAutomaticDimension;
            
        default:
            return [self basicRowHeight];
    }
    return [self basicRowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self rowType:indexPath] == kSectionDiagnose) {
        [WebViewController openNamedURL:@"TriMet"];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self sectionType:section] == kSectionHtmlError) {
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
