//
//  TripPlannerEndPointViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/27/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripPlannerEndPointViewController.h"

#import "RouteViewController.h"
#import "TripPlannerLocationListViewController.h"
#import "TripPlannerResultsViewController.h"
#if !TARGET_OS_MACCATALYST
#import <AddressBook/ABPerson.h>
#import <AddressBookUI/ABPeoplePickerNavigationController.h>
#endif // !TARGET_OS_MACCATALYST

#import "AllRailStationViewController.h"
#import "Icons.h"
#import "RailMapViewController.h"
#import "TriMetInfo+UI.h"
#import "TripPlannerBookmarkViewController.h"
#import "TripPlannerFetcher.h"
#import "TripPlannerOptionsViewController.h"
#import "UITableViewCell+Icons.h"
#import "UserParams.h"
#import "UserState.h"
#import <ContactsUI/ContactsUI.h>

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

#define kTextFieldId @"destination"
#define kPlainFieldId @"triplocplain"
#define kOptionsFieldId @"options"

#define kStartTextDescPlaceHolder NSLocalizedString(@"<starting place or ID>", @"input placeholder")
#define kDestinationTextDescPlaceHolder                                                            \
    NSLocalizedString(@"<destination place or ID>", @"input placeholder")
#define kTextGPSPlaceHolder                                                                        \
    NSLocalizedString(@"<using current location (GPS)>", @"input placeholder")

#define kUIEditHeight 50.0
#define kUIRowHeight 40.0

#define kSegRowWidth 300
#define kSegRowHeight 80
#define kUISegHeight 60
#define kUISegWidth 300

@interface TripPlannerEndPointViewController () {
    bool _keyboardUp;
}

@property (nonatomic, strong) UIPlaceHolderTextView *placeNameField;
@property (nonatomic, strong) CellTextView *editCell;
@property (nonatomic, readonly, strong) UIPlaceHolderTextView *createTextField_Rounded;
@property (nonatomic, readonly, strong) TripEndPoint *endPoint;

- (void)cellDidEndEditing:(EditableTableViewCell *)cell;

@end

@implementation TripPlannerEndPointViewController

#pragma mark TableViewWithToolbar methods

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

- (void)updateToolbarItems:(NSMutableArray<UIBarButtonItem *> *)toolbarItems {
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

    if ((self.from && !self.tripQuery.userRequest.toPoint.useCurrentLocation) ||
        (!self.from && !self.tripQuery.userRequest.fromPoint.useCurrentLocation)) {
        [self addSectionType:kTableSectionRowLocate];
        [self addRowType:kTableSectionRowLocate];
    }

    [self addSectionType:kTableSectionRowFaves];
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
    returnTextField.autocorrectionType = UITextAutocorrectionTypeYes; // no auto correction support

    returnTextField.keyboardType = UIKeyboardTypeASCIICapable;
    returnTextField.returnKeyType = UIReturnKeyDefault;
    returnTextField.editable = YES;

    returnTextField.layer.borderWidth = 2.0f;
    returnTextField.layer.borderColor = [[UIColor lightGrayColor] CGColor];

    returnTextField.clipsToBounds = YES;
    returnTextField.layer.cornerRadius = 10.0f;

    UIToolbar *keyboardToolbar = [[UIToolbar alloc] init];

    [keyboardToolbar sizeToFit];
    UIBarButtonItem *clearBarButton =
        [UIBarButtonItem textButton:NSLocalizedString(@"Clear", @"Button")
                             target:self
                             action:@selector(clearButtonPressed)];

    UIBarButtonItem *flexBarButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                      target:nil
                                                      action:nil];
    UIBarButtonItem *doneBarButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self
                                                      action:@selector(doneButtonPressed)];

    keyboardToolbar.items = @[ clearBarButton, flexBarButton, doneBarButton ];
    returnTextField.inputAccessoryView = keyboardToolbar;
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
    place =
        [place stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

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
        self.tripQuery.userRequest.fromPoint = [TripEndPoint new];
    } else {
        self.tripQuery.userRequest.toPoint = [TripEndPoint new];
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
    UIBarButtonItem *cancelButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target:self
                                                      action:@selector(cancelAction:)];

    self.navigationItem.rightBarButtonItem = cancelButton;
    _keyboardUp = true;

    [self.tableView
        scrollToRowAtIndexPath:[self firstIndexPathOfSectionType:kTableSectionEnterDestination
                                                         rowType:kTableEnterRowEnter]
              atScrollPosition:UITableViewScrollPositionTop
                      animated:YES];

    return YES;
}

