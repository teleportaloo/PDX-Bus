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
#import "StringHelper.h"
#import "XMLMultipleDepartures.h"

#define kGettingStops @"getting locations"

@implementation MapViewWithDetourStops


- (void)reloadData
{
    [self.detourText removeFromSuperview];
    self.detourText = nil;
    [super reloadData];
}

- (CGFloat)heightOffset
{
    return [UIApplication sharedApplication].statusBarFrame.size.height;
}

- (void)modifyMapViewFrame:(CGRect *)frame
{
    if (self.detours.count == 1)
    {
        const CGFloat mapRatio = 0.5;
        
        NSString *textToFormat = self.detours.firstObject.formattedDescriptionWithoutInfo;
        
        if (self.annotations.count == 0)
        {
            NSArray *stops = self.detours.firstObject.extractStops;
            if (stops.count == 1)
            {
                textToFormat = [NSString stringWithFormat:NSLocalizedString(@"#b#RNo location found for stop %@.#b#0\n%@", @"error message"), stops.firstObject, textToFormat];
            }
            else
            {
                textToFormat = [NSString stringWithFormat:NSLocalizedString(@"#b#RNo locations found for stops %@.#b#0\n%@", @"error message"), [NSString commaSeparatedStringFromEnumerator:stops selector:@selector(self)], textToFormat];
            }
        }
        
        
        NSAttributedString *text  = [textToFormat formatAttributedStringWithFont:self.paragraphFont];
        
        // CGRect textSize = [text boundingRectWithSize:CGSizeMake(frame->size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
        
        CGFloat textHeight = frame->size.height * (1-mapRatio);
        // CGFloat textHeight = textSize.size.height > maxTextHeight ? maxTextHeight : textSize.size.height;
        
        CGRect textViewFrame = CGRectMake(frame->origin.x, frame->origin.y + frame->size.height - textHeight, frame->size.width, textHeight);
        
        if (self.detourText==nil)
        {
            self.detourText = [[UITextView alloc] initWithFrame:textViewFrame];
            self.detourText.editable = NO;
            self.detourText.selectable = NO;
            self.detourText.textAlignment = NSTextAlignmentLeft;
            self.detourText.backgroundColor = [UIColor whiteColor];
            self.detourText.attributedText = text;
            self.detourText.accessibilityLabel = text.string.phonetic;
            self.detourText.accessibilityTraits = UIAccessibilityTraitStaticText;
            self.detourText.accessibilityValue = @"";
        }
        
        // Now redo the size
        CGSize newSize = [self.detourText sizeThatFits:CGSizeMake(frame->size.width, MAXFLOAT)];
        
        textHeight = newSize.height > textHeight ? textHeight : newSize.height;
        textViewFrame.size.height = textHeight;
        textViewFrame.origin.y = frame->origin.y + frame->size.height - textHeight;
        
        frame->size.height =  frame->size.height - textHeight;
        
        
        self.detourText.frame = textViewFrame;
        
        if (self.detourText.superview == nil)
        {
            [self.view addSubview:self.detourText];
        }
        
        if (self.detours.firstObject.systemWideFlag)
        {
            self.detourText.backgroundColor = SystemWideDetourBackgroundColor;
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchLocationsMaybeAsync:(id<BackgroundTaskController>)task detours:(NSArray<Detour *>*)detours nav:(UINavigationController*)nav
{
    self.title = NSLocalizedString(@"Detour Map", @"screen title");
    self.detours = detours;

    
    NSMutableArray<NSString *> *locs = [NSMutableArray array];
    NSMutableArray<NSString *> *routes = [NSMutableArray array];
    
    for (Detour *detour in self.detours)
    {
        if (detour.routes)
        {
            for (Route *route in detour.routes)
            {
                [routes addObject:route.route];
            }
        }
        if (detour.locations!=nil && detour.locations.count!=0)
        {
            for (DetourLocation *loc in detour.locations)
            {
                [self addPin:loc];
            }
        }
        else
        {
            [locs addObjectsFromArray:detour.extractStops];
        }
    }
    
    if (locs.count == 0 && self.annotations.count > 0)
    {
        [self fetchRoutesAsync:task routes:routes directions:nil additionalTasks:0 task:nil];
        
    } else if (locs.count >0)
    {
        NSArray<NSString *>* batches = [XMLMultipleDepartures batchesFromEnumerator:locs selector:@selector((self)) max:INT_MAX];
        
        [self fetchRoutesAsync:task routes:routes directions:nil additionalTasks:batches.count task:^( id<BackgroundTaskController> background ){
            
            [XMLDepartures clearCache];
            
            [background taskSubtext:@"getting stops"];
            
            // int total = (int)locs.count;
            
            int item = 0;
            for (NSString *allLocs in batches)
            {
                item++;
                XMLMultipleDepartures *allDeps = [XMLMultipleDepartures xmlWithOptions:DepOptionsNoDetours | DepOptionsOneMin];
                allDeps.oneTimeDelegate = background;
                [allDeps getDeparturesForLocations:allLocs];
                
                for (XMLDepartures *dep in allDeps)
                {
                    if (dep.loc!=nil)
                    {
                        DetourLocation *dloc = [DetourLocation data];
                        
                        dloc.locid = dep.locid;
                        dloc.location = dep.loc;
                        dloc.desc = dep.locDesc;
                        dloc.dir = dep.locDir;
                        
                        if (!dep.gotData || dep.items.count == 0)
                        {
                            dloc.passengerCode = 0;
                            dloc.noServiceFlag = YES;
                        }
                        else
                        {
                            dloc.noServiceFlag = NO;
                        }
                        
                        [self addPin:dloc];
                    }
                }
                [background taskItemsDone:item];
            }
            
        }];
    }
}


@end
