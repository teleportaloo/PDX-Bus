//
//  NearestVehiclesMap.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "NearestVehiclesMapViewController.h"
#import "CLLocation+Helper.h"
#import "DebugLogging.h"
#import "FormatDistance.h"
#import "KMLRoutes.h"
#import "MainQueueSync.h"
#import "NSString+MoreMarkup.h"
#import "RunParallelBlocks.h"
#import "ShapeRoutePath.h"
#import "SimpleAnnotation.h"
#import "StopDistance+iOSUI.h"
#import "TaskLocator.h"
#import "TaskState.h"
#import "TriMetInfo.h"
#import "UIApplication+Compat.h"
#import "UIFont+Utility.h"
#import "Vehicle+iOSUI.h"
#import "XMLLocateStops+iOSUI.h"
#import "XMLLocateVehicles.h"
#import "XMLStreetcarLocations.h"

#define DEBUG_LEVEL_FOR_FILE LogUI

#define kRefreshInterval 30

@interface NearestVehiclesMapViewController () {
    bool _timerPaused;
}

@property(nonatomic, strong) XMLLocateStops *stopLocator;
@property(nonatomic, strong) XMLLocateVehicles *locator;
@property(nonatomic, strong) HiddenTaskContainer *hiddenTaskContainer;

@property(nonatomic, strong) NSTimer *refreshTimer;
@property(nonatomic, strong) NSDate *lastRefresh;
@property(nonatomic, strong) UIBarButtonItem *refreshButton;
@property(nonatomic, strong) UILabel *updatedLabel;
@end

@implementation NearestVehiclesMapViewController

- (instancetype)init {
    if ((self = [super init])) {
        _timerPaused = NO;
        self.lineOptions = MapViewFitLines;
        self.defaultFitOption = MapViewFitLines;
    }

    return self;
}

- (void)dealloc {
    [self stopTimer];
}

- (void)timerFired:(NSTimer *)timer {
    [self stopTimer];
    [self setRefreshButtonText:NSLocalizedString(@"Refreshing",
                                                 @"Refresh button text")];
    [self refreshAction:timer];
    _timerPaused = YES;
}

- (void)countDownAction:(NSTimer *)timer {
    NSTimeInterval sinceRefresh = self.lastRefresh.timeIntervalSinceNow;

    bool updateTimeOnButton = YES;

    if (sinceRefresh <= -kRefreshInterval) {
        [self timerFired:timer];
        updateTimeOnButton = NO;
    }

    if (updateTimeOnButton) {
        int secs = (1 + kRefreshInterval + sinceRefresh);

        if (secs < 0) {
            secs = 0;
        }

        [self setRefreshButtonText:
                  [NSString stringWithFormat:
                                NSLocalizedString(
                                    @"Refresh in %d",
                                    @"Refresh button text {number of seconds}"),
                                secs]];

        [self countDownTimer];
    }
}

- (void)countDownTimer {
}

- (void)setRefreshButtonText:(NSString *)text {
    // iOS10 needs this as it will flash
    [UIView performWithoutAnimation:^{
      [self.refreshButton setTitle:text];
    }];
}

- (void)startTimer {
    self.lastRefresh = [NSDate date];
    [self oneSecondTimer];
}

- (void)oneSecondTimer {
    if (self.refreshTimer) {
        [self.refreshTimer invalidate];
    }

    __weak __typeof(self) weakSelf = self;

    self.refreshTimer = [NSTimer
        timerWithTimeInterval:1
                      repeats:YES
                        block:^(NSTimer *_Nonnull timer) {
                          __strong __typeof(self) strongSelf = weakSelf;
                          if (!strongSelf || strongSelf.refreshTimer == nil ||
                              !strongSelf.refreshTimer.valid) {
                              [timer invalidate];
                              if (strongSelf) {
                                  strongSelf.refreshTimer = nil;
                              }
                              return;
                          }
                          if (timer != self.refreshTimer) {
                              [timer invalidate];
                              return;
                          }

                          [strongSelf countDownAction:timer];
                        }];

    [[NSRunLoop currentRunLoop] addTimer:self.refreshTimer
                                 forMode:NSDefaultRunLoopMode];
}

