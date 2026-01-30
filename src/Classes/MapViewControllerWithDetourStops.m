//
//  MapViewControllerWithDetourStops.m
//  PDX Bus
//
//  Created by Andrew Wallace on 3/6/14.
//  Copyright (c) 2014 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapViewControllerWithDetourStops.h"
#import "DebugLogging.h"
#import "DetourLocation+iOSUI.h"
#import "LinkResponsiveTextView.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "TaskState.h"
#import "TriMetInfo+UI.h"
#import "UIApplication+Compat.h"
#import "ViewControllerBase+DetourTableViewCell.h"
#import "XMLMultipleDepartures.h"

#define kGettingStops @"getting locations"
#define kTextMargin (50.0)

@interface MapViewControllerWithDetourStops () {
    NSMutableArray<XMLDepartures *> *_stopData;
}

@property (nonatomic, strong) NSArray<Detour *> *detours;
@property (nonatomic, strong) LinkResponsiveTextView *detourTextView;
@property (nonatomic) UIView *bottomPanel;
@property (nonatomic) UITextView *bottomTextView;
@property (nonatomic) NSLayoutConstraint *panelBottomConstraint; // to shift above toolbar
@property (nonatomic) NSLayoutConstraint *panelHeightConstraint; // dynamic height

@end

@implementation MapViewControllerWithDetourStops

- (void)reloadData {
    [self.detourTextView removeFromSuperview];
    self.detourTextView = nil;
    [super reloadData];
}

// Tune these
static const CGFloat kToolbarClearance = 8.0; // gap above the toolbar
static const CGFloat kPanelSide = 12.0;       // horizontal insets for the panel
static const CGFloat kPanelTopBottom = 8.0;   // vertical insets inside the panel
static const CGFloat kPanelMaxHeight = 160.0; // clamp for very long text

- (NSAttributedString *)detourText {
    if (self.detours.count == 1) {
        NSString *textToFormat = [self.detours.firstObject markedUpDescriptionWithoutInfo:nil];

        if (self.allAnnotations.count == 0) {
            NSArray<NSString *> *stopIdArray = self.detours.firstObject.extractStops;

            if (stopIdArray.count == 1) {
                textToFormat =
                    [NSString stringWithFormat:NSLocalizedString(
                                                   @"#b#RNo location found for stop %@.#b#D\n%@",
                                                   @"error message"),
                                               stopIdArray.firstObject,
                                               textToFormat];
            } else {
                textToFormat = [NSString
                    stringWithFormat:NSLocalizedString(
                                         @"#b#RNo locations found for stops %@.#b#D\n%@",
                                         @"error message"),
                                     [NSString
                                         commaSeparatedStringFromStringEnumerator:stopIdArray],
                                     textToFormat];
            }
        }

        return textToFormat.smallAttributedStringFromMarkUp;
    }
    return nil;
}

