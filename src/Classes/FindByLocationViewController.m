//
//  FindByLocationViewController.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "FindByLocationViewController.h"
#import "BackgroundTaskContainer.h"
#import "BearingAnnotationView.h"
#import "DebugLogging.h"
#import "DepartureTimesViewController.h"
#import "Icons.h"
#import "NSString+MoreMarkup.h"
#import "NearestRoutesViewController.h"
#import "NearestVehiclesMapViewController.h"
#import "RootViewController.h"
#import "SegmentCell.h"
#import "SimpleAnnotation.h"
#import "StopDistance.h"
#import "TaskDispatch.h"
#import "TextViewLinkCell.h"
#import "TripPlannerEndPointViewController.h"
#import "UITableViewCell+Icons.h"
#import "UIViewController+LocationAuthorization.h"
#import "UserInfo.h"
#import "UserParams.h"
#import <Intents/Intents.h>

enum SECTIONS_AND_ROWS {
    kGpsLocateSection,
    kNoGpsLocateSection,
    kDistanceSection,
    kModeSection,
    kShowSection,
    kAutoSection,
    kNoteSection,
    kMapSection,
    kSiriSection
};

enum { kShowArrivals = 0, kShowMap, kShowRoute };

enum {
    kDistanceNextToMe = 0,
    kDistanceHalfMile,
    kDistanceMile,
    kDistance3Miles
};

enum { kAutoAsk = 0, kAutoPrevious };

#define kHelpText                                                              \
    @"\nNote: Using previous settings chosen in 'Locate nearby stops' main "   \
    @"menu."

@interface FindByLocationViewController () {
    int _maxToFind;
    int _maxRouteCount;
    TripMode _mode;
    int _show;
    int _dist;
    double _minMetres;
    int _routeCount;
    int _firstDisplay;
    bool _locationAuthorized;
}

@property(nonatomic, strong) NSArray *cachedRoutes;
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, NSNumber *> *lastLocate;
@property(nonatomic) int autoLaunch;
@property(nonatomic, copy) NSString *startingLocationName;
@property(nonatomic, strong) CLLocation *startingLocation;
@property(nonatomic, strong) MKCircle *circle;
@property(nonatomic, strong) NSTimer *mapUpdateTimer;
@property(nonatomic, strong) NSUserActivity *userActivity;

- (void)distSegmentChanged:(id)sender;
- (void)modeSegmentChanged:(id)sender;
- (void)showSegmentChanged:(id)sender;

@end

@implementation FindByLocationViewController

// @synthesize progressText = _progressText;

- (instancetype)initWithLocation:(CLLocation *)location
                     description:(NSString *)locationName {
    if ((self = [super init])) {
        [self basicInit];

        self.startingLocation = location;
        self.startingLocationName = locationName;

        [self clearSectionMaps];
        [self addSectionType:kNoGpsLocateSection];
        [self addRowType:kNoGpsLocateSection];

        [self addSectionType:kDistanceSection];
        [self addRowType:kDistanceSection];
        [self addRowType:kMapSection];

        [self addSectionType:kModeSection];
        [self addRowType:kModeSection];

        [self addSectionType:kShowSection];
        [self addRowType:kShowSection];

        [self addSectionType:kNoteSection];
        [self addRowType:kNoteSection];
    }

    return self;
}

- (instancetype)init {
    if ((self = [super init])) {
        [self basicInit];

        [self clearSectionMaps];

        [self addSectionType:kGpsLocateSection];
        [self addRowType:kGpsLocateSection];

        [self addSectionType:kDistanceSection];
        [self addRowType:kDistanceSection];
        [self addRowType:kMapSection];

        [self addSectionType:kModeSection];
        [self addRowType:kModeSection];

        [self addSectionType:kShowSection];
        [self addRowType:kShowSection];

#if !TARGET_OS_MACCATALYST
        [self addSectionType:kSiriSection];
        [self addRowType:kSiriSection];
#endif

        [self addSectionType:kAutoSection];
        [self addRowType:kAutoSection];

        [self addSectionType:kNoteSection];
        [self addRowType:kNoteSection];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[TextViewLinkCell nib]
         forCellReuseIdentifier:MakeCellId(kNoteSection)];

    self.tableView.estimatedRowHeight = self.basicRowHeight;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)dealloc {
    if (_userActivity) {
        [_userActivity invalidate];
    }

    if (_mapUpdateTimer) {
        [_mapUpdateTimer invalidate];
    }
}

