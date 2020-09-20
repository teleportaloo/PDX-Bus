//
//  TripPlannerEndPoint.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/27/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripPlannerEndPointView.h"

#import "TripPlannerResultsView.h"
#import "TripPlannerLocationListView.h"
#import "RouteView.h"
#if !TARGET_OS_MACCATALYST
#import <AddressBookUI/ABPeoplePickerNavigationController.h>
#import <AddressBook/ABPerson.h>
#endif

#import "UserState.h"
#import "TripPlannerBookmarkView.h"
#import "TripPlannerOptions.h"
#import "RailMapView.h"
#import "AllRailStationView.h"
#import "TripPlannerLocatingView.h"
#import <ContactsUI/ContactsUI.h>
#import "Icons.h"

#define kTextMultiple (2.5)

enum {
    kTableSectionEnterDestination,
    kTableSectionRowLocate,
    kTableSectionRowFaves,
    
    kTableEnterRowRailStations,
    kTableEnterRowRailMap,
    kTableEnterRowEnter,
    kTableEnterRowBrowse,
    kTableEnterRowContacts,
    
    kTableLocateRowHere,
    kTableLocateRows
};


#define kTextFieldId                    @"destination"
#define kPlainFieldId                   @"triplocplain"
#define kOptionsFieldId                 @"options"

#define kStartTextDescPlaceHolder       NSLocalizedString(@"<starting place or ID>",         @"input placeholder")
#define kDestinationTextDescPlaceHolder NSLocalizedString(@"<destination place or ID>",      @"input placeholder")
#define kTextGPSPlaceHolder             NSLocalizedString(@"<using current location (GPS)>", @"input placeholder")

#define kUIEditHeight                   50.0
#define kUIRowHeight                    40.0

#define kSegRowWidth                    300
#define kSegRowHeight                   80
#define kUISegHeight                    60
#define kUISegWidth                     300

@interface TripPlannerEndPointView () {
    bool _keyboardUp;
}

@property (nonatomic, strong) UIPlaceHolderTextView *placeNameField;
@property (nonatomic, strong) CellTextView *editCell;
@property (nonatomic, readonly, strong) UIPlaceHolderTextView *createTextField_Rounded;
@property (nonatomic, readonly, strong) TripEndPoint *endPoint;

- (void)cellDidEndEditing:(EditableTableViewCell *)cell;

@end

@implementation TripPlannerEndPointView


#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    [self maybeAddFlashButtonWithSpace:NO buttons:toolbarItems big:NO];
}

#pragma mark View methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.from) {
        self.title = NSLocalizedString(@"Start", @"page title");
    } else {
        self.title = NSLocalizedString(@"Destination", @"page title");
    }
    
    [self clearSectionMaps];
    
    [self addSectionType:kTableSectionEnterDestination];
    [self addRowType:kTableEnterRowEnter];
    [self addRowType:kTableEnterRowContacts];
    [self addRowType:kTableEnterRowBrowse];
    [self addRowType:kTableEnterRowRailStations];
    [self addRowType:kTableEnterRowRailMap];
    
    if ((self.from && !self.tripQuery.userRequest.toPoint.useCurrentLocation)
        || (!self.from && !self.tripQuery.userRequest.fromPoint.useCurrentLocation)) {
        [self addSectionType:kTableSectionRowLocate];
        [self addRowType:kTableSectionRowLocate];
    }
    
    [self addSectionType:kTableSectionRowFaves];
    
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.editCell != nil) {
        if ([self endPoint] != nil && [self endPoint].locationDesc != nil) {
            self.editCell.view.text = [self endPoint].locationDesc;
        } else {
            self.editCell.view.text = @"";
        }
    }
    
    if (self.from) {
        [self reloadData];
    }
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark UI Helper functions

