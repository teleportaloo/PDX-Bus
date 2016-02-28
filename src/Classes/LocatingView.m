//
//  LocatingView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/10/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "LocatingView.h"
#import "RootViewController.h"
#import "DebugLogging.h"
#import "FormatDistance.h"
#import <MapKit/MapKit.h>
#import "SimpleAnnotation.h"
#import "BearingAnnotationView.h"
#import "LocationAuthorization.h"

#define kLocatingRowHeight		60.0
#define MAX_AGE					-30.0
#define TEXT_TAG 1
#define PROGRESS_TAG 2

#define kLocatingAccuracy	0
#define kLocatingStop		1
#define kLocatingMap        2

#define kSectionButtons     0
#define kSectionText        1


@implementation LocatingView

@synthesize progressInd			= _progressInd;
@synthesize locationManager		= _locationManager;
@synthesize lastLocation		= _lastLocation;
@synthesize progressCell		= _progressCell;
@synthesize timeStamp			= _timeStamp;
@synthesize failed              = _failed;
@synthesize accuracy            = _accuracy;
@synthesize delegate            = _delegate;
@synthesize annotation          = _anotation;

- (void)dealloc {
    if (self.locationManager)
    {
        [self.locationManager stopUpdatingLocation];
        self.locationManager.delegate	= nil;
    }
	self.locationManager			= nil;
	self.progressInd				= nil;
	self.lastLocation				= nil;
	self.progressCell				= nil;
	self.timeStamp					= nil;
    self.delegate                   = nil;
    self.annotation                 = nil;
	
    [super dealloc];
}

- (id) init
{
	if ((self = [super init]))
	{
		self.locationManager = [[[CLLocationManager alloc] init] autorelease];
		self.locationManager.delegate = self; // Tells the location manager to send updates to this object
        
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        {
            [self.locationManager requestAlwaysAuthorization];
        }

		_failed = false;
        _waitingForLocation = YES;
        self.title = @"Locator";
	}
	return self;
}

#pragma mark Check the last location

- (bool)checkLocation
{
	
    DEBUG_LOGF([self.timeStamp timeIntervalSinceNow] );
    // This line may be confusing - MAX_AGE is negative, so something older is even more negative
	if (self.timeStamp == nil || [self.timeStamp timeIntervalSinceNow] < MAX_AGE)
	{
		return false;
	}
	
	if (self.lastLocation.horizontalAccuracy > _accuracy)
	{
        if (_waitingForLocation)
        {
            [self reloadData];
        }
        
		return false;
	}
    
	[self stopLocating];
    [self reloadData];
    
	
#ifdef ORIGINAL_IPHONE
    NSDate *soon = [[NSDate date] addTimeInterval:0.1];
#else
    NSDate *soon = [[NSDate date] dateByAddingTimeInterval:0.2];
#endif
	NSTimer *timer = [[[NSTimer alloc] initWithFireDate:soon interval:0.1 target:self selector:@selector(delayedCompletion:) userInfo:nil repeats:NO] autorelease];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	
	return true;
}

#pragma mark ViewControllerBase methods

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}


#pragma mark View methods

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)startLocating
{
    [self.locationManager startUpdatingLocation];
	[self.progressInd startAnimating];
	
	_waitingForLocation = true;
    _failed = false;
    
    self.navigationItem.rightBarButtonItem = nil;
    
}

- (void)stopLocating
{
    
    _waitingForLocation = NO;
    [self.progressInd stopAnimating];

    [self.locationManager stopUpdatingLocation];

    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
									  initWithTitle:NSLocalizedString(@"Refresh", @"")
									  style:UIBarButtonItemStyleBordered
									  target:self
									  action:@selector(refreshAction:)];
	self.navigationItem.rightBarButtonItem = refreshButton;
	[refreshButton release];

}


- (void)refreshAction:(id)sender
{
	[self startLocating];
    [self reloadData];
}