- (void)stopTimer {
    if (self.refreshTimer != nil) {
        [self.refreshTimer invalidate];
        self.refreshTimer = nil;
        [self setRefreshButtonText:NSLocalizedString(@"Refresh",
                                                     @"Refresh button text")];
    }
}

- (void)pauseTimer {
    if (self.refreshTimer != nil) {
        [self.refreshTimer invalidate];
        self.refreshTimer = nil;
        _timerPaused = YES;
    }
}

- (void)didEnterBackground {
    [super didEnterBackground];
    [self stopTimer];
}

- (void)viewDidDisappear:(BOOL)animated {
    DEBUG_FUNC();
    [super viewDidDisappear:animated];
    [self stopTimer];
}

- (void)unpauseTimer {
    if (Settings.autoRefresh && _timerPaused) {
        DEBUG_LOG(@"restarting timer\n");
        [self oneSecondTimer];
        _timerPaused = NO;
    } else if (Settings.autoRefresh) {
        [self startTimer];
        _timerPaused = NO;
    }
}

- (void)didBecomeActive {
    DEBUG_FUNC();
    // [self unpauseTimer];
    [super didBecomeActive];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // self unpauseTimer];
}

- (bool)displayErrorIfNoneFound:(XMLLocateVehicles *)locator
                       progress:(id<TaskController>)progress {
    NSThread *thread = [NSThread currentThread];

    if (locator.noErrorAlerts) {
        return false;
    }

    if (locator.count == 0 && !locator.gotData) {
        if (!thread.cancelled) {
            [progress taskCancel];
            [progress
                taskSetErrorMsg:NSLocalizedString(
                                    @"Network problem: please try again later.",
                                    @"progress message")];

            return true;
        }
    } else if (locator.count == 0) {
        if (!thread.cancelled) {
            [progress taskCancel];

            [progress
                taskSetErrorMsg:
                    [NSString stringWithFormat:
                                  NSLocalizedString(
                                      @"No vehicles were found within %@, note "
                                      @"Streetcar is not supported.",
                                      @"error message"),
                                  [FormatDistance formatMetres:locator.dist]]];
            return true;
        }
    }

    return false;
}

- (void)subTaskCalculateInitialTotal:(bool)fetchVehicles
                        includeStops:(bool)includeStops
                           taskState:(TaskState *)taskState {
    taskState.total = 0;

    if (self.trimetRoutes == nil && fetchVehicles) {
        taskState.total++;
    } else if (self.trimetRoutes.count > 0 && fetchVehicles) {
        taskState.total++;
    }

    if (includeStops && !self.stopLocator.gotData) {
        taskState.total++;
    }
}

- (void)subTaskFetchShapes:(TaskState *)taskState rightNow:(bool)now {
    KMLRoutes *kml = [KMLRoutes xmlWithOneTimeDelegate:taskState];

    NSSet<NSString *> *all =
        [self.streetcarRoutes setByAddingObjectsFromSet:self.trimetRoutes];

    if (self.allRoutes) {
        if (now) {
            kml.oneTimeDelegate = taskState;
            [kml fetchNowForced:YES];
        } else {
            [kml fetchInBackgroundForced:NO];
        }
        self.shapes = [NSMutableArray array];
        for (NSString *key in kml.keyEnumerator) {
            ShapeRoutePath *path = [kml lineCoordsForKey:key];

            if (path) {
                [self.shapes addObject:path];
            }
        }
    } else {
        if (now) {
            kml.oneTimeDelegate = taskState;
            [kml fetchNowForced:YES];
        } else {
            [kml fetchInBackgroundForced:NO];
        }

        self.shapes = [NSMutableArray array];
        for (NSString *route in all) {
            if (self.direction) {
                ShapeRoutePath *path = [kml lineCoordsForRoute:route
                                                     direction:self.direction];

                if (path) {
                    [self.shapes addObject:path];
                }
            } else {
                ShapeRoutePath *path =
                    [kml lineCoordsForRoute:route direction:kKmlFirstDirection];

                if (path) {
                    [self.shapes addObject:path];
                }

                ShapeRoutePath *second =
                    [kml lineCoordsForRoute:route
                                  direction:kKmlOptionalDirection];

                if (second) {
                    [self.shapes addObject:second];
                }
            }

            [taskState incrementItemsDoneAndDisplay];
        }
    }

    [taskState incrementItemsDoneAndDisplay];
}

