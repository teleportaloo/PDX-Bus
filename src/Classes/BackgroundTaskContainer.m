//
//  BackgroundTaskContainer.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/20/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogTask

#import "BackgroundTaskContainer.h"
#import "DebugLogging.h"
#import "MainQueueSync.h"
#import "Settings.h"
#import "TaskDispatch.h"
#import "TaskState.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIApplication+Compat.h"

@interface BackgroundTaskContainer ()

@property(atomic) bool debugMessages;
@property(atomic) bool showSizes;
@property(atomic) NSInteger bytesDone;

@end

@implementation BackgroundTaskContainer

- (void)dealloc {
    _callbackComplete = nil;
}

+ (BackgroundTaskContainer *)create:(id<BackgroundTaskDone>)done { // Here
    BackgroundTaskContainer *btc = [[[self class] alloc] init];
    btc.callbackComplete = done;
    return btc;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.showSizes = Settings.showSizes;
    }

    return self;
}

- (void)taskStartWithTotal:(NSInteger)total title:(NSString *)title {

    [super taskStartWithTotal:total title:title];

    self.title = title;
    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
      UIWindow *keyWindow = UIApplication.firstKeyWindow;

      if (self.progressModal == nil) {
          if ([self.callbackComplete
                  respondsToSelector:@selector(backgroundTaskStarted)]) {
              [self.callbackComplete backgroundTaskStarted];
          }

          self.progressModal = [[ProgressModalView alloc]
              initWithParent:keyWindow
                       items:total
                       title:self.title
                    delegate:(self.backgroundThread != nil ? self : nil)
                 orientation:[self.callbackComplete backgroundTaskOrientation]];

          [keyWindow addSubview:self.progressModal];
          [keyWindow bringSubviewToFront:self.progressModal];
          [keyWindow layoutSubviews];

          [self.progressModal addHelpText:self.help];
      } else {
          self.progressModal.totalItems = total;
      }
    }];

    if ([self.callbackComplete
            respondsToSelector:@selector(backgroundTaskWait)]) {
        while ([self.callbackComplete backgroundTaskWait]) {
            [NSThread sleepForTimeInterval:0.3];
        }
    }
}

- (void)taskSubtext:(NSString *)subtext {
    MainTask(^{
      [self addBytes:subtext];
    });
}

- (void)taskItemsDone:(NSInteger)itemsDone {
    MainTask(^{
      [self.progressModal itemsDone:itemsDone];
    });
}

- (void)taskTotalItems:(NSInteger)totalItems {
    MainTask(^{
      [self.progressModal totalItems:totalItems];
    });
}

- (void)finish {
    DEBUG_FUNC();

    bool cancelled =
        (self.backgroundThread != nil && self.backgroundThread.cancelled);
    [self.callbackComplete backgroundTaskDone:self.controllerToPop
                                    cancelled:cancelled];
    self.progressModal = nil;
    [super finish];
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
          UIAlertController *alert =
              [UIAlertController simpleOkWithTitle:nil message:self.errMsg];

          UIViewController *top = UIApplication.topViewController;

          [top presentViewController:alert
                            animated:YES
                          completion:^{
                            [self finish];
                          }];
          self.errMsg = nil;
      } else {
          DEBUG_LOG(@"finish");
          [self finish];
      }
    }];
}

- (void)taskSetHelpText:(NSString *)helpText {
    [self.progressModal addHelpText:helpText];
}

- (NSString *)size:(NSInteger)bytes fromCache:(bool)fromCache {
    NSString *result = nil;

    if (bytes < 1024) {
        result = [NSString stringWithFormat:@"%d B%@", (int)bytes,
                                            fromCache ? @" cached" : @""];
    } else if (bytes < (1024 * 1024)) {
        result =
            [NSString stringWithFormat:@"%.2f K%@", (((float)(bytes)) / 1024.0),
                                       fromCache ? @" cached" : @""];
    } else {
        result = [NSString stringWithFormat:@"%.2f MB%@",
                                            ((float)(bytes) / (1024 * 1024)),
                                            fromCache ? @" cached" : @""];
    }

    return result;
}

- (void)triMetXML:(TriMetXML *)xml startedFetchingData:(bool)fromCache {
    MainTask(^{
      [self.progressModal subItemsDone:1 totalSubs:5];
    });
}

- (void)triMetXML:(TriMetXML *)xml finishedFetchingData:(bool)fromCache {
    MainTask(^{
      [self.progressModal subItemsDone:4 totalSubs:5];
      [self addBytes:@""];
    });
}

#define kBytesToKB(B) ((double)(B) / 1024)
#define kBytesToMB(B) (((double)(B)) / (1024 * 1024))

- (NSString *)bytes:(long long)bytes {
    if (kBytesToKB(bytes) > 512) {
        return [NSString stringWithFormat:@"%.2f MB", kBytesToMB(bytes)];
    }

    return [NSString stringWithFormat:@"%.2f KB", kBytesToKB(bytes)];
}

- (void)addBytes:(NSString *)text {
    if (self.bytesDone > 0 && self.showSizes) {
        [self.progressModal
            addSubtext:[NSString stringWithFormat:@"%@ %@",
                                                  [self bytes:self.bytesDone],
                                                  text]];
    } else {
        [self.progressModal addSubtext:text];
    }
}

- (void)triMetXML:(TriMetXML *_Nonnull)xml
    incrementalBytes:(long long)incremental {
    self.bytesDone += incremental;

    MainTask(^{
      [self.progressModal subItemsDone:3 totalSubs:5];
      if (self.showSizes) {
          [self addBytes:@""];
      }
    });
}

- (void)progressDelegateCancel {
    [self taskCancel];
}

@end
