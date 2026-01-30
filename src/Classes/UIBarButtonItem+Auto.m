//
//  CustomToolbar.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/22/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Icons.h"
#import "TableViewControllerWithToolbar.h"
#import "UIBarButtonItem+Auto.h"
#import "UIBarButtonItem+Icons.h"

const CGFloat buttonWidth = 32.0;

@implementation UIBarButtonItem (Auto)

#pragma mark Methods to create common auto-released toolbar buttons

+ (UIBarButtonItem *)textButton:(NSString *)text target:(id)target action:(SEL)action {
    // create the system-defined "OK or Done" button
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:text
                                                               style:UIBarButtonItemStylePlain
                                                              target:target
                                                              action:action];

    return button;
}

+ (UIBarButtonItem *)noSleepButtonWithTarget:(id)target action:(SEL)action {
    // create the system-defined "OK or Done" button
    UIBarButtonItem *button =
        [self textButton:NSLocalizedString(@"Device sleep disabled!", @"warning")
                  target:target
                  action:action];
    return button;
}

+ (UIBarButtonItem *)imageButton:(UIImage *)image target:(id)target action:(SEL)action {
    return [[UIBarButtonItem alloc] initWithImage:image
                                            style:UIBarButtonItemStylePlain
                                           target:target
                                           action:action];
}

+ (UIBarButtonItem *)iconButton:(BoxedIcon *)icon
             accessabilityLabel:(NSString *)accessability
                         target:(id)target
                         action:(SEL)action {

    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:icon.image
                                                             style:UIBarButtonItemStylePlain
                                                            target:target
                                                            action:action];

    item.accessibilityLabel = accessability;
    return item;
}

+ (UIBarButtonItem *)magnifyButtonWithTarget:(id)target action:(SEL)action {

    return [self iconButton:kIconMagnify
         accessabilityLabel:NSLocalizedString(@"Large bus line identifier", @"accessibility text")
                     target:target
                     action:action];
}

+ (UIBarButtonItem *)mapButtonWithTarget:(id)target action:(SEL)action {
    return [self iconButton:kIconMap
         accessabilityLabel:NSLocalizedString(@"Show Map", @"accessibility text")
                     target:target
                     action:action];
}

+ (UIBarButtonItem *)flashButtonWithTarget:(id)target action:(SEL)action {
    return [self iconButton:kIconFlash
         accessabilityLabel:NSLocalizedString(@"Flash Screen", @"accessibility text")
                     target:target
                     action:action];
}

+ (UIBarButtonItem *)homeButtonWithTarget:(id)target action:(SEL)action {
    return [self iconButton:kIconHome
         accessabilityLabel:NSLocalizedString(@"Home", @"accessibility text")
                     target:target
                     action:action];
}

+ (UIBarButtonItem *)redoButtonWithTarget:(id)target action:(SEL)action {
    return [self iconButton:kIconBack
         accessabilityLabel:NSLocalizedString(@"Redo", @"accessibility text")
                     target:target
                     action:action];
}

+ (UIBarButtonItem *)commuteButtonWithTarget:(id)target action:(SEL)action {
    return [self iconButton:kIconCommute
         accessabilityLabel:NSLocalizedString(@"Commuter Bookmark", @"acessibility text")
                     target:target
                     action:action];
}

+ (UIBarButtonItem *)settingsButtonWithTarget:(id)target action:(SEL)action {
    return [self iconButton:kIconSettings
         accessabilityLabel:NSLocalizedString(@"Settings", @"acessibility text")
                     target:target
                     action:action];
}

+ (UIBarButtonItem *)locateButtonWithTarget:(id)target action:(SEL)action {

    return [self iconButton:kIconLocateMe
         accessabilityLabel:NSLocalizedString(@"Locate Stops", @"acessibility text")
                     target:target
                     action:action];
}

+ (UIBarButtonItem *)qrScannerButtonWithTarget:(id)target action:(SEL)action {
    return [self iconButton:kIconQR
         accessabilityLabel:NSLocalizedString(@"QR Scanner", @"acessibility text")
                     target:target
                     action:action];
}

+ (UIBarButtonItem *)flexSpace {
    UIBarButtonItem *space =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                      target:nil
                                                      action:nil];

    return space;
}

- (void)setIcon:(BoxedSystemIcon *)icon {
    self.image = icon.image;
}

@end
