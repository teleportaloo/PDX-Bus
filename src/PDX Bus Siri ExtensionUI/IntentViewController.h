//
//  IntentViewController.h
//  PDXBus Siri ExtensionUI
//
//  Created by Andrew Wallace on 9/23/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//

#import <IntentsUI/IntentsUI.h>
#import "XMLDepartures.h"

@interface IntentViewController : UIViewController <INUIHostedViewControlling, UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray<XMLDepartures *> *departures;
@end