- (void)selectFromRailStations {
    AllRailStationViewController *rmView = [AllRailStationViewController viewController];

    rmView.stopIdStringCallback = self;

    // Push the detail view controller
    [self.navigationController pushViewController:rmView animated:YES];
}

- (void)selectFromRailMap {
    RailMapViewController *railMapView = [RailMapViewController viewController];

    railMapView.stopIdStringCallback = self;

    railMapView.from = self.from;

    // Push the detail view controller
    [self.navigationController pushViewController:railMapView animated:YES];
}

- (void)browseForStop {
    RouteViewController *routeViewController = [RouteViewController viewController];

    routeViewController.stopIdStringCallback = self;
    [routeViewController fetchRoutesAsync:self.backgroundTask backgroundRefresh:NO];
}

#pragma mark Table view methods

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
    UserParams *item = self.tripQuery.userFaves[index].userParams;
    NSString *location = item.valLocation;

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self hideKeyboard];
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark ReturnStopIdString methods

- (NSString *)returnStopIdStringActionText {
    if (self.from) {
        return @"Set as Trip starting stop";
    }

    return @"Set as Trip destination stop";
}

- (void)returnStopIdString:(NSString *)stopId desc:(NSString *)stopDesc {
    if (stopId != nil) {
        [self gotPlace:stopId setUiText:YES additionalInfo:stopDesc];
    }
}

