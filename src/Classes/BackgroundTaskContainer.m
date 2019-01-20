//
//  BackgroundTaskContainer.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/20/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BackgroundTaskContainer.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "DebugLogging.h"
#import "MainQueueSync.h"


@implementation BackgroundTaskContainer

- (void)taskCancel
{
    DEBUG_FUNC();
    if (self.backgroundThread!=nil)
    {
        [self.backgroundThread cancel];
    }
}


- (bool)taskCancelled
{
    DEBUG_FUNC();
    if (self.backgroundThread!=nil)
    {
        return NO;
    }
    
    return self.backgroundThread.isCancelled;
}

- (bool)running
{
    return (self.backgroundThread != nil);
}

- (void)dealloc {
    self.callbackComplete = nil;
}

+ (BackgroundTaskContainer*)create:(id<BackgroundTaskDone>) done
{
    BackgroundTaskContainer * btc = [[BackgroundTaskContainer alloc] init];
    
    btc.callbackComplete = done;    
    return btc;
        
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        
    }
    
    return self;
}

- (void)progressDelegateCancel
{
    [self.backgroundThread cancel];
}

-(void)taskStartWithItems:(NSInteger)items title:(NSString *)title
{
    self.title = title;
    self.errMsg = nil;

    self.backgroundThread = [NSThread currentThread];
    
    self.debugMessages = [UserPrefs sharedInstance].progressDebug;
    
    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
        TriMetTimesAppDelegate *app = [TriMetTimesAppDelegate sharedInstance];
        
        if (self.progressModal == nil)
        {
            if ([self.callbackComplete respondsToSelector:@selector(backgroundTaskStarted)])
            {
                [self.callbackComplete backgroundTaskStarted];
            }
            
            self.progressModal = [ProgressModalView initWithSuper:app.window
                                                            items:items
                                                            title:self.title
                                                         delegate:(self.backgroundThread!=nil?self:nil)
                                                      orientation:[self.callbackComplete backgroundTaskOrientation]];
            
            [app.window addSubview:self.progressModal];
            
            [self.progressModal addHelpText:self.help];
        }
        else
        {
            self.progressModal.totalItems = items;
        }
        
    }];
    
    if ([self.callbackComplete respondsToSelector:@selector(backgroundTaskWait)])
    {
        while([self.callbackComplete backgroundTaskWait])
        {
            [NSThread sleepForTimeInterval:0.3];
        }
    }    
}

-(void)taskSubtext:(NSString *)subtext
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [self.progressModal addSubtext:subtext];
                   });
}

-(void)taskItemsDone:(NSInteger)itemsDone
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [self.progressModal itemsDone:itemsDone];
                   });
}

-(void)taskTotalItems:(NSInteger)totalItems
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [self.progressModal totalItems:totalItems];
                   });
}


-(void)finish
{
    DEBUG_FUNC();
    
    bool cancelled = (self.backgroundThread !=nil && self.backgroundThread.cancelled);
    [self.callbackComplete backgroundTaskDone:self.controllerToPop cancelled:cancelled];
    self.controllerToPop = nil;
    self.progressModal = nil;
    self.backgroundThread = nil;
}

- (void)runBlock:(UIViewController * (^)(void)) block
{
    static NSNumber *globalSyncObject;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        globalSyncObject = @(42);
    });
    
    // This forces the background thread only to run one at a time - no
    // deadlock!
    
    @synchronized(globalSyncObject)
    {
        @autoreleasepool
        {
            self.backgroundThread = [NSThread currentThread];
            [self taskCompleted:block()];
        }
    }
}

- (void)taskRunAsync:(UIViewController * (^)(void)) block
{
    // We need to use the NSThread mechanism so we can cancel it easily, but I want to use the blocks
    // as it makes the passing of variables very easy.
    [self performSelectorInBackground:@selector(runBlock:) withObject:[block copy]];
}


-(void)taskCompleted:(UIViewController *)viewController
{
    DEBUG_FUNC();
    DEBUG_PROGRESS(self, @"BC");
    
    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
         DEBUG_FUNC();
         self.controllerToPop = viewController;
        
         DEBUG_PROGRESS(self, @"DONE");
        
         if (self.progressModal)
         {
             [self.progressModal removeFromSuperview];
         }
         
         if (self.errMsg)
         {
             TriMetTimesAppDelegate *app = [TriMetTimesAppDelegate sharedInstance];
             
             UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                            message:self.errMsg
                                                                     preferredStyle:UIAlertControllerStyleAlert];
             
             
             [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"button text") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
                 
             }]];
             
             [app.navigationController.topViewController presentViewController:alert animated:YES completion:^{
                 [self finish];
             }];
         }
         else
         {
             DEBUG_LOG(@"finish");
             [self finish];
         }
     }];
}

- (void)taskSetErrorMsg:(NSString *)errMsg
{
    self.errMsg = errMsg;
}

- (void)taskSetHelpText:(NSString *)helpText
{
    [self.progressModal addHelpText:helpText];
}

-(NSString *)size:(NSInteger)bytes fromCache:(bool)fromCache
{
    NSString *result = nil;
    if (bytes < 1024)
    {
        result = [NSString stringWithFormat:@"%d B%@", (int)bytes, fromCache ? @" cached" : @""];
    }
    else if (bytes < (1024 * 1024))
    {
        result = [NSString stringWithFormat:@"%.2f K%@", (((float)(bytes))/1024.0),fromCache ? @" cached" : @""];
    } else
    {
        result = [NSString stringWithFormat:@"%.2f MB%@", ((float)(bytes)/(1024*1024)),fromCache ? @" cached" : @""];
    }
    
    return result;
}

- (void)TriMetXML:(TriMetXML*)xml startedFetchingData:(bool)fromCache
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [self.progressModal subItemsDone:1 totalSubs:5];
                   });
}

- (void)TriMetXML:(TriMetXML*)xml finishedFetchingData:(bool)fromCache
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [self.progressModal subItemsDone:3 totalSubs:5];
                   });
}

- (void)TriMetXML:(TriMetXML*)xml startedParsingData:(NSUInteger)size fromCache:(bool)fromCache
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [self.progressModal subItemsDone:4 totalSubs:5];
                       if ([UserPrefs sharedInstance].showSizes)
                       {
                           [self.progressModal addSubtext:[self size:size fromCache:fromCache]];
                       }
                   });
}

- (void)TriMetXML:(TriMetXML*)xml finishedParsingData:(NSUInteger)size fromCache:(bool)fromCache
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [self.progressModal subItemsDone:5 totalSubs:5];
                   });
}

- (void)TriMetXML:(TriMetXML *)xml expectedSize:(long long)expected {
    
}

- (void)TriMetXML:(TriMetXML *)xml progress:(long long)progress of:(long long)expected {
    
    if (expected > 1024*1024)
    {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self.progressModal subItemsDone:4 totalSubs:5];
                           [self.progressModal addSubtext:[NSString stringWithFormat:@"%.1f%% done", (100.0*(float)progress/(float)expected)]];
                       });
    }
}

@end
