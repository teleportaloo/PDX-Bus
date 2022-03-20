//
//  StopView.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewControllerWithRefresh.h"
#import "Stop.h"

@class XMLStops;
@class Departure;

@interface StopView : TableViewControllerWithRefresh<ReturnStopObject>

- (void)fetchStopsAsync:(id<TaskController>)taskController
                  route:(NSString *)routeid
              direction:(NSString *)dir
            description:(NSString *)desc
          directionName:(NSString *)dirName
      backgroundRefresh:(bool)backgroundRefresh;

- (void)fetchDestinationsAsync:(id<TaskController>)taskController
                           dep:(Departure *)dep;

@end
