//
//  TriMetTimesAppDelegate.h
//  TriMetTimes
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import <UIKit/UIKit.h>
#import "TriMetTypes.h"
#import "UserPrefs.h"



@class RootViewController;
@class Departure;

@interface TriMetTimesAppDelegate : NSObject <UIApplicationDelegate,UIAlertViewDelegate> {	
	IBOutlet UIWindow *window;
	IBOutlet UINavigationController *navigationController;
	IBOutlet RootViewController *rootViewController;
		
	NSMutableDictionary *_streetcarMapping;
	NSString *_pathToCleanExit;
	UIView *activityView;
	bool _cleanExitLastTime;
	UserPrefs *_prefs;	
	bool _suppressCommuterBookmarkOnActivate;
}

@property (nonatomic, retain) UserPrefs *prefs;
@property (nonatomic) bool cleanExitLastTime;
@property (nonatomic, retain) NSMutableDictionary *streetcarMapping;
@property (nonatomic, retain) NSString *pathToCleanExit;
@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet RootViewController *rootViewController;


@end