- (void)subTaskLocateTriMetVehicles:(XMLLocateVehicles *)locator
                               mode:(TripMode)mode
                          taskState:(TaskState *)taskState {
    locator.noErrorAlerts = YES;

    locator.oneTimeDelegate = taskState;
    [locator findNearestVehicles:self.trimetRoutes
                       direction:self.direction
                          blocks:nil
                        vehicles:nil
                           since:nil];
    XML_DEBUG_RAW_DATA(locator);

    [taskState incrementItemsDoneAndDisplay];

    @synchronized(self) {
        if (![self displayErrorIfNoneFound:locator progress:taskState]) {
            for (int i = 0; i < locator.count && !taskState.taskCancelled;
                 i++) {
                Vehicle *ui = locator.items[i];

                if ([ui typeMatchesMode:mode] &&
                    (self.stopLocator == nil ||
                     [ui.location
                         distanceFromLocation:self.stopLocator.location] <=
                         self.stopLocator.minDistance)) {
                    [self addPin:ui];
                }
            }
        }
    }
}

- (void)subTaskLocateStreetcarVehicles:
            (NSSet<NSString *> *)streetcarRoutesForVehicles
                             taskState:(TaskState *)taskState
                        parallelBlocks:(RunParallelBlocks *)parallelBlocks {
    for (NSString *route in streetcarRoutesForVehicles) {
        [parallelBlocks startBlock:^{
          XMLStreetcarLocations *loc =
              [XMLStreetcarLocations sharedInstanceForRoute:route];

          loc.oneTimeDelegate = taskState;
          [loc.locations removeAllObjects];
          [loc getLocations];

          @synchronized(self) {
              XML_DEBUG_RAW_DATA(loc);

              [taskState incrementItemsDoneAndDisplay];

              [loc.locations enumerateKeysAndObjectsUsingBlock:^(
                                 NSString *streecarId, Vehicle *vehicle,
                                 BOOL *stop) {
                if (self.direction == nil || vehicle.direction == nil ||
                    [vehicle.direction isEqualToString:self.direction]) {
                    if (self.stopLocator == nil ||
                        [vehicle.location
                            distanceFromLocation:self.stopLocator.location] <=
                            self.stopLocator.minDistance) {
                        [self addPin:vehicle];
                    }
                }
              }];
          }
        }];
    }
}

- (void)subTaskLocateStops:(TaskState *)taskState {
    self.stopLocator.oneTimeDelegate = taskState;
    [self.stopLocator findNearestStops];

    [taskState incrementItemsDoneAndDisplay];

    @synchronized(self) {
        if (![self.stopLocator displayErrorIfNoneFound:taskState]) {
            for (int i = 0;
                 i < self.stopLocator.count && !taskState.taskCancelled; i++) {
                [self addPin:self.stopLocator.items[i]];
            }

            self.staticAnnotations = self.annotations.copy;
        }
    }
}

