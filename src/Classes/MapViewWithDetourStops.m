//
//  MapViewWithDetourStops.m
//  PDX Bus
//
//  Created by Andrew Wallace on 3/6/14.
//  Copyright (c) 2014 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapViewWithDetourStops.h"
#import "DebugLogging.h"
#import "DetourLocation+iOSUI.h"
#import "NSString+Helper.h"
#import "XMLMultipleDepartures.h"
#import "TaskState.h"
#import "LinkResponsiveTextView.h"
#import "ViewControllerBase+DetourTableViewCell.h"
#import "UIApplication+Compat.h"

#define kGettingStops @"getting locations"
#define kTextMargin   (50.0)

@interface MapViewWithDetourStops () {
    NSMutableArray<XMLDepartures *> *_stopData;
}

@property (nonatomic, strong) NSArray<Detour *> *detours;
@property (nonatomic, strong) LinkResponsiveTextView *detourText;

@end

@implementation MapViewWithDetourStops


- (void)reloadData {
    [self.detourText removeFromSuperview];
    self.detourText = nil;
    [super reloadData];
}

- (void)modifyMapViewFrame:(CGRect *)frame {
    if (self.detours.count == 1) {
        const CGFloat mapRatio = 0.5;
        
        NSString *textToFormat = [self.detours.firstObject formattedDescriptionWithoutInfo:nil];
        
        if (self.annotations.count == 0) {
            NSArray<NSString *> *stopIdArray = self.detours.firstObject.extractStops;
            
            if (stopIdArray.count == 1) {
                textToFormat = [NSString stringWithFormat:NSLocalizedString(@"#b#RNo location found for stop %@.#b#D\n%@", @"error message"), stopIdArray.firstObject, textToFormat];
            } else {
                textToFormat = [NSString stringWithFormat:NSLocalizedString(@"#b#RNo locations found for stops %@.#b#D\n%@", @"error message"), [NSString commaSeparatedStringFromStringEnumerator:stopIdArray], textToFormat];
            }
        }
        
        NSAttributedString *text = [textToFormat formatAttributedStringWithFont:self.paragraphFont];
        
        // CGRect textSize = [text boundingRectWithSize:CGSizeMake(frame->size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
        
        CGFloat textHeight = frame->size.height * (1 - mapRatio);
        // CGFloat textHeight = textSize.size.height > maxTextHeight ? maxTextHeight : textSize.size.height;
        
        CGRect textViewFrame = CGRectMake(frame->origin.x, frame->origin.y + frame->size.height - textHeight, frame->size.width, textHeight);
        
        UIColor *background = nil;
        
        if (self.detours.firstObject.systemWide) {
            background = [UIColor modeAwareSystemWideAlertBackground];
        } else {
            background = [UIColor modeAwareAppBackground];
        }
        
        if (self.detourText == nil) {
            self.detourText = [[LinkResponsiveTextView alloc] initWithFrame:textViewFrame];
            self.detourText.textAlignment = NSTextAlignmentLeft;
            self.detourText.backgroundColor = [UIColor clearColor]; //   background;
            self.detourText.alpha = 1.0;
            self.view.backgroundColor = background;
            self.detourText.attributedText = text;
            self.detourText.accessibilityLabel = text.string.phonetic;
            self.detourText.accessibilityTraits = UIAccessibilityTraitStaticText;
            self.detourText.accessibilityValue = @"";
            self.detourText.delegate = self;

        }
        
        // Now redo the size
        CGSize newSize = [self.detourText sizeThatFits:CGSizeMake(frame->size.width, MAXFLOAT)];
        
        textHeight =  newSize.height > textHeight ? textHeight : (newSize.height + kTextMargin);
        textViewFrame.size.height = textHeight;
        textViewFrame.origin.y = frame->origin.y + frame->size.height - textHeight;
        
        frame->size.height -=  textHeight;
        
        
        self.detourText.frame = textViewFrame;
        
        if (self.detourText.superview == nil) {
            [self.view addSubview:self.detourText];
        }
        
        for (UIView *view in self.view.subviews) {
            view.backgroundColor = background;
        }
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

- (void)fetchLocationsMaybeAsync:(id<TaskController>)taskController detours:(NSArray<Detour *> *)detours nav:(UINavigationController *)nav {
    self.title = NSLocalizedString(@"Detour Map", @"screen title");
    self.detours = detours;
    
    NSMutableArray<NSString *> *locs = [NSMutableArray array];
    NSMutableArray<NSString *> *routes = [NSMutableArray array];
    
    for (Detour *detour in self.detours) {
        if (detour.routes) {
            for (Route *route in detour.routes) {
                [routes addObject:route.route];
            }
        }
        
        if (detour.locations != nil && detour.locations.count != 0) {
            for (DetourLocation *loc in detour.locations) {
                [self addPin:loc];
            }
        } else {
            [locs addObjectsFromArray:detour.extractStops];
        }
    }
    
    if (locs.count == 0 && self.annotations.count > 0) {
        [self fetchRoutesAsync:taskController routes:routes directions:nil additionalTasks:0 task:nil];
    } else if (locs.count > 0) {
        NSArray<NSString *> *batches = [XMLMultipleDepartures batchesFromEnumerator:locs
                                                                           selector:@selector(self) max:INT_MAX];
        
        [self fetchRoutesAsync:taskController routes:routes directions:nil additionalTasks:batches.count
                          task:^(TaskState *taskState) {
            [XMLDepartures clearCache];
            
            [taskState taskSubtext:NSLocalizedString(@"getting stops", @"progress message")];
            
            for (NSString *allLocs in batches) {
                XMLMultipleDepartures *allDeps = [XMLMultipleDepartures xmlWithOptions:DepOptionsNoDetours | DepOptionsOneMin
                                                                       oneTimeDelegate:taskState];
                [allDeps getDeparturesForStopIds:allLocs];
                
                for (XMLDepartures *dep in allDeps) {
                    if (dep.loc != nil) {
                        DetourLocation *dloc = [DetourLocation data];
                        
                        dloc.stopId = dep.stopId;
                        dloc.location = dep.loc;
                        dloc.desc = dep.locDesc;
                        dloc.dir = dep.locDir;
                        
                        if (!dep.gotData || dep.items.count == 0) {
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

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    return [self detourLink:URL.absoluteString detour:self.detours.firstObject];
}

@end
