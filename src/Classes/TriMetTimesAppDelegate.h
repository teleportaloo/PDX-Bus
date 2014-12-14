//
//  TriMetTimesAppDelegate.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TriMetTypes.h"
#import "UserPrefs.h"

@class RootViewController;
@class Departure;

@interface TriMetTimesAppDelegate : NSObject <UIApplicationDelegate,UIAlertViewDelegate> {	
	IBOutlet UIWindow *window;
	IBOutlet UINavigationController *navigationController;
    IBOutlet RootViewController *rootViewController;
    
	NSString *_pathToCleanExit;
	bool     _cleanExitLastTime;
}

@property (nonatomic) bool cleanExitLastTime;

@property (nonatomic, retain) NSString *pathToCleanExit;
@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) RootViewController *rootViewController;


@end