- (UIViewController *)returnStopIdStringController {
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
 * @discussion The picker will be dismissed automatically after a contact or
 * property is picked.
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
 * @discussion These delegate methods will be invoked when the user selects a
 * single contact or property.
 */

- (void)contactPicker:(CNContactPickerViewController *)picker
     didSelectContact:(CNContact *)contact {
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

- (void)contactPicker:(CNContactPickerViewController *)picker
    didSelectContactProperty:(CNContactProperty *)contactProperty {
    CNPostalAddress *postalAddress = contactProperty.value;

    [self getAddress:postalAddress description:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
        self.editCell = nil;
    }
    [super traitCollectionDidChange:previousTraitCollection];
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS TripPlannerEndPointViewController
//--------------------------------------------------------------------------------------------------
#pragma mark kTableEnterRowEnter

CELL_CONFIG_METHOD(kTableEnterRowEnter) {
    if (self.editCell == nil) {
        self.editCell = [[CellTextView alloc] initWithStyle:UITableViewCellStyleDefault
                                            reuseIdentifier:kTextFieldId];
        self.placeNameField = [self createTextField_Rounded];
        self.editCell.delegate = self;
        self.editCell.view = self.placeNameField;
        self.editCell.icon = kIconEnterStopID;
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

    if ([self endPoint] != nil && [self endPoint].locationDesc != nil &&
        ![self endPoint].useCurrentLocation) {
        self.editCell.view.text = [self endPoint].locationDesc;
    } else {
        self.editCell.view.text = @"";
    }

    return self.editCell;
}

CELL_HEIGHT_METHOD(kTableEnterRowEnter) { return [CellTextField cellHeight] * kTextMultiple; }

CELL_STATIC_VTABLE(kTableEnterRowEnter){
    SET_CELL_CONFIG_SEL(kTableEnterRowEnter),
    SET_CELL_HEIGHT_SEL(kTableEnterRowEnter),
};

//--------------------------------------------------------------------------------------------------
#pragma mark kTableEnterRowBrowse

BASIC_CELL_SELECT(kTableEnterRowBrowse,
                  self.from ? NSLocalizedString(@"Browse for starting stop", @"main menu item")
                            : NSLocalizedString(@"Browse for destination stop", @"main menu item"),
                  kIconBrowse,
                  UITableViewCellAccessoryDisclosureIndicator) {
    [self browseForStop];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableEnterRowRailMap

BASIC_CELL_SELECT(kTableEnterRowRailMap,
                  NSLocalizedString(@"Select from rail maps", @"main menu item"),
                  kIconMaxMap,
                  UITableViewCellAccessoryDisclosureIndicator) {
    [self selectFromRailMap];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableEnterRowRailStations

BASIC_CELL_SELECT(kTableEnterRowRailStations,
                  NSLocalizedString(@"Search all rail stations (A-Z)", @"main menu item"),
                  kIconRailStations,
                  UITableViewCellAccessoryDisclosureIndicator) {
    [self selectFromRailStations];
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableEnterRowContacts

BASIC_CELL_SELECT(kTableEnterRowContacts,
                  NSLocalizedString(@"Address from contacts", @"main menu item"),
                  kIconContacts,
                  UITableViewCellAccessoryDisclosureIndicator) {
    if ([CNContactStore class]) {
        CNContactPickerViewController *picker = [[CNContactPickerViewController alloc] init];

        picker.delegate = self;
        picker.displayedPropertyKeys =
            [[NSArray alloc] initWithObjects:CNContactPostalAddressesKey, nil];
        ;
        picker.predicateForEnablingContact =
            [NSPredicate predicateWithFormat:@"postalAddresses.@count > 0"];
        picker.predicateForSelectionOfContact =
            [NSPredicate predicateWithFormat:@"postalAddresses.@count == 1"];

        [self presentViewController:picker animated:YES completion:nil];
    }
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableSectionRowFaves

BASIC_CELL_SELECT(kTableSectionRowFaves,
                  self.tripQuery.userFaves[indexPath.row].userParams.valChosenName,
                  kIconFave,
                  [self multipleStopsForFave:indexPath.row]
                      ? UITableViewCellAccessoryDisclosureIndicator
                      : UITableViewCellAccessoryNone) {
    UserParams *item = self.tripQuery.userFaves[indexPath.row].userParams;
    NSString *location = item.valLocation;

    if (![self multipleStopsForFave:indexPath.row]) {
        [self gotPlace:location setUiText:YES additionalInfo:item.valChosenName];
    } else {
        TripPlannerBookmarkViewController *bmView =
            [TripPlannerBookmarkViewController viewController];
        bmView.stopIdStringCallback = self;
        bmView.from = self.from;

        [bmView fetchNamesForStopIdsAsync:self.backgroundTask stopIds:location];
    }
}

//--------------------------------------------------------------------------------------------------
#pragma mark kTableSectionRowLocate

BASIC_CELL_SELECT(kTableSectionRowLocate,
                  self.from
                      ? NSLocalizedString(@"Start from current location (GPS)", @"main menu item")
                      : NSLocalizedString(@"Go to current location (GPS)", @"main menu item"),
                  kIconLocateMe,
                  UITableViewCellAccessoryNone) {
    [self initEndPoint];
    [self endPoint].useCurrentLocation = YES;
    self.placeNameField.text = @"";
    [self nextScreen];
}

//--------------------------------------------------------------------------------------------------
CELL_VTABLE_MAP{
    CELL_MAP(kTableEnterRowEnter),
    CELL_MAP(kTableEnterRowBrowse),
    CELL_MAP(kTableEnterRowRailMap),
    CELL_MAP(kTableEnterRowRailStations),
    CELL_MAP(kTableEnterRowContacts),
    CELL_MAP(kTableSectionRowFaves),
    CELL_MAP(kTableSectionRowLocate),
};

@end