- (void)hideKeyboard {
    if (_keyboardUp) {
        _keyboardUp = false;
        
        if (self.placeNameField.isFirstResponder && self.placeNameField.canResignFirstResponder) {
            [self.placeNameField resignFirstResponder];
        }
        
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)doneButtonPressed {
    [self.editCell stopEditing];
}

- (void)clearButtonPressed {
    self.editCell.view.text = @"";
}

- (UIPlaceHolderTextView *)createTextField_Rounded {
    CGRect frame = CGRectMake(0.0, 0.0, 80.0, [CellTextField editHeight] * kTextMultiple);
    UIPlaceHolderTextView *returnTextField = [[UIPlaceHolderTextView alloc] initWithFrame:frame];
    
    // returnTextField.borderStyle = UITextBorderStyleRoundedRect;
    returnTextField.textColor = [UIColor modeAwareText];
    returnTextField.font = [CellTextField editFont];
    returnTextField.placeholder = @"";
    returnTextField.backgroundColor = [UIColor modeAwareGrayBackground];
    returnTextField.autocorrectionType = UITextAutocorrectionTypeYes;    // no auto correction support
    
    returnTextField.keyboardType = UIKeyboardTypeASCIICapable;
    returnTextField.returnKeyType = UIReturnKeyDefault;
    returnTextField.editable = YES;
    
    returnTextField.layer.borderWidth = 2.0f;
    returnTextField.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    
    returnTextField.clipsToBounds = YES;
    returnTextField.layer.cornerRadius = 10.0f;
    
    
    UIToolbar *keyboardToolbar = [[UIToolbar alloc] init];
    
    [keyboardToolbar sizeToFit];
    UIBarButtonItem *clearBarButton = [[UIBarButtonItem alloc]
                                       initWithTitle:NSLocalizedString(@"Clear", @"Button")
                                       style:UIBarButtonItemStylePlain
                                       target:self
                                       action:@selector(clearButtonPressed)];
    
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(doneButtonPressed)];
    
    keyboardToolbar.items = @[clearBarButton, flexBarButton, doneBarButton];
    returnTextField.inputAccessoryView = keyboardToolbar;
    
    // returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;    // has a clear 'x' button to the right
    self.placeNameField = returnTextField;
    
    return returnTextField;
}

