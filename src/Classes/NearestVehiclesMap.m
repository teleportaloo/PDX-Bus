//
//  NearestVehiclesMap.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//

#import "NearestVehiclesMap.h"
#import "XMLLocateVehicles.h"


@implementation NearestVehiclesMap

@synthesize locator = _locator;

- (void)dealloc
{
    self.locator = nil;
    [super dealloc];
}

- (void)fetchNearestVehicles:(XMLLocateVehicles*) locator
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSThread *thread = [NSThread currentThread];
	
	[self.backgroundTask.callbackWhenFetching backgroundThread:thread];
	
    
	[self.backgroundTask.callbackWhenFetching backgroundStart:1 title:@"getting vehicles"];
    
	[locator findNearestVehicles];
    
	if (![locator displayErrorIfNoneFound:self.backgroundTask.callbackWhenFetching])
	{
		for (int i=0; i< [locator safeItemCount] && ![thread isCancelled]; i++)
		{
			[self addPin:[locator.itemArray objectAtIndex:i]];
		}
	}
   	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
    
    self.title = @"Vehicle Map";
	
	[pool release];
}



- (void)fetchNearestVehiclesInBackground:(id<BackgroundTaskProgress>)background location:(CLLocation *)here maxDistance:(double)dist
{
	self.backgroundTask.callbackWhenFetching = background;
	
    self.locator = [[[XMLLocateVehicles alloc] init] autorelease];
	
	self.locator.location = here;
	self.locator.dist     = dist;
	
	[NSThread detachNewThreadSelector:@selector(fetchNearestVehicles:) toTarget:self withObject:self.locator];
	
}

-(void)refreshAction:(id)arg
{
    self.backgroundRefresh = YES;
    
    XMLLocateVehicles * locator =[self.locator retain];
    
    [self.annotations removeAllObjects];
    
    [self fetchNearestVehiclesInBackground:self.backgroundTask location:locator.location maxDistance:locator.dist];
    
    [locator release];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // add our custom add button as the nav bar's custom right view
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]
                                      initWithTitle:NSLocalizedString(@"Refresh", @"")
                                      style:UIBarButtonItemStyleBordered
                                      target:self
                                      action:@selector(refreshAction:)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    [refreshButton release];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (bool)hasXML
{
    return YES;
}

-(void) appendXmlData:(NSMutableData *)buffer
{
    [self.locator appendQueryAndData:buffer];
}
@end
