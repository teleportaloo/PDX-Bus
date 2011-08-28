//
//  XMLStops.h
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
#import "Stop.h"
#import "TriMetXML.h"


@interface XMLStops : TriMetXML {
	Stop			*_currentStopObject;
	NSString		*_direction;
	NSString		*_routeId;
	NSString		*_routeDescription;
	NSString		*_afterStop;
}

@property (nonatomic, retain) Stop *currentStopObject;
@property (nonatomic, retain) NSString *direction;
@property (nonatomic, retain) NSString *routeId;
@property (nonatomic, retain) NSString *routeDescription;
@property (nonatomic, retain) NSString *afterStop;

- (BOOL)getStopsForRoute:(NSString *)route direction:(NSString *)dir 
			 description:(NSString *)desc parseError:(NSError **)error cacheAction:(CacheAction)cacheAction;
- (BOOL)getStopsAfterLocation:(NSString *)locid route:(NSString *)route direction:(NSString *)dir 
				  description:(NSString *)desc parseError:(NSError **)error cacheAction:(CacheAction)cacheAction;


@end
