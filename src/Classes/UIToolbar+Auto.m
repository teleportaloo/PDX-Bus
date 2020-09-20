//
//  CustomToolbar.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/22/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "UIToolbar+Auto.h"
#import "TableViewWithToolbar.h"
#import "Icons.h"

@implementation UIToolbar (Auto)


#pragma mark Methods to create common auto-released toolbar buttons


+ (UIBarButtonItem *)noSleepButtonWithTarget:(id)target action:(SEL)action {
    // create the system-defined "OK or Done" button
    UIBarButtonItem *button = [[UIBarButtonItem alloc]
                               initWithTitle:NSLocalizedString(@"Device sleep disabled!", @"warning") style:UIBarButtonItemStylePlain
                               target:target action:action];
    
    return button;
}

+ (UIBarButtonItem *)magnifyButtonWithTarget:(id)target action:(SEL)action {
    // create the system-defined "OK or Done" button
    UIBarButtonItem *mag = [[UIBarButtonItem alloc]
                            // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                            initWithImage:[Icons getToolbarIcon:kIconMagnify]
                            style:UIBarButtonItemStylePlain
                            target:target action:action];
    
    TOOLBAR_PLACEHOLDER(mag, NSLocalizedString(@"mag", @"placeholder"));
    mag.style = UIBarButtonItemStylePlain;
    mag.accessibilityLabel = NSLocalizedString(@"Large bus line identifier", @"accessibility text");
    return mag;
}

+ (UIBarButtonItem *)mapButtonWithTarget:(id)target action:(SEL)action {
    // create the system-defined "OK or Done" button
    UIBarButtonItem *map = [[UIBarButtonItem alloc]
                            initWithImage:[Icons getToolbarIcon:kIconMap7]
                            style:UIBarButtonItemStylePlain
                            target:target action:action];
    
    TOOLBAR_PLACEHOLDER(map, NSLocalizedString(@"map", @"placeholder"));
    map.style = UIBarButtonItemStylePlain;
    map.accessibilityLabel = NSLocalizedString(@"Show Map", @"accessibility text");
    
    return map;
}

+ (UIBarButtonItem *)flashButtonWithTarget:(id)target action:(SEL)action {
    UIBarButtonItem *flash = [[UIBarButtonItem alloc]
                              // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                              initWithImage:[Icons getToolbarIcon:kIconFlash7]
                              style:UIBarButtonItemStylePlain
                              target:target action:action];
    
    TOOLBAR_PLACEHOLDER(flash, NSLocalizedString(@"flash", @"placeholder"));
    flash.style = UIBarButtonItemStylePlain;
    flash.accessibilityLabel = NSLocalizedString(@"Flash Screen", @"accessibility text");
    return flash;
}

+ (UIBarButtonItem *)doneButtonWithTarget:(id)target action:(SEL)action {
    // create the system-defined "OK or Done" button
    UIBarButtonItem *back = [[UIBarButtonItem alloc]
                             initWithImage:[Icons getToolbarIcon:kIconHome7]
                             style:UIBarButtonItemStylePlain
                             target:target action:action];
    
    TOOLBAR_PLACEHOLDER(back, NSLocalizedString(@"home", @"placeholder"));
    back.style = UIBarButtonItemStylePlain;
    back.accessibilityLabel = NSLocalizedString(@"Home", @"accessibility text");
    back.accessibilityHint = nil;
    
    return back;
}

+ (UIBarButtonItem *)redoButtonWithTarget:(id)target action:(SEL)action {
    // create the system-defined "OK or Done" button
    UIBarButtonItem *back = [[UIBarButtonItem alloc]
                             initWithImage:[Icons getToolbarIcon:kIconRedo]
                             style:UIBarButtonItemStylePlain
                             target:target action:action];
    
    TOOLBAR_PLACEHOLDER(back, NSLocalizedString(@"redo", @"placeholder"));
    back.style = UIBarButtonItemStylePlain;
    back.accessibilityLabel = NSLocalizedString(@"Redo", @"accessibility text");
    return back;
}

+ (UIBarButtonItem *)commuteButtonWithTarget:(id)target action:(SEL)action {
    UIBarButtonItem *back = [[UIBarButtonItem alloc]
                             // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                             initWithImage:[Icons getToolbarIcon:kIconCommute7]
                             style:UIBarButtonItemStylePlain
                             target:target action:action];
    
    TOOLBAR_PLACEHOLDER(back, NSLocalizedString(@"com", @"placeholder"));
    back.style = UIBarButtonItemStylePlain;
    back.accessibilityLabel = NSLocalizedString(@"Commuter Bookmark", @"acessibility text");
    return back;
}

+ (UIBarButtonItem *)settingsButtonWithTarget:(id)target action:(SEL)action {
    UIBarButtonItem *back = [[UIBarButtonItem alloc]
                             // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                             initWithImage:[Icons getToolbarIcon:kIconSettings]
                             style:UIBarButtonItemStylePlain
                             target:target action:action];
    
    TOOLBAR_PLACEHOLDER(back, NSLocalizedString(@"settings", @"placeholder"));
    back.style = UIBarButtonItemStylePlain;
    back.accessibilityLabel = NSLocalizedString(@"Settings", @"acessibility text");
    return back;
}

+ (UIBarButtonItem *)locateButtonWithTarget:(id)target action:(SEL)action {
    UIBarButtonItem *back = [[UIBarButtonItem alloc]
                             initWithImage:[Icons getToolbarIcon:kIconLocateNear7]
                             style:UIBarButtonItemStylePlain
                             target:target action:action];
    
    TOOLBAR_PLACEHOLDER(back, NSLocalizedString(@"loc", @"placeholder"));
    back.style = UIBarButtonItemStylePlain;
    back.accessibilityLabel = NSLocalizedString(@"Locate Stops", @"acessibility text");
    return back;
}

+ (UIBarButtonItem *)qrScannerButtonWithTarget:(id)target action:(SEL)action {
    UIBarButtonItem *back = [[UIBarButtonItem alloc]
                             initWithImage:[Icons getToolbarIcon:kIconCamera7]
                             style:UIBarButtonItemStylePlain
                             target:target action:action];
    
    TOOLBAR_PLACEHOLDER(back, NSLocalizedString(@"QR", @"placeholder"));
    back.style = UIBarButtonItemStylePlain;
    back.accessibilityLabel = NSLocalizedString(@"QR Scanner", @"acessibility text");
    return back;
}

+ (UIBarButtonItem *)flexSpace {
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                           target:nil
                                                                           action:nil];
    
    return space;
}

@end
