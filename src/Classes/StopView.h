//
//  StopView.h
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
#import "TableViewWithToolbar.h"
#import "ReturnStopId.h"
#import "Stop.h"
@class XMLStops;
@class Departure;


@interface StopView : TableViewWithToolbar <ReturnStop>{
	XMLStops *_stopData;
	Departure *_departure;
	NSString *_directionName;
}

@property (nonatomic, retain) XMLStops *stopData;
@property (nonatomic, retain) Departure *departure;
@property (nonatomic, retain) NSString *directionName;
- (void)refreshAction:(id)sender;
- (void)fetchStopsInBackground:(id<BackgroundTaskProgress>) callback route:(NSString*)routeid direction:(NSString*)dir description:(NSString *)desc
				 directionName:(NSString *)dirName;
- (void)fetchDestinationsInBackground:(id<BackgroundTaskProgress>) callback dep:(Departure *)dep;


@end