- (void)loadView
{
    [self clearSectionMaps];
    [self addSectionType:kSectionButtons];
    [self addRowType:kLocatingAccuracy];
    [self addRowType:kLocatingMap];
    
    [self addSectionType:kSectionText];
    [self addRowType:kLocatingStop];
    
    
    [super loadView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (_waitingForLocation)
    {
        [self startLocating];
    }
}


#pragma mark Subclass methods

- (void)reinit
{
	
}

- (void)located
{
	[self.delegate locatingViewFinished:self];
}

#pragma mark UI helper functions

- (int)LocationTextTag
{
	return TEXT_TAG;
}

- (UITableViewCell *)accuracyCellWithReuseIdentifier:(NSString *)identifier {
	
	/*
	 Create an instance of UITableViewCell and add tagged subviews for the name, local time, and quarter image of the time zone.
	 */
	CGRect rect;
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
	
#define LEFT_COLUMN_OFFSET 20.0
#define LEFT_COLUMN_WIDTH 30.0
#define LEFT_COLUMN_HEIGHT 35.0
	
#define MAIN_FONT_SIZE 16.0
#define LABEL_HEIGHT (kLocatingRowHeight - 10.0)
#define LABEL_COLUMN_OFFSET (LEFT_COLUMN_OFFSET + LEFT_COLUMN_WIDTH + 5.0)
#define LABEL_COLUMN_WIDTH  (260.0 - LEFT_COLUMN_WIDTH)
	
	CGRect frame = CGRectMake(LEFT_COLUMN_OFFSET, (kLocatingRowHeight - LEFT_COLUMN_HEIGHT) / 2.0, LEFT_COLUMN_WIDTH, LEFT_COLUMN_HEIGHT);
	self.progressInd = [[[UIActivityIndicatorView alloc] initWithFrame:frame] autorelease];
	self.progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
	self.progressInd.hidesWhenStopped = YES;
	[self.progressInd sizeToFit];
	self.progressInd.autoresizingMask =  (UIViewAutoresizingFlexibleTopMargin |
                                          UIViewAutoresizingFlexibleBottomMargin);
    self.progressInd.tag = PROGRESS_TAG;
	[cell.contentView addSubview:self.progressInd];
	
	
	/*
	 Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
	 */
	UILabel *label;
	
	rect = CGRectMake(LABEL_COLUMN_OFFSET, (kLocatingRowHeight - LABEL_HEIGHT) / 2.0, LABEL_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = TEXT_TAG;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	label.adjustsFontSizeToFitWidth = NO;
	label.numberOfLines = 0;
	label.lineBreakMode = NSLineBreakByWordWrapping;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	label.textColor  = [UIColor blackColor];
	label.autoresizingMask =  (UIViewAutoresizingFlexibleWidth);
	label.backgroundColor = [UIColor clearColor];
	[label release];
	
	[cell.contentView layoutSubviews];
	
	self.progressCell = cell;
	
	return cell;
}

- (void)delayedCompletion:(NSTimer*)theTimer
{
	[self located];
}

-(void)updateMap
{
    if (self.lastLocation != nil)
    {
        self.mapView.hidden = NO;
        if (self.annotation != nil)
        {
            [self.mapView removeAnnotation:self.annotation];
        }
    
    
        SimpleAnnotation *annotLoc = [[[SimpleAnnotation alloc] init] autorelease];
    
        annotLoc.pinTitle = @"Here!";
        annotLoc.pinColor = MKPinAnnotationColorRed;
        [annotLoc setCoord:self.lastLocation.coordinate];
    
        [self.mapView addAnnotation:annotLoc];
    
        self.annotation = annotLoc;
    
        MKMapPoint annotationPoint = MKMapPointForCoordinate(self.lastLocation.coordinate);
    
        MKMapRect busRect = MakeMapRectWithPointAtCenter(annotationPoint.x, annotationPoint.y, 300, 2000);
    
        UIEdgeInsets insets = {
            30,
            10,
            10,
            20
        };
    
        [self.mapView setVisibleMapRect:[self.mapView mapRectThatFits:busRect edgePadding:insets] animated:YES];
    }
    else
    {
        self.mapView.hidden = YES;
    }

}


#pragma mark Location Manager callbacks

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
	
	
	if ([newLocation.timestamp timeIntervalSinceNow] < MAX_AGE)
	{
		// too old!
		return;
	}
	
	self.lastLocation = newLocation;
	self.timeStamp    = newLocation.timestamp;
	
	if (!_waitingForLocation)
	{
		return;
	}
    
   	[self updateMap];
	[self checkLocation];
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	DEBUG_LOG(@"location error %@\n", [error localizedDescription]);
    
    switch (error.code)
    {
        default:
        case kCLErrorLocationUnknown:
            break;
        case kCLErrorDenied:
            
            [self reloadData];
            [self stopLocating];
            _failed = YES;
            
            [self failedToLocate];
            break;
    }
}

- (void) failedToLocate
{
	[self.delegate locatingViewFinished:self];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self rowsInSection:section];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([self rowType:indexPath])
    {
        case kLocatingMap:
            return [self mapCellHeight];
        default:
            break;
    }
	return kLocatingRowHeight;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    
    if ([cell.reuseIdentifier isEqualToString:MakeCellId(kLocatingStop)])
	{
        if (_waitingForLocation)
        {
            cell.backgroundColor = [UIColor redColor];
        }
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {


    switch ([self rowType:indexPath])
    {
        case kLocatingAccuracy:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kLocatingAccuracy)];
            if (cell == nil) {
                cell = [self accuracyCellWithReuseIdentifier:MakeCellId(kLocatingAccuracy)];
            }
            
            UILabel* text = (UILabel *)[cell.contentView viewWithTag:[self LocationTextTag]];
            
            self.progressInd = (UIActivityIndicatorView*)[cell.contentView viewWithTag:PROGRESS_TAG];
            
            if (_waitingForLocation)
            {
                [self.progressInd startAnimating];
            }
            else
            {
                [self.progressInd stopAnimating];
            }
            
            if (self.lastLocation != nil)
            {
                text.text = [NSString stringWithFormat:@"Accuracy acquired:\n+/- %@",
                             [FormatDistance formatMetres:self.lastLocation.horizontalAccuracy]];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                [cell setAccessibilityHint:@"Double-tap for arrivals"];
            }
            else if (!_failed)
            {
                text.text = @"Locating...";
                cell.accessoryType = UITableViewCellAccessoryNone;
                [cell setAccessibilityHint:nil];
            }
            else if (_failed)
            {
                text.text = @"Locating failed.";
                cell.accessoryType = UITableViewCellAccessoryNone;
                [cell setAccessibilityHint:nil];
            }
            
            [self updateAccessibility:cell indexPath:indexPath text:text.text alwaysSaySection:YES];
            return cell;
        }
        case kLocatingStop:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kLocatingStop)];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MakeCellId(kLocatingStop)] autorelease];
            }
            if (_waitingForLocation)
            {
                cell.textLabel.text = @"Cancel";
            }
            else
            {
                cell.textLabel.text =@"Done";
            }
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.accessoryType = UITableViewCellAccessoryNone;
            // cell.imageView.image = [self getActionIcon:kIconCancel];
            cell.textLabel.font = [self getBasicFont];
            
            [self updateAccessibility:cell indexPath:indexPath text:cell.textLabel.text alwaysSaySection:YES];
            return cell;
        }
        case kLocatingMap:
        {
            UITableViewCell *cell = [self  getMapCell:MakeCellId(kLocatingMap) withUserLocation:YES];
            
            self.mapView.showsUserLocation = NO;
            // self.mapView.userTrackingMode = MKUserTrackingModeFollow;
            [self updateMap];
            
            return cell;
        }
    }
    
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch ([self sectionType:section])
    {
        case kSectionButtons:
            return @"Location information:";
            
        case kSectionText:
        {
            if (_waitingForLocation)
            {
                return [NSString stringWithFormat:@"Acquiring location. Accuracy will improve momentarily; search will start when accuracy is sufficient or whenever you choose."];
            }
            
            if (_failed)
            {
                return @"Failed to find location.  Check that Location Services are enabled.";
            }
            return @"Location acquired. Select 'Refresh' to re-acquire current location.";
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == kLocatingAccuracy && self.lastLocation!=nil)
    {
        [self stopLocating];
        [self located];
    }
    else if(indexPath.row == kLocatingStop)
    {
        [self stopLocating];
        _cancelled = YES;
        
        [self.delegate locatingViewFinished:self];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[self.locationManager stopUpdatingLocation];
}

- (void)didEnterBackground {
	[self.locationManager stopUpdatingLocation];
}

- (void)didBecomeActive
{
    if (_waitingForLocation)
    {
        [self.locationManager startUpdatingLocation];
    }
}

#pragma mark Background methods

/*
- (void)BackgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled
{
    DEBUG_LOG(@"BackgroundTaskDone\n");
	_waitingForLocation = false;
    {
        [self reinit];
        [super BackgroundTaskDone:viewController cancelled:cancelled];
        [self.table reloadData];
    }
}
*/

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [LocationAuthorization locationAuthorizedOrNotDeterminedShowMsg:YES backgroundRequired:NO];
}

- (void)didTapMap:(id)sender
{
    [self refreshAction:nil];
}

@end
