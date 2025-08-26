//
//  IntentViewController.h
//  PDXBus Siri ExtensionUI
//
//  Created by Andrew Wallace on 9/23/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLDepartures.h"
#import <IntentsUI/IntentsUI.h>

@interface IntentViewController
    : UIViewController <INUIHostedViewControlling, UITableViewDelegate,
                        UITableViewDataSource>
@property(strong, nonatomic) IBOutlet UITableView *tableView;
@property(strong, nonatomic) NSMutableArray<XMLDepartures *> *departures;
@end
