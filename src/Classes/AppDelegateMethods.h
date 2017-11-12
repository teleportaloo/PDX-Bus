//
//  AppDelegateMethods.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


@class Stop, Route, Departure, TriMetTimesAppDelegate, StopView;

@interface TriMetTimesAppDelegate (AppDelegateMethods)

- (BOOL)processURL:(NSString *)url protocol:(NSString *)protocol;
- (BOOL)processBookMarkFromURL:(NSString *)bookmark protocol:(NSString *)protocol;
- (BOOL)processStopFromURL:(NSString *)stop;
- (BOOL)processCommandFromURL:(NSString *)command;
+ (TriMetTimesAppDelegate*)sharedInstance;

@end