- (void)nextScreen {
    if (self.popBackTo) {
        [self.navigationController popToViewController:self.popBackTo animated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)addDescription:(NSString *)desc {
    if (desc.length != 0) {
        if (self.endPoint == nil) {
            [self endPoint].additionalInfo = desc;
        }
    }
}

- (void)gotPlace:(NSString *)place setUiText:(bool)setText additionalInfo:(NSString *)info {
    place = [place stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (place.length != 0) {
        if (self.from) {
            self.placeNameField.placeholder = kStartTextDescPlaceHolder;
        } else {
            self.placeNameField.placeholder = kDestinationTextDescPlaceHolder;
        }
        
        if (setText && self.placeNameField != nil) {
            self.placeNameField.text = place;
        }
        
        if (self.endPoint == nil || ![place isEqualToString:[self endPoint].locationDesc]) {
            [self initEndPoint];
            [self endPoint].locationDesc = place;
            [self endPoint].additionalInfo = info;
        }
        
        [self nextScreen];
    }
}

- (void)cancelAction:(id)sender {
    [self hideKeyboard];
}

- (TripEndPoint *)endPoint {
    if (self.from) {
        return self.tripQuery.userRequest.fromPoint;
    }
    
    return self.tripQuery.userRequest.toPoint;
}

- (void)initEndPoint {
    if (self.from) {
        self.tripQuery.userRequest.fromPoint = [TripEndPoint data];
    } else {
        self.tripQuery.userRequest.toPoint = [TripEndPoint data];
    }
}

- (void)cellDidEndEditing:(EditableTableViewCell *)cell {
    UITextView *textView = (UITextView *)((CellTextField *)cell).view;
    
    if (_keyboardUp) {
        [self gotPlace:textView.text setUiText:NO additionalInfo:nil];
        self.navigationItem.rightBarButtonItem = nil;
        _keyboardUp = NO;
    }
}

// Invoked before editing begins. The delegate may return NO to prevent editing.
- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell {
    // add our custom add button as the nav bar's custom right view
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                     target:self
                                     action:@selector(cancelAction:)];
    
    self.navigationItem.rightBarButtonItem = cancelButton;
    _keyboardUp = true;
    
    
    [self.table scrollToRowAtIndexPath:[self firstIndexPathOfSectionType:kTableSectionEnterDestination rowType:kTableEnterRowEnter]
                      atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
    return YES;
}

- (void)selectFromRailStations {
    AllRailStationView *rmView = [AllRailStationView viewController];
    
    rmView.stopIdCallback = self;
    
    // Push the detail view controller
    [self.navigationController pushViewController:rmView animated:YES];
}

- (void)selectFromRailMap {
    RailMapView *railMapView = [RailMapView viewController];
    
    railMapView.stopIdCallback = self;
    
    railMapView.from = self.from;
    
    // Push the detail view controller
    [self.navigationController pushViewController:railMapView animated:YES];
}

- (void)browseForStop {
    RouteView *routeViewController = [RouteView viewController];
    
    routeViewController.stopIdCallback = self;
    [routeViewController fetchRoutesAsync:self.backgroundTask backgroundRefresh:NO];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections;
}

- (NSInteger)rowsInSection:(NSInteger)section {
    NSInteger sectionType = [self sectionType:section];
    
    if (sectionType == kTableSectionRowFaves) {
        if (self.tripQuery.userFaves != nil) {
            return self.tripQuery.userFaves.count;
        } else {
            return 0;
        }
    }
    
    return [super rowsInSection:section];
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self rowsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSInteger sectionType = [self sectionType:section];
    
    switch (sectionType) {
        case kTableSectionEnterDestination:
            
            if (self.from) {
                return NSLocalizedString(@"Choose starting address, or stop:", @"section header");
            } else {
                return NSLocalizedString(@"Choose destination, or stop:", @"section header");
            }
            
        case kTableSectionRowFaves:
            
            if (self.tripQuery.userFaves != nil && self.tripQuery.userFaves.count > 0) {
                return NSLocalizedString(@"Bookmarks:", @"section header");
            }
            
            break;
    }
    return nil;
}

- (bool)multipleStopsForFave:(NSInteger)index {
    NSMutableDictionary *item = (NSMutableDictionary *)(self.tripQuery.userFaves[index]);
    NSString *location = item[kUserFavesLocation];
    
    NSCharacterSet *comma = [NSCharacterSet characterSetWithCharactersInString:@","];
    NSRange commas = [location rangeOfCharacterFromSet:comma];
    
    return (commas.location != NSNotFound);
}

- (NSInteger)rowType:(NSIndexPath *)indexPath {
    NSInteger section = [self sectionType:indexPath.section];
    
    if (section == kTableSectionRowFaves) {
        return kTableSectionRowFaves;
    }
    
    return [super rowType:indexPath];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger rowType = [self rowType:indexPath];
    
    switch (rowType) {
        case kTableEnterRowEnter: {
            if (self.editCell == nil) {
                self.editCell = [[CellTextView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kTextFieldId];
                self.placeNameField = [self createTextField_Rounded];
                self.editCell.delegate = self;
                self.editCell.view = self.placeNameField;
                
                // self.editCell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                self.editCell.imageView.image = [Icons getIcon:kIconEnterStopID];
                self.editCell.cellLeftOffset = 50.0;
                
                if ([self endPoint].useCurrentLocation) {
                    self.placeNameField.placeholder = kTextGPSPlaceHolder;
                } else {
                    if (self.from) {
                        self.placeNameField.placeholder = kStartTextDescPlaceHolder;
                    } else {
                        self.placeNameField.placeholder = kDestinationTextDescPlaceHolder;
                    }
                }
            }
            
            if ([self endPoint] != nil && [self endPoint].locationDesc != nil && ![self endPoint].useCurrentLocation) {
                self.editCell.view.text = [self endPoint].locationDesc;
            } else {
                self.editCell.view.text = @"";
            }
            
            return self.editCell;
        }
            
        case kTableEnterRowBrowse: {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:kPlainFieldId];
            
            if (self.from) {
                cell.textLabel.text = NSLocalizedString(@"Browse for starting stop", @"main menu item");
            } else {
                cell.textLabel.text = NSLocalizedString(@"Browse for destination stop", @"main menu item");
            }
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [Icons getIcon:kIconBrowse];
            cell.textLabel.font = self.basicFont;
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            
            return cell;
        }
            
        case kTableEnterRowRailMap: {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:kPlainFieldId];
            
            if (self.from) {
                cell.textLabel.text = NSLocalizedString(@"Select from rail maps", @"main menu item");
            } else {
                cell.textLabel.text = NSLocalizedString(@"Select from rail maps",  @"main menu item");
            }
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [Icons getIcon:kIconMaxMap];
            cell.textLabel.font = self.basicFont;
            
            return cell;
        }
            
        case kTableEnterRowRailStations: {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:kPlainFieldId];
            cell.textLabel.text = NSLocalizedString(@"Search all rail stations (A-Z)", @"main menu item");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [Icons getIcon:kIconRailStations];
            cell.textLabel.font = self.basicFont;
            
            return cell;
        }
            
        case kTableEnterRowContacts: {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:kPlainFieldId];
            cell.textLabel.text = NSLocalizedString(@"Address from contacts", @"main menu item");
            
            if (self.from) {
                [cell setAccessibilityLabel:NSLocalizedString(@"Choose starting address from contacts", @"main menu item")];
            } else {
                [cell setAccessibilityLabel:NSLocalizedString(@"Choose destination address from contacts", @"main menu item")];
            }
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [Icons getIcon:kIconContacts];
            cell.textLabel.font = self.basicFont;
            return cell;
        }
            
        case kTableSectionRowFaves: {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:@"fave"];
            
            if ([self multipleStopsForFave:indexPath.row]) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            // Set up the cell
            NSDictionary *item = self.tripQuery.userFaves[indexPath.row];
            // printf("item %p\n", item);
            
            cell.textLabel.text = item[kUserFavesChosenName];
            cell.textLabel.font = self.basicFont;
            [self updateAccessibility:cell];
            cell.imageView.image = [Icons getIcon:kIconFave];
            return cell;
        }
            
        case kTableSectionRowLocate: {
            UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:kPlainFieldId];
            
            if (self.from) {
                cell.textLabel.text = NSLocalizedString(@"Start from current location (GPS)", @"main menu item");
            } else {
                cell.textLabel.text = NSLocalizedString(@"Go to current location (GPS)", @"main menu item");
            }
            
            cell.textLabel.font = self.basicFont;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.imageView.image = [Icons getModeAwareIcon:kIconLocate7];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            return cell;
        }
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger rowType = [self rowType:indexPath];
    
    switch (rowType) {
        case kTableEnterRowEnter:
            return [CellTextField cellHeight] * kTextMultiple;
            
        case   kTableEnterRowRailStations:
        case   kTableEnterRowRailMap:
        case   kTableEnterRowBrowse:
        case   kTableEnterRowContacts:
            return [self basicRowHeight];
            
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
    
    NSInteger rowType = [self rowType:indexPath];
    
    switch (rowType) {
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
            
        case kTableEnterRowContacts: {
            // self.navigationItem.rightBarButtonItem = nil;
            
            if ([CNContactStore class]) {
                CNContactPickerViewController *picker = [[CNContactPickerViewController alloc] init];
                
                picker.delegate = self;
                picker.displayedPropertyKeys = [[NSArray alloc] initWithObjects:CNContactPostalAddressesKey, nil];;
                picker.predicateForEnablingContact = [NSPredicate predicateWithFormat:@"postalAddresses.@count > 0"];
                picker.predicateForSelectionOfContact = [NSPredicate predicateWithFormat:@"postalAddresses.@count == 1"];
                
                [self presentViewController:picker animated:YES completion:nil];
            }
            
            break;
            
        case kTableSectionRowFaves: {
            NSMutableDictionary *item = (NSMutableDictionary *)(self.tripQuery.userFaves[indexPath.row]);
            NSString *location = item[kUserFavesLocation];
            
            if (![self multipleStopsForFave:indexPath.row]) {
                // Set up the cell
                NSDictionary *item = self.tripQuery.userFaves[indexPath.row];
                // printf("item %p\n", item);
                
                [self gotPlace:location setUiText:YES additionalInfo:item[kUserFavesChosenName]];
            } else {
                TripPlannerBookmarkView *bmView = [TripPlannerBookmarkView viewController];
                bmView.stopIdCallback = self;
                bmView.from = self.from;
                
                // bmView.displayName = item[kUserFavesOriginalName];
                [bmView fetchNamesForStopIdsAsync:self.backgroundTask stopIds:location];
            }
            
            break;
        }
            
        case kTableSectionRowLocate: {
            [self initEndPoint];
            [self endPoint].useCurrentLocation = YES;
            self.placeNameField.text = @"";
            // self.placeNameField.placeholder=kTextGPSPlaceHolder;
            
            [self nextScreen];
            break;
        }
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    UITextView *textView = (UITextView *)(self.editCell).view;
    
    if (_keyboardUp) {
        [self.placeNameField resignFirstResponder];
    } else {
        if (textView.text.length == 0 && self.endPoint.useCurrentLocation) {
            [self nextScreen];
        } else {
            [self gotPlace:textView.text setUiText:NO additionalInfo:nil];
        }
    }
}

#pragma mark ReturnStopID methods

- (NSString *)actionText {
    if (self.from) {
        return @"Set as starting stop";
    }
    
    return @"Set as destination";
}

- (void)selectedStop:(NSString *)stopId {
}

- (void)selectedStop:(NSString *)stopId desc:(NSString *)stopDesc {
    if (stopId != nil) {
        [self gotPlace:stopId setUiText:YES additionalInfo:stopDesc];
    }
}

- (UIViewController *)controller {
    return self;
}

#pragma mark People Picker methods

- (void)addName:(NSMutableString **)fullName item:(NSString *)item {
    NSMutableString *full = *fullName;
    
    if (item == nil || item.length == 0) {
        return;
    }
    
    if (full.length > 0) {
        [full appendString:@" "];
    }
    
    [full appendString:item];
}

- (void)delayedCompletion:(NSTimer *)timer {
    NSArray *info = (NSArray *)timer.userInfo;
    
    [self gotPlace:info.firstObject setUiText:YES additionalInfo:info[1]];
}

#pragma mark Contact Picker methods

/*!
 * @abstract Invoked when the picker is closed.
 * @discussion The picker will be dismissed automatically after a contact or property is picked.
 */
- (void)contactPickerDidCancel:(CNContactPickerViewController *)picker {
}

- (void)getAddress:(CNPostalAddress *)postalAddress description:(NSString *)description {
    NSMutableString *address = [NSMutableString string];
    
    
    if (postalAddress.street) {
        [address appendString:postalAddress.street];
        
        if (description == nil) {
            description = postalAddress.street;
        }
    }
    
    if (postalAddress.city) {
        if (address.length > 0) {
            [address appendString:@", "];
        }
        
        [address appendString:postalAddress.city];
    }
    
    if (postalAddress.state) {
        if (address.length > 0) {
            [address appendString:@", "];
        }
        
        [address appendString:postalAddress.state];
    }
    
    [self gotPlace:address setUiText:YES additionalInfo:description];
}

/*!
 * @abstract Singular delegate methods.
 * @discussion These delegate methods will be invoked when the user selects a single contact or property.
 */



- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContact:(CNContact *)contact {
    CNLabeledValue *addressValue = contact.postalAddresses.firstObject;
    CNPostalAddress *postalAddress = addressValue.value;
    
    NSMutableString *fullName = [NSMutableString string];
    
    if (contact.contactType == CNContactTypePerson) {
        [self addName:&fullName item:contact.namePrefix];
        [self addName:&fullName item:contact.givenName];
        [self addName:&fullName item:contact.middleName];
        [self addName:&fullName item:contact.familyName];
        [self addName:&fullName item:contact.nameSuffix];
    }
    
    if (contact.contactType == CNContactTypeOrganization) {
        [self addName:&fullName item:contact.organizationName];
    }
    
    [self getAddress:postalAddress description:fullName];
}

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContactProperty:(CNContactProperty *)contactProperty {
    CNPostalAddress *postalAddress = contactProperty.value;
    
    [self getAddress:postalAddress description:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if (@available(iOS 13.0, *)) {
        if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
            self.editCell = nil;
        }
    }
    
    [super traitCollectionDidChange:previousTraitCollection];
}

@end