- (void)basicInit {
    self.title = NSLocalizedString(@"Locate Stops", @"page title");
    _maxRouteCount = 1;
    _mode = TripModeAll;
    _dist = kDistanceHalfMile;
    _show = kShowArrivals;
    _firstDisplay = YES;

    self.lastLocate = _userState.lastLocate;

    if (self.lastLocate != nil) {
        UserParams *params = self.lastLocate.userParams;
        _mode = params.valLocateMode;
        _show = params.valLocateShow;
        _dist = params.valLocateDist;
    }
}

static NSDictionary<NSString *, NSNumber *> *dist_map;
static NSDictionary<NSString *, NSNumber *> *mode_map;
static NSDictionary<NSString *, NSNumber *> *show_map;
static NSDictionary<NSNumber *, NSString *> *ui_mmap;
static NSDictionary<NSNumber *, NSString *> *ui_dmap;
static NSDictionary<NSNumber *, NSString *> *ui_smap;

- (void)initMappings {
    DoOnce((^{
      show_map = @{
          @"Arrivals" : @(kShowArrivals),
          @"arrivals" : @(kShowArrivals),
          @"Departures" : @(kShowArrivals),
          @"departures" : @(kShowArrivals),
          @"map" : @(kShowMap),
          @"Map" : @(kShowMap),
          @"routes" : @(kShowRoute),
          @"Routes" : @(kShowRoute)
      };

      ui_smap = @{
          @(kShowArrivals) : NSLocalizedString(@"Departures", @"screen type"),
          @(kShowMap) : NSLocalizedString(@"Map", @"screen type"),
          @(kShowRoute) : NSLocalizedString(@"Routes", @"screen type")
      };

      dist_map = @{
          @"closest" : @(kDistanceNextToMe),
          @"Closest" : @(kDistanceNextToMe),
          @"0.5" : @(kDistanceHalfMile),
          @"1" : @(kDistanceMile),
          @"3" : @(kDistance3Miles)
      };

      ui_dmap = @{
          @(kDistanceNextToMe) :
              NSLocalizedString(@"that are nearby", @"location distance"),
          @(kDistanceHalfMile) : NSLocalizedString(@"that are within ½ mile",
                                                   @"location distance"),
          @(kDistanceMile) : NSLocalizedString(@"that are within 1 mile",
                                               @"location distance"),
          @(kDistance3Miles) : NSLocalizedString(@"that are within 3 miles",
                                                 @"location distance")
      };

      mode_map = @{
          @"Bus" : @(TripModeBusOnly),
          @"bus" : @(TripModeBusOnly),
          @"Busses" : @(TripModeBusOnly),
          @"busses" : @(TripModeBusOnly),
          @"Buses" : @(TripModeBusOnly),
          @"buses" : @(TripModeBusOnly),
          @"Train" : @(TripModeTrainOnly),
          @"train" : @(TripModeTrainOnly),
          @"Trains" : @(TripModeTrainOnly),
          @"trains" : @(TripModeTrainOnly),
          @"both" : @(TripModeAll),
          @"Both" : @(TripModeAll),
          @"BusAndTrain" : @(TripModeAll),
          @"busandtrain" : @(TripModeAll),
          @"BussesAndTrains" : @(TripModeAll),
          @"bussesandtrains" : @(TripModeAll),
          @"BusesAndTrains" : @(TripModeAll),
          @"busesandtrains" : @(TripModeAll)
      };

      ui_mmap = @{
          @(TripModeBusOnly) : @"bus stops",
          @(TripModeTrainOnly) : @"train stations",
          @(TripModeAll) : @"bus stops and stations"
      };
    }));
}

+ (NSString *)mapValue:(NSInteger)value
                    in:(NSDictionary<NSString *, NSNumber *> *)dict {
    __block NSString *found = @"";

    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key,
                                              NSNumber *_Nonnull obj,
                                              BOOL *_Nonnull stop) {
      if (obj.integerValue == value) {
          found = key;
          *stop = YES;
      }
    }];

    return found;
}

#define MAP_TO_INT(V, A, M)                                                    \
    {                                                                          \
        NSString *str = (A);                                                   \
        if (str != nil) {                                                      \
            NSNumber *num = (M)[str];                                          \
            if (num) {                                                         \
                V = num.intValue;                                              \
            }                                                                  \
        }                                                                      \
    }