- (void)fetchNearestVehicles:(XMLLocateVehicles *)locator
              taskController:(id<TaskController>)taskController
           backgroundRefresh:(bool)backgroundRefresh {
    [taskController taskRunAsync:^(TaskState *taskState) {
      self.backgroundRefresh = backgroundRefresh;
      XML_DEBUG_INIT();

      TripMode mode = TripModeAll;

      if (self.stopLocator) {
          mode = self.stopLocator.mode;
      }

      bool fetchVehicles = Settings.useVehicleLocator;
      bool includeStops = self.stopLocator != nil;

      [self subTaskCalculateInitialTotal:fetchVehicles
                            includeStops:includeStops
                               taskState:taskState];

      [taskState startTask:@"making Transit Map"];

      if (locator.location == nil) {
          taskState.total++;

          locator.location = [TaskLocator locateWithAccuracy:locator.dist
                                                   taskState:taskState];

          if (self.stopLocator) {
              self.stopLocator.location = locator.location;
          }
      }

      if (includeStops && !self.stopLocator.gotData) {
          [taskState startTask:@"searching for stops"];
          [self subTaskLocateStops:taskState];
      }

      if (self.stopLocator.includeRoutesInStops) {
          NSMutableSet *triMetRoutes = NSMutableSet.set;
          NSMutableSet *streetcarRoutes = NSMutableSet.set;

          for (StopDistance *stop in self.stopLocator.items) {
              for (Route *route in stop.routes) {
                  PtrConstRouteInfo info =
                      [TriMetInfo infoForRoute:route.routeId];

                  if (info && info->lineType == LineTypeStreetcar) {
                      [streetcarRoutes addObject:route.routeId];
                  } else {
                      [triMetRoutes addObject:route.routeId];
                  }
              }
          }

          self.trimetRoutes = triMetRoutes;
          self.streetcarRoutes = streetcarRoutes;
      }

      if (locator.location != nil) {
          RunParallelBlocks *parallelBlocks = [RunParallelBlocks instance];

          [taskState taskSubtext:@"getting vehicles"];

          if ((self.trimetRoutes == nil || self.trimetRoutes.count > 0) &&
              fetchVehicles) {
              taskState.total++;
              [parallelBlocks startBlock:^{
                [self subTaskLocateTriMetVehicles:locator
                                             mode:mode
                                        taskState:taskState];
              }];
          }

          if (self.streetcarRoutes.count > 0 && mode != TripModeBusOnly &&
              fetchVehicles) {
              taskState.total++;
              [self subTaskLocateStreetcarVehicles:self.streetcarRoutes
                                         taskState:taskState
                                    parallelBlocks:parallelBlocks];
          }

          [parallelBlocks waitForBlocksWithState:taskState];

          if ((self.allRoutes || self.trimetRoutes.count > 0 ||
               self.streetcarRoutes.count > 0) &&
              Settings.kmlRoutes) {

              [self subTaskFetchShapes:taskState rightNow:NO];
          }

          [taskState taskSubtext:@"drawing map"];

          [NSThread sleepForTimeInterval:0.1];
      }
      return (UIViewController *)self;
    }];
}

- (void)fetchNearestVehiclesAsync:(id<TaskController>)taskController {
    [self fetchNearestVehiclesAsync:taskController backgroundRefresh:NO];
}

- (void)fetchNearestVehiclesAsync:(id<TaskController>)taskController
                backgroundRefresh:(bool)backgroundRefresh {
    self.locator = [XMLLocateVehicles xml];

    CLLocation *here = nil;

    {
        CLLocationDegrees X0 = 45.255797;
        CLLocationDegrees X1 = 45.657207;
        CLLocationDegrees Y0 = -122.249926;
        CLLocationDegrees Y1 = -123.153522;

        CLLocationCoordinate2D triMetCenter = {(X0 + X1) / 2.0,
                                               (Y0 + Y1) / 2.0};

        here = [CLLocation withLat:triMetCenter.latitude
                               lng:triMetCenter.longitude];
    }

    self.locator.location = here;
    self.locator.dist = 0.0;

    if (Settings.useVehicleLocator || self.alwaysFetch) {
        [self fetchNearestVehicles:self.locator
                    taskController:taskController
                 backgroundRefresh:backgroundRefresh];
    } else {
        [taskController taskCompleted:self];
    }
}

- (void)removeAnnotations {
    NSArray *annotions = self.mapView.annotations;

    for (id<MapPin> annot in annotions) {
        if ([annot isKindOfClass:[Vehicle class]]) {
            [self.mapView removeAnnotation:annot];
        }
    }
}

- (void)hiddenTaskStarted {
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)hiddenTaskDone:(UIViewController *)viewController
             cancelled:(bool)cancelled {
    self.hiddenTaskContainer = nil;
    self.navigationItem.rightBarButtonItem.enabled = YES;

    if (!cancelled) {
        [self addDataToMap:NO animate:YES];
    }

    if (self.backgroundRefresh && !cancelled && _timerPaused) {
        _timerPaused = NO;
        [self startTimer];
    }

    self.backgroundRefresh = false;
}