- (void)installMapView {
    // 1) Map
    MKMapView *map = [[MKMapView alloc] initWithFrame:CGRectZero];
    map.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:map];
    self.mapView = map;

    // 2) Bottom panel container
    UIView *panel = [[UIView alloc] initWithFrame:CGRectZero];
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    panel.backgroundColor = [[UIColor secondarySystemBackgroundColor] colorWithAlphaComponent:0.95];
    panel.layer.cornerRadius = 12.0;
    panel.layer.masksToBounds = YES;
    [self.view addSubview:panel];
    self.bottomPanel = panel;

    // 3) Text view inside panel
    LinkResponsiveTextView *tv = [[LinkResponsiveTextView alloc] initWithFrame:CGRectZero];
    tv.translatesAutoresizingMaskIntoConstraints = NO;
    tv.backgroundColor = UIColor.clearColor;
    tv.textColor = UIColor.labelColor;
    tv.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    tv.editable = NO;
    tv.scrollEnabled = NO; // let Auto Layout size it; we’ll cap height later
    tv.textContainerInset =
        UIEdgeInsetsMake(kPanelTopBottom, kPanelSide, kPanelTopBottom, kPanelSide);
    tv.delegate = self;
    [panel addSubview:tv];
    self.detourTextView = tv;

    NSAttributedString *text = self.detourText;
    tv.attributedText = text;
    tv.accessibilityLabel = text.string.phonetic;
    self.bottomTextView = tv;

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    // Panel constraints (top, sides)
    [NSLayoutConstraint activateConstraints:@[
        [panel.topAnchor constraintEqualToAnchor:safe.topAnchor constant:8.0],
        [panel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:kPanelSide],
        [panel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor
                                             constant:-kPanelSide],
    ]];
    self.panelHeightConstraint = [panel.heightAnchor constraintGreaterThanOrEqualToConstant:44.0];
    self.panelHeightConstraint.active = YES;

    // TextView fills panel
    [NSLayoutConstraint activateConstraints:@[
        [tv.topAnchor constraintEqualToAnchor:panel.topAnchor],
        [tv.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor],
        [tv.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor],
        [tv.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor],
    ]];

    // Map fills from panel’s bottom to view’s bottom (underlaps toolbar)
    [NSLayoutConstraint activateConstraints:@[
        [map.topAnchor constraintEqualToAnchor:panel.bottomAnchor constant:8.0],
        [map.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [map.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [map.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor], // not safe area
    ]];

    map.showsCompass = YES;
    map.showsScale = YES;
}

- (CGFloat)toolbarHeight {
    UIToolbar *tb = self.navigationController.toolbar;
    if (!tb || self.navigationController.isToolbarHidden || tb.isHidden || tb.alpha <= 0.001)
        return 0.0;
    return [tb sizeThatFits:CGSizeMake(CGRectGetWidth(self.view.bounds), CGFLOAT_MAX)].height;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    // 1) Float panel above toolbar (or home indicator, whichever is taller)
    const CGFloat safeBottom = self.view.safeAreaInsets.bottom;
    const CGFloat bottomGap = MAX([self toolbarHeight], safeBottom) + kToolbarClearance;
    CGFloat newConst = -bottomGap; // constraint is to view.bottomAnchor
    if (fabs(self.panelBottomConstraint.constant - newConst) > 0.5) {
        self.panelBottomConstraint.constant = newConst;
    }

    // 2) Size the text view/panel height to content (non-scrolling until clamped)
    CGSize fit = [self.bottomTextView
        sizeThatFits:CGSizeMake(CGRectGetWidth(self.bottomPanel.bounds), CGFLOAT_MAX)];
    CGFloat desired = MIN(MAX(fit.height, 44.0), kPanelMaxHeight);
    if (fabs(self.panelHeightConstraint.constant - desired) > 0.5) {
        self.panelHeightConstraint.constant = desired;
        // Enable scrolling if content exceeds max height
        self.bottomTextView.scrollEnabled = (fit.height > kPanelMaxHeight - 1.0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchLocationsMaybeAsync:(id<TaskController>)taskController
                         detours:(NSArray<Detour *> *)detours
                             nav:(UINavigationController *)nav {
    self.title = NSLocalizedString(@"Detour Map", @"screen title");
    self.detours = detours;

    NSMutableArray<NSString *> *stopIds = [NSMutableArray array];
    NSMutableArray<NSString *> *routes = [NSMutableArray array];

    for (Detour *detour in self.detours) {
        if (detour.routes) {
            for (Route *route in detour.routes) {
                [routes addObject:route.routeId];
            }
        }

        if (detour.locations != nil && detour.locations.count != 0) {
            for (DetourLocation *loc in detour.locations) {
                [self addPin:loc];
            }
        } else {
            [stopIds addObjectsFromArray:detour.extractStops];
        }
    }

    if (stopIds.count == 0 && self.allAnnotations.count > 0) {
        [self fetchRoutesAsync:taskController
                        routes:routes
                    directions:nil
               additionalTasks:0
                          task:nil];
    } else if (stopIds.count > 0) {
        NSArray<NSString *> *batches = [XMLMultipleDepartures batchesFromEnumerator:stopIds
                                                                     selToGetStopId:@selector(self)
                                                                                max:INT_MAX];

        [self fetchRoutesAsync:taskController
                        routes:routes
                    directions:nil
               additionalTasks:batches.count
                          task:^(TaskState *taskState) {
                            [XMLDepartures clearCache];

                            [taskState taskSubtext:NSLocalizedString(@"getting stops",
                                                                     @"progress message")];

                            for (NSString *allLocs in batches) {
                                XMLMultipleDepartures *allDeps = [XMLMultipleDepartures
                                     xmlWithOptions:DepOptionsNoDetours | DepOptionsOneMin
                                    oneTimeDelegate:taskState];
                                [allDeps getDeparturesForStopIds:allLocs];

                                for (XMLDepartures *deps in allDeps) {
                                    if (deps.loc != nil) {
                                        DetourLocation *dloc = [DetourLocation new];

                                        dloc.stopId = deps.stopId;
                                        dloc.location = deps.loc;
                                        dloc.desc = deps.locDesc;
                                        dloc.dir = deps.locDir;

                                        if (!deps.gotData || deps.items.count == 0) {
                                            dloc.passengerCode = 0;
                                            dloc.noServiceFlag = YES;
                                        } else {
                                            dloc.noServiceFlag = NO;
                                        }

                                        [self addPin:dloc];
                                    }
                                }

                                [taskState incrementItemsDoneAndDisplay];
                            }
                          }];
    }
}

- (BOOL)textView:(UITextView *)textView
    shouldInteractWithURL:(NSURL *)URL
                  inRange:(NSRange)characterRange
              interaction:(UITextItemInteraction)interaction {
    return [self detourLink:URL.absoluteString detour:self.detours.firstObject source:textView];
}

@end