- (void)actionArgs:(NSDictionary *)args {
    [self initMappings];

    _autoLaunch = YES;

    UserInfo *info = args.userInfo;

    MAP_TO_INT(_dist, info.valDist, dist_map);
    MAP_TO_INT(_mode, info.valMode, mode_map);
    MAP_TO_INT(_show, info.valShow, show_map);
}

- (instancetype)initAutoLaunch {
    _autoLaunch = YES;

    return [self init];
}

- (void)setDistance {
    switch (_dist) {
    case kDistanceNextToMe:
        _minMetres = kMetresNextToMe;
        _maxToFind = kMaxStops;
        break;

    case kDistanceHalfMile:
        _minMetres = kMetresHalfMile;
        _maxToFind = kMaxStops;
        break;

    case kDistanceMile:
        _minMetres = kMetresInAMile;
        _maxToFind = kMaxStops;
        break;

    case kDistance3Miles:
        _minMetres = MetresForMiles(3);
        _maxToFind = kMaxStops;
        break;
    }
}

+ (NSDictionary *)nearbyArrivalInfo {
    MutableUserInfo *info = MutableUserInfo.new;

    info.valMode = [FindByLocationViewController mapValue:TripModeAll
                                                       in:mode_map];

    info.valShow = [FindByLocationViewController mapValue:kShowArrivals
                                                       in:show_map];

    info.valDist = [FindByLocationViewController mapValue:kDistanceHalfMile
                                                       in:dist_map];

    return info.dictionary;
}

- (void)createUserActivity {
    if (self.userActivity != nil) {
        [self.userActivity invalidate];
    }

    self.userActivity = [[NSUserActivity alloc]
        initWithActivityType:kHandoffUserActivityLocation];

    MutableUserInfo *info = MutableUserInfo.new;

    [self initMappings];

    info.valMode = [FindByLocationViewController mapValue:_mode in:mode_map];
    info.valShow = [FindByLocationViewController mapValue:_show in:show_map];
    info.valDist = [FindByLocationViewController mapValue:_dist in:dist_map];

    self.userActivity.eligibleForSearch = YES;
    self.userActivity.eligibleForPrediction = YES;

    self.userActivity.title =
        [NSString stringWithFormat:@"Launch PDX Bus & show %@ for %@ %@",
                                   ui_smap[@(_show)], ui_mmap[@(_mode)],
                                   ui_dmap[@(_dist)]];

    self.userActivity.userInfo = info.dictionary;
    [self.userActivity becomeCurrent];
}

#pragma mark TableViewWithToolbar methods

- (void)resetButton:(id)unused {
    _mode = TripModeAll;
    _show = kShowArrivals;
    _dist = kDistanceHalfMile;
    Settings.autoLocateShowOptions = YES;
    [self reloadData];
}

- (void)locateButton:(id)unused {
    if (self.startingLocation) {
        [self setDistance];
        [self searchAndDisplay:self.backgroundTask
                      location:self.startingLocation];
    } else {
        [self searchAndDisplay:self.backgroundTask location:nil];
    }
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {

    UIBarButtonItem *locateButton = [[UIBarButtonItem alloc]
        initWithImage:[UIImage systemImageNamed:self.startingLocation
                                                    ? kSFIconLocateNearby
                                                    : kSFIconLocateNow]
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(locateButton:)];

    [toolbarItems addObject:locateButton];

    [toolbarItems addObject:UIToolbar.flexSpace];

    UIBarButtonItem *resetButton = [[UIBarButtonItem alloc]
        initWithTitle:NSLocalizedString(@"Reset", @"button text")
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(resetButton:)];

    [toolbarItems addObject:resetButton];
}

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

#pragma mark UI Helper functions

- (void)backButton:(id)sender {
    [super backButton:sender];
}

- (void)searchAndDisplay:(BackgroundTaskContainer *)background
                location:(CLLocation *)here {

    if (_autoLaunch && _firstDisplay) {
        background.help = kHelpText;
    } else {
        background.help = nil;
    }

    switch (_show) {
    case kShowMap: {
        NearestVehiclesMapViewController *mapView =
            [NearestVehiclesMapViewController viewController];

        [mapView fetchNearestVehiclesAndStopsAsync:background
                                          location:here
                                         maxToFind:_maxToFind
                                       minDistance:_minMetres
                                              mode:_mode];

        break;
    }

    case kShowRoute: {
        [[NearestRoutesViewController viewController]
            fetchNearestRoutesAsync:background
                           location:here
                          maxToFind:_maxToFind
                        minDistance:_minMetres
                               mode:_mode];
        break;
    }

    case kShowArrivals: {
        [[DepartureTimesViewController viewController]
            fetchTimesForNearestStopsAsync:background
                                  location:here
                                 maxToFind:_maxToFind
                               minDistance:_minMetres
                                      mode:_mode];
        break;
    }
    }
}

#pragma mark Segment Controls

- (void)modeSegmentChanged:(UISegmentedControl *)sender {
    _mode = (TripMode)sender.selectedSegmentIndex;
}

- (void)showSegmentChanged:(UISegmentedControl *)sender {
    _show = (int)sender.selectedSegmentIndex;
}

- (void)distSegmentChanged:(UISegmentedControl *)sender {
    _dist = (int)sender.selectedSegmentIndex;
    [self setDistance];
    [self updateCircle];
}

- (void)autoSegmentChanged:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
    case kAutoAsk:
        Settings.autoLocateShowOptions = YES;
        break;

    default:
    case kAutoPrevious:
        Settings.autoLocateShowOptions = NO;
        break;
    }
}

