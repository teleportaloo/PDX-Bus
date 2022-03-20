//
//  BackgroundTaskContainer.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/20/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogTask

#import "BackgroundTaskContainer.h"
#import "PDXBusAppDelegate+Methods.h"
#import "DebugLogging.h"
#import "MainQueueSync.h"
#import "TaskState.h"
#import "UIAlertController+SimpleMessages.h"

@interface BackgroundTaskContainer ()

@property (atomic, strong) NSString *errMsg;
@property (atomic, strong) NSThread *backgroundThread;

@end

@implementation BackgroundTaskContainer

- (void)taskCancel {
    DEBUG_FUNC();
    
    if (self.backgroundThread != nil) {
        [self.backgroundThread cancel];
    }
}

- (bool)taskCancelled {
    DEBUG_FUNC();
    
    if (self.backgroundThread != nil) {
        return NO;
    }
    
    return self.backgroundThread.isCancelled;
}

- (bool)running {
    return (self.backgroundThread != nil);
}

- (void)dealloc {
    self.callbackComplete = nil;
}

+ (BackgroundTaskContainer *)create:(id<BackgroundTaskDone>)done {
    BackgroundTaskContainer *btc = [[BackgroundTaskContainer alloc] init];
    
    btc.callbackComplete = done;
    return btc;
}

- (instancetype)init {
    if ((self = [super init])) {
    }
    
    return self;
}

- (void)progressDelegateCancel {
    [self.backgroundThread cancel];
}

- (void)taskStartWithTotal:(NSInteger)total title:(NSString *)title {
    self.title = title;
    self.errMsg = nil;
    self.bytesDone = 0;
    
    self.backgroundThread = [NSThread currentThread];
    
    self.debugMessages = Settings.progressDebug;
    self.showSizes = Settings.showSizes;
    
    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
        PDXBusAppDelegate *app = PDXBusAppDelegate.sharedInstance;
        
        if (self.progressModal == nil) {
            if ([self.callbackComplete respondsToSelector:@selector(backgroundTaskStarted)]) {
                [self.callbackComplete backgroundTaskStarted];
            }
            
            self.progressModal = [[ProgressModalView alloc]            initWithParent:app.window
                                                                                items:total
                                                                                title:self.title
                                                                             delegate:(self.backgroundThread != nil ? self : nil)
                                                                          orientation:[self.callbackComplete backgroundTaskOrientation]];
            
            [app.window addSubview:self.progressModal];
            
            [self.progressModal addHelpText:self.help];
        } else {
            self.progressModal.totalItems = total;
        }
    }];
    
    if ([self.callbackComplete respondsToSelector:@selector(backgroundTaskWait)]) {
        while ([self.callbackComplete backgroundTaskWait]) {
            [NSThread sleepForTimeInterval:0.3];
        }
    }
}

- (void)taskSubtext:(NSString *)subtext {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self addBytes:subtext];
    });
}

- (void)taskItemsDone:(NSInteger)itemsDone {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressModal itemsDone:itemsDone];
    });
}

- (void)taskTotalItems:(NSInteger)totalItems {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressModal totalItems:totalItems];
    });
}

- (void)finish {
    DEBUG_FUNC();
    
    bool cancelled = (self.backgroundThread != nil && self.backgroundThread.cancelled);
    
    [self.callbackComplete backgroundTaskDone:self.controllerToPop cancelled:cancelled];
    self.controllerToPop = nil;
    self.progressModal = nil;
    self.backgroundThread = nil;
}

- (void)runBlock:(UIViewController * (^)(TaskState *taskState))block {
    static NSMutableData *globalSyncObject;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        globalSyncObject = [[NSMutableData alloc] initWithLength:1];
    });
    
    // This forces the background thread only to run one at a time - no
    // deadlock!
    
    @synchronized(globalSyncObject) {
        @autoreleasepool
        {
            self.backgroundThread = [NSThread currentThread];
            TaskState *taskState = [TaskState state:self];
            [self taskCompleted:block(taskState)];
        }
    }
}

- (void)taskRunAsync:(UIViewController * (^)(TaskState *state))block {
    // We need to use the NSThread mechanism so we can cancel it easily, but I want to use the blocks
    // as it makes the passing of variables very easy.
    [self performSelectorInBackground:@selector(runBlock:) withObject:[block copy]];
}

- (void)taskCompleted:(UIViewController *)viewController {
    DEBUG_FUNC();
    DEBUG_PROGRESS(self, @"task done");
    
    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
        DEBUG_FUNC();
        self.controllerToPop = viewController;
        
        DEBUG_PROGRESS(self, @"finishing");
        
        if (self.progressModal) {
            [self.progressModal removeFromSuperview];
        }
        
        if (self.errMsg) {
            UIAlertController *alert = [UIAlertController simpleOkWithTitle:nil message:self.errMsg];
            
            UIViewController *top = PDXBusAppDelegate.sharedInstance.navigationController.topViewController;
            
            [top presentViewController:alert
                              animated:YES
                            completion:^{
                [self finish];
            }];
        } else {
            DEBUG_LOG(@"finish");
            [self finish];
        }
    }];
}

- (void)taskSetErrorMsg:(NSString *)errMsg {
    self.errMsg = errMsg;
}

- (void)taskSetHelpText:(NSString *)helpText {
    [self.progressModal addHelpText:helpText];
}

- (NSString *)size:(NSInteger)bytes fromCache:(bool)fromCache {
    NSString *result = nil;
    
    if (bytes < 1024) {
        result = [NSString stringWithFormat:@"%d B%@", (int)bytes, fromCache ? @" cached" : @""];
    } else if (bytes < (1024 * 1024)) {
        result = [NSString stringWithFormat:@"%.2f K%@", (((float)(bytes)) / 1024.0), fromCache ? @" cached" : @""];
    } else {
        result = [NSString stringWithFormat:@"%.2f MB%@", ((float)(bytes) / (1024 * 1024)), fromCache ? @" cached" : @""];
    }
    
    return result;
}

- (void)triMetXML:(TriMetXML *)xml startedFetchingData:(bool)fromCache {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressModal subItemsDone:1 totalSubs:5];
    });
}

- (void)triMetXML:(TriMetXML *)xml finishedFetchingData:(bool)fromCache {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressModal subItemsDone:4 totalSubs:5];
        [self addBytes:@""];
    });
}

#define kBytesToKB(B) ((double)(B) / 1024)
#define kBytesToMB(B) (((double)(B)) / (1024 * 1024))

- (NSString *)bytes:(long long)bytes
{
    if (kBytesToKB(bytes) > 512) {
        return [NSString stringWithFormat:@"%.2f MB", kBytesToMB(bytes)];
    }
    
    return [NSString stringWithFormat:@"%.2f KB", kBytesToKB(bytes)];
}

- (void)addBytes:(NSString *)text
{
    if (self.bytesDone > 0 && self.showSizes) {
        [self.progressModal addSubtext:[NSString stringWithFormat:@"%@ %@", [self bytes:self.bytesDone], text]];
    } else {
        [self.progressModal addSubtext:text];
    }
}

- (void)triMetXML:(TriMetXML * _Nonnull)xml incrementalBytes:(long long)incremental {
    self.bytesDone += incremental;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressModal subItemsDone:3 totalSubs:5];
        [self addBytes:@""];
    });
}


@end
