//
//  AppDelegateMethods.h
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

@class Stop, Route, Departure, TriMetTimesAppDelegate, StopView;

@interface TriMetTimesAppDelegate (AppDelegateMethods)



- (NSDictionary *)getStreetcarPlatforms;
- (NSDictionary *)getStreetcarDirections;
- (NSDictionary *)getStreetcarShortNames;
- (NSString *)getStreetcarRoute;
- (BOOL)processURL:(NSString *)url protocol:(NSString *)protocol;
- (BOOL)processBookMarkFromURL:(NSString *)bookmark protocol:(NSString *)protocol;
- (BOOL)processStopFromURL:(NSString *)stop;
- (void)showActivityViewer;
- (void)hideActivityViewer;
+ (TriMetTimesAppDelegate*)getSingleton;
- (NSDictionary *)checkForCommuterBookmarkShowOnlyOnce:(bool)onlyOnce;
- (bool)canTweet;


@end