#pragma mark TableViewWithToolbar methods

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
    switch ([self sectionType:section]) {
    case kDistanceSection:
        return NSLocalizedString(@"Search radius:", @"Section title");

    case kModeSection:
        return NSLocalizedString(@"Mode of travel:", @"Section title");

    case kShowSection:
        return NSLocalizedString(@"Show:", @"Section title");

    case kNoteSection:
        return nil;

    case kAutoSection:
        return NSLocalizedString(
            @"Choose what happens when you touch the locate toolbar icon from "
            @"the main screen.  It can either:",
            @"Section title");

    case kSiriSection:
        return NSLocalizedString(@"Add to Siri", @"Section title");

    case kGpsLocateSection:
        return nil; // [NSString stringWithFormat:@"Choosing 'Arrivals' will
                    // show a maximum of %d stops.", kMaxStops];

    case kNoGpsLocateSection:
        return self.startingLocationName;
    }
    return nil;
}

#define kUIProgressBarWidth 240.0
#define kUIProgressBarHeight 10.0
#define kRowHeight 40.0

#define kRowWidth 300.0

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result = UITableViewAutomaticDimension;

    switch ([self rowType:indexPath]) {
    case kDistanceSection:
    case kModeSection:
    case kShowSection:
    case kAutoSection:
        result = SegmentCell.rowHeight;
        break;
    case kNoteSection:
        result = UITableViewAutomaticDimension;
        break;
    case kGpsLocateSection:
    case kNoGpsLocateSection:
    case kSiriSection:
        result = [self basicRowHeight];
        break;

    case kMapSection:
        result = self.mapCellHeight;
        break;
    }
    return result;
}