- (void)addDataToMap:(bool)zoom animate:(bool)animate {
    [super addDataToMap:zoom animate:animate];

    NSDateFormatter *dateFormatter = [NSDateFormatter new];

    dateFormatter.dateStyle = NSDateFormatterNoStyle;
    dateFormatter.timeStyle = NSDateFormatterMediumStyle;

    NSDate *updated = self.locator.httpDate;

    if (updated == nil) {
        updated = [NSDate date];
    }

    NSString *timeStr = [dateFormatter stringFromDate:updated];

    NSAttributedString *text =
        [NSString stringWithFormat:@"Updated: #U%@", timeStr]
            .smallAttributedStringFromMarkUp;

    self.updatedLabel.attributedText = text;
    self.updatedLabel.frame = self.updateLabelFrame;
    [self.view bringSubviewToFront:self.updatedLabel];
}

- (void)refreshAction:(id)unused {
    if (!self.backgroundRefresh && self.hiddenTaskContainer == nil) {
        // [self removeAnnotations];

        self.hiddenTaskContainer = [[HiddenTaskContainer alloc] init];

        self.hiddenTaskContainer.hiddenTaskCallback = self;

        [self.annotations removeAllObjects];

        [self fetchNearestVehiclesAsync:self.hiddenTaskContainer
                      backgroundRefresh:YES];
    }
}

- (CGRect)updateLabelFrame {
    CGFloat inset = UIApplication.firstKeyWindow.safeAreaInsets.bottom;

    const CGSize size = [self.updatedLabel.attributedText size];

    CGFloat toolbarHeight = self.navigationController.toolbar.frame.size.height;
    CGRect bounds = self.view.frame;

    DEBUG_LOG(@"bounds %f, %f, %f, %f\n", bounds.origin.x, bounds.origin.y,
              bounds.size.width, bounds.size.height);
    DEBUG_LOG(@"inset %f\n", inset);
    DEBUG_LOG(@"tb height  %f\n", toolbarHeight);

#define kLabelMargin 5

    CGFloat labelHeight = size.height + kLabelMargin * 2;

    CGRect rect = CGRectMake(kLabelMargin + CGRectGetMinX(bounds),
                             CGRectGetMinY(bounds) + CGRectGetHeight(bounds) -
                                 labelHeight - toolbarHeight - inset,
                             size.width + kLabelMargin * 2, labelHeight);

    self.updatedLabel.frame = rect;

    return rect;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    self.updatedLabel.frame = self.updateLabelFrame;
    [self.view bringSubviewToFront:self.updatedLabel];
}

- (void)buttonRefreshAction:(id)unused {
    [self timerFired:nil];
}

- (void)updateRoutePaths {
    KMLRoutes *routes = [KMLRoutes xml];

    if (!routes.backgroundFetching) {
        Settings.rawKmlRoutes = kKmlMonthly;
        self.lineOptions = self.defaultFitOption;

        [self.backgroundTask taskRunAsync:^(TaskState *taskState) {
          taskState.total = 2;
          [taskState startTask:NSLocalizedString(@"Downloading route paths",
                                                 @"alert item")];

          [self subTaskFetchShapes:taskState rightNow:YES];

          [taskState decrementTotalAndDisplay];

          [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
            DEBUG_LOG(@"Updating polys");
            [self removeOverlays];
            [self addDataToMap:NO animate:NO];
            DEBUG_LOG(@"Done");
          }];

          [taskState decrementTotalAndDisplay];

          return (UIViewController *)nil;
        }];
    }
}

