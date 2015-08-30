//
//  SupportView.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "SupportView.h"
#include "CellLabel.h"
#include "WebViewController.h"
#include "TriMetXML.h"
#import "WhatsNewView.h"
#import "AboutView.h"
#import "BlockColorDb.h"
#import "BlockColorViewController.h"
#import "DebugLogging.h"
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>

#define kSectionSupport			0
#define kSectionTips			1
#define kSectionLinks			2
#define kSectionNetwork			3
#define kSectionCache           4
#define kSectionHighlights      5
#define kSectionPrivacy         6

#define kSections               7

#define kLinkRows				3
			
#define kSectionSupportRows		3
#define kSectionSupportRowSupport 0
#define kSectionSupportRowNew	 1
#define kSectionSupportHowToRide 2

#define kSectionLinkRows        4
#define kSectionLinkBlog        0
#define kSectionLinkTwitter     1
#define kSectionLinkFacebook    2
#define kSectionLinkGitHub      3

#define kSectionPrivacyRows     2
#define kSectionPrivacyRowLocation 0
#define kSectionPrivacyRowCamera   1



@implementation SupportView

@synthesize hideButton = _hideButton;
@synthesize locMan     = _locMan;
@synthesize locationText = _locationText;
@synthesize cameraText = _cameraText;

- (void)dealloc {
	[supportText release];
    [tipText release];
    self.locMan = nil;
    self.locationText = nil;
    self.cameraText = nil;
	[super dealloc];
}

#pragma mark Helper functions

- (UITableViewStyle) getStyle
{
	return UITableViewStyleGrouped;
}

#pragma mark Table view methods


- (bool)canOpenSettings
{
    return([[UIDevice currentDevice].systemVersion floatValue] >= 8.0);
}

- (void)initCameraText
{
    _cameraGoesToSettings = NO;
    if ([[AVCaptureDevice class] respondsToSelector:@selector(authorizationStatusForMediaType:)])
    {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        switch (authStatus)
        {
            default:
            case AVAuthorizationStatusAuthorized:
                if ([self canOpenSettings])
                {
                    self.cameraText = @"Camera access is authorized. Touch here to check settings.";
                    _cameraGoesToSettings = YES;
                }
                else
                {
                    self.cameraText = @"Camera access is authorized.";
                }
                break;
            case AVAuthorizationStatusNotDetermined:
                self.cameraText = @"Camera access has not been set up by the user. Touch here to set this up.";
                break;
            case AVAuthorizationStatusDenied:
                if ([self canOpenSettings])
                {
                    self.cameraText = @"Camera access has been denied by the user. Touch here to go to the settings app re-enable Camera access.";
                    _cameraGoesToSettings = YES;
                }
                else
                {
                   self.cameraText = @"Camera access has been denied by the user. Go to the settings app and select PDX Bus to re-enable Camera access.";
                }
                break;
            case AVAuthorizationStatusRestricted:
                self.cameraText = @"Camea access has been restricted. Check the restrictions section in the Setttings app under 'General->Restrictions' to change this.";
                break;
        }
    }
    else
    {
        self.cameraText = @"Camera access can not be determined on this version of iOS.";
    }
}