- (void)updateCircle {
    if (self.mapView) {
        [self setDistance];

        if (self.circle) {
            [self.mapView removeOverlay:self.circle];
            self.circle = nil;
        }

        if (self.startingLocation != nil) {
            self.circle = [MKCircle
                circleWithCenterCoordinate:self.startingLocation.coordinate
                                    radius:_minMetres];
        } else if (self.mapView.userLocation != nil) {
            self.circle =
                [MKCircle circleWithCenterCoordinate:self.mapView.userLocation
                                                         .location.coordinate
                                              radius:_minMetres];
        }

        self.mapView.delegate = self;

        [self.mapView addOverlay:self.circle];

        MKMapRect flyTo = MKMapRectNull;
        // MKMapPoint annotationPoint =
        // MKMapPointForCoordinate(self.startingLocation.coordinate);

        flyTo = self.circle.boundingMapRect;

        UIEdgeInsets insets = {5, 5, 5, 5};

        [self.mapView setVisibleMapRect:[self.mapView mapRectThatFits:flyTo
                                                          edgePadding:insets]
                               animated:YES];
    }

    bool newAuthorization =
        [UIViewController locationAuthorizedOrNotDeterminedWithBackground:NO];

    if (newAuthorization != _locationAuthorized) {
        _locationAuthorized = newAuthorization;

        NSIndexPath *locIndex =
            [self firstIndexPathOfSectionType:kGpsLocateSection
                                      rowType:kGpsLocateSection];

        if (locIndex) {
            [self.tableView reloadRowsAtIndexPaths:@[ locIndex ]
                                  withRowAnimation:NO];
        }
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id<MKOverlay>)overlay {
    if (overlay == self.circle) {
        MKCircleRenderer *circleView =
            [[MKCircleRenderer alloc] initWithCircle:overlay];
        circleView.strokeColor = [UIColor greenColor];
        circleView.lineWidth = 3.0;
        return circleView;
    }

    // Can't reurn nil so make a dummy one
    return [[MKCircleRenderer alloc]
        initWithCircle:[MKCircle circleWithMapRect:MKMapRectNull]];
}

- (void)startCircleTimer {
    if (!self.startingLocation && self.mapView && self.mapUpdateTimer == nil) {
        __weak __typeof(self) weakSelf = self;

        self.mapUpdateTimer = [NSTimer
            timerWithTimeInterval:1
                          repeats:YES
                            block:^(NSTimer *_Nonnull timer) {
                              __strong __typeof(self) strongSelf = weakSelf;
                              if (!strongSelf ||
                                  strongSelf.mapUpdateTimer == nil ||
                                  !strongSelf.mapUpdateTimer.valid) {
                                  [timer invalidate];
                                  if (strongSelf) {
                                      strongSelf.mapUpdateTimer = nil;
                                  }
                                  return;
                              }
                              if (timer != self.mapUpdateTimer) {
                                  [timer invalidate];
                                  return;
                              }

                              [strongSelf updateCircle];
                            }];

        [[NSRunLoop currentRunLoop] addTimer:self.mapUpdateTimer
                                     forMode:NSDefaultRunLoopMode];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DEBUG_LOG(@"Requesting cell for ip %ld %ld\n", (long)indexPath.section,
              (long)indexPath.row);

    switch ([self rowType:indexPath]) {
    case kDistanceSection: {
        return [SegmentCell
                  tableView:tableView
            reuseIdentifier:MakeCellId(kDistanceSection)
            cellWithContent:@[
                NSLocalizedString(@"Closest", @"Short segment button text"),
                NSLocalizedString(@"½ mile", @"Short segment button text"),
                NSLocalizedString(@"1 mile", @"Short segment button text"),
                NSLocalizedString(@"3 miles", @"Short segment button text")
            ]
                     target:self
                     action:@selector(distSegmentChanged:)
              selectedIndex:_dist];
    }

    case kShowSection: {
        return [SegmentCell
                  tableView:tableView
            reuseIdentifier:MakeCellId(kShowSection)
            cellWithContent:@[
                NSLocalizedString(@"Departures", @"Short segment button text"),
                NSLocalizedString(@"Map", @"Short segment button text"),
                NSLocalizedString(@"Routes", @"Short segment button text")
            ]
                     target:self
                     action:@selector(showSegmentChanged:)
              selectedIndex:_show];
    }

    case kModeSection: {
        return [SegmentCell
                  tableView:tableView
            reuseIdentifier:MakeCellId(kModeSection)
            cellWithContent:@[
                NSLocalizedString(@"Bus only", @"Short segment button text"),
                NSLocalizedString(@"Rail only", @"Short segment button text"),
                NSLocalizedString(@"Bus or Rail",
                                  @"Short segment button text")
            ]
                     target:self
                     action:@selector(modeSegmentChanged:)
              selectedIndex:_mode];
    }

    case kAutoSection: {
        SegmentCell *cell = [SegmentCell
                  tableView:tableView
            reuseIdentifier:MakeCellId(kAutoSection)
            cellWithContent:@[
                NSLocalizedString(@"Show this page",
                                  @"Short segment button text"),
                NSLocalizedString(@"Show results",
                                  @"Short segment button text")
            ]
                     target:self
                     action:@selector(autoSegmentChanged:)
              selectedIndex:Settings.autoLocateShowOptions ? kAutoAsk
                                                           : kAutoPrevious];

        cell.systemIcon = kSFIconLocateMe;
        [cell layoutSubviews];
        return cell;
    }

    case kSiriSection: {
        UITableViewCell *cell = [self tableView:tableView
                        cellWithReuseIdentifier:MakeCellId(kSiriSection)];

        cell.textLabel.text = NSLocalizedString(@"Add to Siri", @"Button text");
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        cell.namedIcon = kIconSiri;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = self.basicFont;

        [self updateAccessibility:cell];
        return cell;
    }

    case kGpsLocateSection: {
        UITableViewCell *cell = [self tableView:tableView
                        cellWithReuseIdentifier:MakeCellId(kGpsLocateSection)];

        if ([UIViewController
                locationAuthorizedOrNotDeterminedWithBackground:NO]) {
            cell.textLabel.text =
                NSLocalizedString(@"Start locating", @"Button text");
        } else {
            cell.textLabel.text = NSLocalizedString(
                @"Current location not authorized", @"Button text");
        }

        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        cell.imageView.image = [UIImage systemImageNamed:kSFIconLocateNow];

        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = self.basicFont;

        [self updateAccessibility:cell];
        return cell;
    }

    case kNoGpsLocateSection: {
        UITableViewCell *cell =
            [self tableView:tableView
                cellWithReuseIdentifier:MakeCellId(kNoGpsLocateSection)];
        cell.textLabel.text =
            NSLocalizedString(@"Find nearby stops", @"Button text");
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        cell.imageView.image = [UIImage systemImageNamed:kSFIconLocateNearby];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = self.basicFont;

        [self updateAccessibility:cell];
        return cell;
    }
    case kNoteSection: {
        TextViewLinkCell *cell = [self.tableView
            dequeueReusableCellWithIdentifier:MakeCellId(kNoteSection)];

        NSString *info = @"";

        if (self.startingLocation == nil) {
            info = NSLocalizedString(@"Note: This page is always shown when "
                                     @"'Locate nearby stops' is "
                                     @"selected from the main list.\n\n",
                                     @"Page note");
        }

        cell.textView.attributedText =
            [NSString stringWithFormat:
                          NSLocalizedString(
                              @"%@#bOnly "
                              @"the closest #U%ld#D stops will be displayed.#b",
                              @"Page note"),
                          info, (long)kMaxStops]
                .smallAttributedStringFromMarkUp;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }

    case kMapSection: {
        UITableViewCell *cell = [self
                  getMapCell:MakeCellId(kMapSection)
            withUserLocation:YES
                  completion:^(MKMapView *map) {
                    if (self.startingLocation) {
                        SimpleAnnotation *annotLoc =
                            [SimpleAnnotation annotation];

                        annotLoc.pinTitle = self.startingLocationName;
                        annotLoc.pinColor = MAP_PIN_COLOR_RED;
                        annotLoc.coordinate = self.startingLocation.coordinate;

                        [self.mapView addAnnotation:annotLoc];
                    }

                    [self startCircleTimer];
                    [self updateCircle];
                  }];
        return cell;
    }
    }

    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)addToSiri {
    [self createUserActivity];
    INShortcut *shortCut =
        [[INShortcut alloc] initWithUserActivity:self.userActivity];

    INUIAddVoiceShortcutViewController *viewController =
        [[INUIAddVoiceShortcutViewController alloc] initWithShortcut:shortCut];
    viewController.modalPresentationStyle = UIModalPresentationFormSheet;
    viewController.delegate = self;

    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self sectionType:indexPath.section]) {
    case kSiriSection:
        [self addToSiri];
        break;

    case kGpsLocateSection:
        // [self startLocating];
        [self searchAndDisplay:self.backgroundTask location:nil];
        break;

    case kNoGpsLocateSection:
        [self setDistance];
        [self searchAndDisplay:self.backgroundTask
                      location:self.startingLocation];
        break;
    }
}