- (void)updateTapped {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:NSLocalizedString(@"Transit Map Options",
                                                   @"alert title")
                         message:NSLocalizedString(
                                     @"Route paths can be shown. Route paths "
                                     @"will be updated monthly.",
                                     "alert message")
                  preferredStyle:UIAlertControllerStyleActionSheet];

    if (Settings.kmlRoutes && self.lineOptions == MapViewNoLines) {
        [alert
            addAction:[UIAlertAction
                          actionWithTitle:NSLocalizedString(@"Show route paths",
                                                            @"alert item")
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *action) {
                                    self.lineOptions = self.defaultFitOption;
                                    [self updateOverlays];
                                  }]];
    }

    if (Settings.kmlRoutes && self.lineOptions != MapViewNoLines) {
        [alert
            addAction:[UIAlertAction
                          actionWithTitle:NSLocalizedString(@"Hide route paths",
                                                            @"alert item")
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *action) {
                                    self.lineOptions = MapViewNoLines;
                                    [self updateOverlays];
                                  }]];
    }

    if (Settings.kmlRoutes) {
        [alert
            addAction:[UIAlertAction actionWithTitle:NSLocalizedString(
                                                         @"Update route paths",
                                                         @"alert item")
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
                                               [self updateRoutePaths];
                                               [self updateOverlays];
                                             }]];

        [alert addAction:[UIAlertAction
                             actionWithTitle:
                                 NSLocalizedString(
                                     @"Delete route paths and stop updates",
                                     @"alert item")
                                       style:UIAlertActionStyleDestructive
                                     handler:^(UIAlertAction *action) {
                                       self.lineOptions = MapViewNoLines;
                                       Settings.rawKmlRoutes = kKmlNever;
                                       [KMLRoutes deleteCacheFile];
                                       [self updateOverlays];
                                     }]];
    }

    if (!Settings.kmlRoutes) {
        [alert addAction:[UIAlertAction
                             actionWithTitle:NSLocalizedString(
                                                 @"Download route paths",
                                                 @"alert item")
                                       style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction *action) {
                                       [self updateRoutePaths];
                                     }]];
    }

    [alert addAction:[UIAlertAction
                         actionWithTitle:NSLocalizedString(@"Cancel",
                                                           @"alert item")
                                   style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction *action){
                                 }]];

    alert.popoverPresentationController.sourceView = self.view;
    alert.popoverPresentationController.sourceRect = self.updatedLabel.frame;

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)viewDidLoad {
    CGRect rect = CGRectNull;

    self.updatedLabel = [[UILabel alloc] initWithFrame:rect];

    self.updatedLabel.textAlignment = NSTextAlignmentCenter;
    self.updatedLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;

    self.updatedLabel.adjustsFontSizeToFitWidth = YES;

    self.updatedLabel.layer.borderWidth = 1.0;
    self.updatedLabel.layer.cornerRadius = 8;
    self.updatedLabel.layer.masksToBounds = YES;

    self.updatedLabel.textColor = [UIColor labelColor];
    self.updatedLabel.backgroundColor = [UIColor tertiarySystemBackgroundColor];

    UITapGestureRecognizer *tapGestureRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(updateTapped)];

    tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.updatedLabel addGestureRecognizer:tapGestureRecognizer];
    self.updatedLabel.userInteractionEnabled = YES;

    [self.view addSubview:self.updatedLabel];
    [self.view bringSubviewToFront:self.updatedLabel];

    [super viewDidLoad];

    if (Settings.useVehicleLocator || self.alwaysFetch) {
        self.refreshButton = [[UIBarButtonItem alloc]
            initWithTitle:NSLocalizedString(@"Refresh", @"text")
                    style:UIBarButtonItemStylePlain
                   target:self
                   action:@selector(buttonRefreshAction:)];
        self.navigationItem.rightBarButtonItem = self.refreshButton;

        NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
        paragraphStyle.alignment = NSTextAlignmentRight;

        [self.refreshButton setTitleTextAttributes:@{
            NSFontAttributeName :
                [UIFont monospacedDigitSystemFontOfSize:UIFont.labelFontSize],
            NSParagraphStyleAttributeName : paragraphStyle
        }
                                          forState:UIControlStateNormal];
    }

    // Uncomment the following line to display an Edit button in the
    // navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (bool)hasXML {
    return YES;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.

    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

- (void)fetchNearestVehiclesAndStopsAsync:(id<TaskController>)taskController
                                 location:(CLLocation *)here
                                maxToFind:(int)max
                              minDistance:(double)min
                                     mode:(TripMode)mode {
    self.stopLocator = [XMLLocateStops xml];
    self.stopLocator.includeRoutesInStops = YES;
    self.lineOptions = MapViewNoFitLines;
    self.defaultFitOption = MapViewNoFitLines;

    self.locator = [XMLLocateVehicles xml];
    self.locator.location = here;
    self.locator.dist = min;

    self.stopLocator.maxToFind = max;
    self.stopLocator.location = here;
    self.stopLocator.mode = mode;
    self.stopLocator.minDistance = min;

    [self fetchNearestVehicles:self.locator
                taskController:taskController
             backgroundRefresh:NO];
}

@end