- (void)initLocationText
{
    _locationGoesToSettings = NO;
    switch ([CLLocationManager authorizationStatus])
    {
            // User has not yet made a choice with regards to this application
        default:
        case kCLAuthorizationStatusNotDetermined:
            self.locationText = @"Location Services: Authorization has not been set by the user. Touch here to set this up.";
            break;
            
            // This application is not authorized to use location services.  Due
            // to active restrictions on location services, the user cannot change
            // this status, and may not have personally denied authorization
        case kCLAuthorizationStatusRestricted:
            self.locationText = @"Location Services: Authorization has been restricted. Check the restrictions section in the Setttings app under 'General->Restrictions' to change this.";
            break;
            
            // User has explicitly denied authorization for this application, or
            // location services are disabled in Settings.
        case kCLAuthorizationStatusDenied:
            if (self.canOpenSettings)
            {
                _locationGoesToSettings = YES;
                self.locationText = @"Location Services: Authorization has been denied. Touch here to go to the settings app to re-enable location services.";
            }
            else
            {
                self.locationText = @"Location Services: Authorization has been denied. Go to the settings app and select PDX Bus to re-enable location services.";
            }
            break;
            
            // User has granted authorization to use their location at any time,
            // including monitoring for regions, visits, or significant location changes.
        case kCLAuthorizationStatusAuthorizedAlways:
            if (self.canOpenSettings)
            {
                self.locationText = @"Location Services: Authorization has been granted for use in the background for the alarms. Touch here to check settings.";
                _locationGoesToSettings = YES;

            }
            else
            {
                self.locationText = @"Location Services: Authorization has been granted for use in the background for the alarms.";

            }
            break;
            
            // User has granted authorization to use their location only when your app
            // is visible to them (it will be made visible to them if you continue to
            // receive location updates while in the background).  Authorization to use
            // launch APIs has not been granted.
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            if (self.canOpenSettings)
            {
                self.locationText = @"Location Services: Authorization has been granted for use only when PDX Bus is being used, which means the proximity alarms will not work in iOS 8. Touch here to change this to allow alarms to work - choose 'Always' for location.";
                _locationGoesToSettings = YES;
            }
            else
            {
                self.locationText = @"Location Services: Authorization has been granted for use only when PDX Bus is being used, which means the proximity alarms will not work in iOS 8. To change this to allow alarms to work go to the Settings app and select PDX Bus  - choose 'Always' for location.";
            }
            break;
    }
}

- (id)init {
	if ((self = [super init]))
	{
		self.title = @"Help and Support";
        
		supportText = @"One developer writes PDX Bus as a volunteer effort, with a little help from friends and the local community. He has no affiliation with TriMet, but he happens to ride TriMet on most days. "
                    "\n\nThe arrival data is provided by TriMet and Portland Streetcar and should be same as the transit tracker data. "
                    "Please contact TriMet for issues about late busses or other transit issues as he cannot help. "
                    "\n\nFor app support or feature requests please leave a comment on the blog; alternatively use twitter, Facebook or Github. He is not able to respond to app store reviews, "
                    "so do not use these for support or feature requests. "
                    "He cannot provide an email address for support because of privacy reasons, both yours and his.";
        
        tipText = [[NSArray alloc] initWithObjects:
                   @"There are LOTS of settings for PDXBus - take a look at the settings on the front screen to change colors, move the bookmarks to the top of the screen or change other options.",
                   @"When the time is shown in red the vehicle will depart in 5 minutes or less.",
                   @"When the time is shown in blue the vehicle will depart in more than 5 minutes.",
                   @"When the time is shown in gray no location infomation is available - the scheduled time is shown.",
                   @"When the time is shown in orange and crossed out the vehicle was canceled.  The original scheduled time is shown for reference.",
                   @"Sometimes the scheduled time is also shown in gray when the vehicle is not running to schedule.",
                   @"Shake the device to refresh the arrival times.",
                   @"Backup your bookmarks by emailing them to yourself.",
                   @"Keep an eye on the toolbar at the bottom - there are maps, options, and other features to explore.",
                   @"At night, TriMet recommends holding up a cell phone or flashing light so the driver can see you.",
                   @"Many issues can be solved by deleting the app and reinstalling - be sure to email the bookmarks to yourself first so you can restore them.",
                   nil];
    
        [self initLocationText];
        [self initCameraText];
        
        self.locMan = [[[CLLocationManager alloc] init] autorelease];
        
        if ([self.locMan respondsToSelector:@selector(requestAlwaysAuthorization)])
        {
            [self.locMan requestAlwaysAuthorization];
            
            self.locMan.delegate = self;
        }
	}
	return self;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
    if (!_hideButton)
    {
        UIBarButtonItem *info = [[[UIBarButtonItem alloc]
                                  initWithTitle:@"About"
                                  style:UIBarButtonItemStyleBordered
                                  target:self action:@selector(infoAction:)] autorelease];
        
        
        self.navigationItem.rightBarButtonItem = info;
	}
}

