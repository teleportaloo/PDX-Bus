//
//  LocatingView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/10/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//

#import "LocatingView.h"
#import "RootViewController.h"
#import "debug.h"

#define kLocatingRowHeight		60.0
#define MAX_AGE					-30.0
#define TEXT_TAG 1
#define PROGRESS_TAG 2

#define kLocatingAccuracy	0
#define kLocatingStop		1

#define kSectionButtons     0
#define kSectionText        1



#define kCancelId @"cancel"



@implementation LocatingView

@synthesize progressInd			= _progressInd;
@synthesize locationManager		= _locationManager;
@synthesize lastLocation		= _lastLocation;
@synthesize progressCell		= _progressCell;
@synthesize timeStamp			= _timeStamp;
@synthesize failed              = _failed;
@synthesize accuracy            = _accuracy;
@synthesize delegate            = _delegate;

- (void)dealloc {
	self.locationManager.delegate	= nil;
	self.locationManager			= nil;
	self.progressInd				= nil;
	self.lastLocation				= nil;
	self.progressCell				= nil;
	self.timeStamp					= nil;
    self.delegate                   = nil;
	
    [super dealloc];
}

- (id) init
{
	if ((self = [super init]))
	{
		self.locationManager = [[[CLLocationManager alloc] init] autorelease];
		self.locationManager.delegate = self; // Tells the location manager to send updates to this object
		_failed = false;
        _waitingForLocation = YES;
        self.title = @"Locator";
	}
	return self;
}

#pragma mark Check the last location

- (bool)checkLocation
{
	
    DEBUG_LOG(@"Timeinterval %f\n",[self.timeStamp timeIntervalSinceNow] );
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

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)startLocating
{
    [self.locationManager startUpdatingLocation];
	[self.progressInd startAnimating];
	
	_waitingForLocation = true;
    
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

-(NSString *)formatDistance:(double)distance
{
	NSString *str = nil;
	if (distance < 500)
	{
		str = [NSString stringWithFormat:@"%d ft (%d meters)", (int)(distance * 3.2808398950131235),
			   (int)(distance) ];
	}
	else
	{
		str = [NSString stringWithFormat:@"%.2f miles (%.2f km)", (float)(distance / 1609.344),
			   (float)(distance / 1000) ];
	}
	return str;
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
	label.lineBreakMode = UILineBreakModeWordWrap;
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
    return 2;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kSectionButtons)
    {
        return 2;
    }
    return 0;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kLocatingRowHeight;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    
    if ([cell.reuseIdentifier isEqualToString:kCancelId])
	{
        if (_waitingForLocation)
        {
            cell.backgroundColor = [UIColor redColor];
        }
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section != kSectionButtons)
    {
        return nil;
    }
    
    switch (indexPath.row)
    {
        case kLocatingAccuracy:
        {
            static NSString *locSecid = @"LocatingSection";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:locSecid];
            if (cell == nil) {
                cell = [self accuracyCellWithReuseIdentifier:locSecid];
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
                             [self formatDistance:self.lastLocation.horizontalAccuracy]];
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
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCancelId];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCancelId] autorelease];
            }
            if (_waitingForLocation)
            {
                cell.textLabel.text = @"Cancel";
            }
            else
            {
                cell.textLabel.text =@"Done";
            }
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.accessoryType = UITableViewCellAccessoryNone;
            // cell.imageView.image = [self getActionIcon:kIconCancel];
            cell.textLabel.font = [self getBasicFont];
            
            [self updateAccessibility:cell indexPath:indexPath text:cell.textLabel.text alwaysSaySection:YES];
            return cell;
        }	
    }
    
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == kSectionText)
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


@end