- (void)tableView:(UITableView *)tableView
      willDisplayCell:(UITableViewCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView
          willDisplayCell:cell
        forRowAtIndexPath:indexPath];

    if ([cell.reuseIdentifier isEqualToString:MakeCellId(kGpsLocateSection)]) {
        if (![UIViewController
                locationAuthorizedOrNotDeterminedWithBackground:NO]) {
            cell.backgroundColor = [UIColor redColor];
        }
    }
}

#pragma mark View methods

- (void)viewWillDisappear:(BOOL)animated {
    // if (!_autoLaunch)
    {
        MutableUserParams *params = MutableUserParams.new;

        params.valLocateMode = _mode;
        params.valLocateDist = _dist;
        params.valLocateShow = _show;
        self.lastLocate = params.mutableDictionary;

        _userState.lastLocate = self.lastLocate;
    }

    if (self.mapUpdateTimer) {
        [self.mapUpdateTimer invalidate];
        self.mapUpdateTimer = nil;
    }

    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (self.mapView) {
        self.mapView.delegate = self;
    }

    bool authorized = YES;

    if (self.startingLocation == nil) {
        authorized =
            [self locationAuthorizedOrNotDeterminedAlertWithBackground:NO];
    }

    if (_autoLaunch && _firstDisplay && authorized) {
        [self searchAndDisplay:self.backgroundTask location:nil];
        _firstDisplay = NO;
    } else {
        [self startCircleTimer];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)didTapMap:(id)sender {
    [self updateCircle];
}

@end