- (void)infoAction:(id)sender
{
	AboutView *infoView = [[AboutView alloc] init];
    
    infoView.hideButton = YES;
	
	// Push the detail view controller
    [[self navigationController] pushViewController:infoView animated:YES];
	[infoView release];
	
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case kSectionSupport:
			return @"PDX Bus - App Support";
        case kSectionTips:
			return @"Tips";
		case kSectionLinks:
			return @"App Support Links";
        case kSectionNetwork:
			return @"Network & Server Connectivity";
        case kSectionPrivacy:
            return @"Privacy";
		case kSectionCache:
			return @"Route and Stop Data Cache";
        case kSectionHighlights:
			return @"Vehicle highlights";

	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case kSectionSupport:
			return kSectionSupportRows;
		case kSectionLinks:
			return kSectionLinkRows;
        case kSectionNetwork:
		case kSectionCache:
        case kSectionHighlights:
            return 1;
        case kSectionPrivacy:
            return kSectionPrivacyRows;
        case kSectionTips:
			return [tipText count];
	}
	return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (indexPath.section) {
		case kSectionNetwork:
		{
			static NSString *networkId = @"network";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:networkId];
			if (cell == nil) {
				
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:networkId] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				/*
				 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
				 */
				
				cell.textLabel.font =  [self getBasicFont]; //  [UIFont fontWithName:@"Ariel" size:14];
				cell.textLabel.adjustsFontSizeToFitWidth = YES;
				cell.textLabel.text = @"Check Network Connection";
				cell.imageView.image = [self getActionIcon:kIconNetwork];
				
			}
			return cell;
			break;
		}
		case kSectionCache:
		{
			static NSString *cacheId = @"cache";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cacheId];
			if (cell == nil) {
				
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cacheId] autorelease];
				cell.textLabel.font =  [self getBasicFont]; //  [UIFont fontWithName:@"Ariel" size:14];
				cell.textLabel.adjustsFontSizeToFitWidth = YES;
				cell.textLabel.text = @"Delete Cached Routes and Stops";
				cell.textLabel.textAlignment = NSTextAlignmentLeft;
				cell.imageView.image = [self getActionIcon:kIconDelete];
			}
			return cell;
			break;
		}
            
        case kSectionHighlights:
		{
			static NSString *cacheId = @"high";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cacheId];
			if (cell == nil) {
				
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cacheId] autorelease];
				cell.textLabel.font =  [self getBasicFont]; //  [UIFont fontWithName:@"Ariel" size:14];
				cell.textLabel.adjustsFontSizeToFitWidth = YES;
				cell.textLabel.text = @"Show vehicle color tags";
				cell.textLabel.textAlignment = NSTextAlignmentLeft;
				cell.imageView.image = [BlockColorDb imageWithColor:[UIColor redColor]];
			}
			return cell;
			break;
		}
			
		case kSectionSupport:
		{
			if (indexPath.row == kSectionSupportRowSupport)
			{
				static NSString *aboutId = @"about";
				CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:aboutId];
				if (cell == nil) {
					cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:aboutId] autorelease];
					cell.view = [self create_UITextView:nil font:[self getParagraphFont]];
				}
				
				cell.view.font =  [self getParagraphFont];
				cell.view.text =  supportText;
				DEBUG_LOG(@"width:  %f\n", cell.view.bounds.size.width);
    
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				[self updateAccessibility:cell indexPath:indexPath text:supportText alwaysSaySection:YES];
				// cell.backgroundView = [self clearView];
				return cell;
			}
			else {
				static NSString *newId = @"newid";
				UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:newId];
				if (cell == nil) {
					
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:newId] autorelease];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					/*
					 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
					 */
					
					cell.textLabel.font =  [self getBasicFont]; //  [UIFont fontWithName:@"Ariel" size:14];
					cell.textLabel.adjustsFontSizeToFitWidth = YES;
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				}
                
                if (indexPath.row == kSectionSupportHowToRide)
                {
                    cell.textLabel.text = @"How to ride";
                    cell.imageView.image = [self getActionIcon:kIconAbout];
                }
                else 
                {
                    cell.textLabel.text = @"What's new?";
                    cell.imageView.image = [self getActionIcon:kIconAppIconAction];
                }
				return cell;
			}

			break;
		}
		case kSectionLinks:
		{
			static NSString *linkId = @"pdxbuslink";
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:linkId];
			if (cell == nil) {
				
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:linkId] autorelease];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				/*
				 [self newLabelWithPrimaryColor:[UIColor blueColor] selectedColor:[UIColor cyanColor] fontSize:14 bold:YES parentView:[cell contentView]];
				 */
				
				cell.textLabel.font =  [self getBasicFont]; //  [UIFont fontWithName:@"Ariel" size:14];
				cell.textLabel.textColor = [UIColor blueColor];
				cell.textLabel.adjustsFontSizeToFitWidth = YES;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			}
			
			switch (indexPath.row)
			{
			case kSectionLinkBlog:
				cell.textLabel.text = @"PDX Bus blog & support";
				cell.imageView.image = [self getActionIcon:kIconBlog];
				break;
            case kSectionLinkTwitter:
                cell.textLabel.text = @"@pdxbus on Twitter";
                cell.imageView.image = [self getActionIcon:kIconTwitter];
                break;
            case kSectionLinkGitHub:
                cell.textLabel.text = @"pdxbus on GitHub";
                cell.imageView.image = [self getActionIcon:kIconSrc];
                break;
            case kSectionLinkFacebook:
                cell.textLabel.text = @"Facebook page";
                cell.imageView.image = [self getActionIcon:kIconFacebook];
                break;
            }
			[cell setAccessibilityLabel:[NSString stringWithFormat:@"Link to %@", cell.textLabel.text]];
			return cell;
			break;
		}
        case kSectionTips:
		{
			static NSString *tipsId = @"tips";
			CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:tipsId];
			if (cell == nil) {
				cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tipsId] autorelease];
				cell.view = [self create_UITextView:nil font:[self getParagraphFont]];
			}
			
			cell.view.font =  [self getParagraphFont];
			cell.view.text = [tipText objectAtIndex:indexPath.row];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			[self updateAccessibility:cell indexPath:indexPath text:[tipText objectAtIndex:indexPath.row] alwaysSaySection:YES];
			return cell;
			break;
		}
        case kSectionPrivacy:
        {
            static NSString *tipsId = @"tips";
            CellLabel *cell = (CellLabel *)[tableView dequeueReusableCellWithIdentifier:tipsId];
            if (cell == nil) {
                cell = [[[CellLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tipsId] autorelease];
                cell.view = [self create_UITextView:nil font:[self getParagraphFont]];
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cell.view.font =  [self getParagraphFont];
            
            if (indexPath.row == kSectionPrivacyRowLocation)
            {
                cell.view.text = self.locationText;
                [self updateAccessibility:cell indexPath:indexPath text:self.locationText alwaysSaySection:YES];
            }
            else
            {
                cell.view.text = self.cameraText;
                [self updateAccessibility:cell indexPath:indexPath text:self.cameraText alwaysSaySection:YES];
            }
            return cell;
            break;
        }
		default:
			break;
	}
	
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section) {
		case kSectionSupport:
			if (indexPath.row == kSectionSupportRowSupport)
			{
				return [self getTextHeight:supportText font:[self getParagraphFont]];
			}
			break;
        case kSectionTips:
			return [self getTextHeight:[tipText objectAtIndex:indexPath.row] font:[self getParagraphFont]];
        case kSectionPrivacy:
            if (indexPath.row == kSectionPrivacyRowLocation)
            {
                return [self getTextHeight:self.locationText font:[self getParagraphFont]];
            }
            else
            {
                return [self getTextHeight:self.cameraText font:[self getParagraphFont]];
            }
		default:
			break;
	}
	return [self basicRowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section)
	{
		case kSectionLinks:
		{
			WebViewController *webPage = [[WebViewController alloc] init];
		
			switch (indexPath.row)
			{
				case kSectionLinkBlog:
					[webPage setURLmobile:@"http:/pdxbus.teleportaloo.org" full:nil];
                    [webPage displayPage:[self navigationController] animated:YES itemToDeselect:self];
					break;
                case kSectionLinkGitHub:
					[webPage setURLmobile:@"http:/github.com/teleportaloo/PDX-Bus" full:nil];
                    [webPage displayPage:[self navigationController] animated:YES itemToDeselect:self];
					break;
                case kSectionLinkTwitter:
                    self.tweetAt   = @"pdxbus";
                    self.initTweet = @"@pdxbus";
                    [self tweet];
                    break;
                case kSectionLinkFacebook:
                    [self facebook];
                    break;
            }
	
            [webPage release];
			
			break;
		}
		case kSectionNetwork:
			[self networkTips:nil networkError:nil];
            [self clearSelection];
			break;
		case kSectionCache:
		{
			[TriMetXML deleteCacheFile];
			[self.table deselectRowAtIndexPath:indexPath animated:YES];
			UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Data Cache"
															   message:@"Cached Routes and Stops have been deleted"
															  delegate:nil
													 cancelButtonTitle:@"OK"
													 otherButtonTitles:nil ] autorelease];
			[alert show];
			
			break;
		}
        case kSectionHighlights:
		{
            BlockColorViewController *blockTable = [[BlockColorViewController alloc] init];
            [[self navigationController] pushViewController:blockTable animated:YES];
            [blockTable release];
            
            /*
			[[BlockColorDb getSingleton] clearAll];
            [self.table deselectRowAtIndexPath:indexPath animated:YES];
			*/
            break;
		}
		case kSectionSupport:
			if (indexPath.row == kSectionSupportRowSupport)
			{
				[[self navigationController] popViewControllerAnimated:YES];
			}
			else if (indexPath.row == kSectionSupportHowToRide)
            {
                WebViewController *webPage = [[WebViewController alloc] init];
                [webPage setURLmobile:@"http://trimet.org/howtoride/index.htm" full:nil]; 
                [webPage displayPage:[self navigationController] animated:YES itemToDeselect:self];
                [webPage release];
            }
            else
			{
				WhatsNewView *whatsNew = [[WhatsNewView alloc] init];
				[[self navigationController] pushViewController:whatsNew animated:YES];
				[whatsNew release];
			}
			break;
        case kSectionPrivacy:
        {
            if (indexPath.row == kSectionPrivacyRowLocation)
            {
                if (_locationGoesToSettings)
                {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }
                else
                {
                    self.locMan = [[[CLLocationManager alloc] init] autorelease];
            
                    if ([self.locMan respondsToSelector:@selector(requestAlwaysAuthorization)])
                    {
                        [self.locMan requestAlwaysAuthorization];
                
                        self.locMan.delegate = self;
                    }
                }
            }
            else
            {
                if (_cameraGoesToSettings)
                {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }
                else if (  [[AVCaptureDevice class] respondsToSelector:@selector(requestAccessForMediaType:completionHandler:)])
                {
                    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                        if(granted){
                            NSLog(@"Granted access to %@", AVMediaTypeVideo);
                        } else {
                            NSLog(@"Not granted access to %@", AVMediaTypeVideo);
                        }
                        [self initCameraText];
                        [self reloadData];
                    }
                     ];
                }
            }
            break;
        }
	}
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [self initLocationText];
    [self reloadData];
}




@end

