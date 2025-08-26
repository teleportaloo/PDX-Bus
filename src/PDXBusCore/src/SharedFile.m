//
//  SharedFile.m
//  PDXBusCore
//
//  Created by Andrew Wallace on 5/15/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogSettings

#import "SharedFile.h"
#import "DebugLogging.h"
#import "NSString+DocPath.h"

#define PDXBUS_GROUP @"group.teleportaloo.pdxbus"

@implementation NSMutableDictionary (DeepCopy)

- (NSDictionary *)deepCopy {
    CFPropertyListRef localCopy = CFPropertyListCreateDeepCopy(
        kCFAllocatorDefault, (__bridge CFPropertyListRef)(self),
        kCFPropertyListImmutable);
    if (localCopy) {
        NSDictionary *arc = (__bridge NSDictionary *)localCopy;
        CFRelease(localCopy);
        return arc;
    }

    return nil;
}

@end

@implementation SharedFile

+ (bool)canUseSharedFilePath {
#ifdef PDXBUS_WATCH
    return NO;

#else
    return YES;

#endif
}

+ (instancetype)fileWithName:(NSString *)shortFileName
              initFromBundle:(bool)initFromBundle
                        sync:(NSObject *)sync {
    return [[[self class] alloc] initWithFileName:shortFileName
                                   initFromBundle:initFromBundle
                                             sync:sync];
}

+ (void)removeFileWithName:(NSString *)shortFileName {

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *fullPathName = shortFileName.fullDocPath;

    if ([fileManager fileExistsAtPath:fullPathName]) {
        NSURL *oldFilePath = [NSURL fileURLWithPath:fullPathName
                                        isDirectory:NO];

        @try {
            [fileManager removeItemAtPath:oldFilePath.path error:nil];
        } @catch (NSException *exception) {
            ERROR_LOG(@"moveItemAtURL exception: %@ %@\n", exception.name,
                      exception.reason);
        }
    }

    if ([SharedFile canUseSharedFilePath]) {
        NSURL *sharedContainer = [fileManager
            containerURLForSecurityApplicationGroupIdentifier:PDXBUS_GROUP];
        NSURL *urlToSharedFile =
            [sharedContainer URLByAppendingPathComponent:shortFileName];

        if ([fileManager fileExistsAtPath:urlToSharedFile.path]) {
            @try {
                [fileManager removeItemAtPath:urlToSharedFile.path error:nil];
            } @catch (NSException *exception) {
                ERROR_LOG(@"removeItemAtPath exception: %@ %@\n",
                          exception.name, exception.reason);
            }
        }
    }
}

- (instancetype)initWithFileName:(NSString *)shortFileName
                  initFromBundle:(bool)initFromBundle
                            sync:(NSObject *)sync {
    if ((self = [super init])) {

        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        self.shortName = shortFileName;

        NSString *fullPathName = shortFileName.fullDocPath;

        if ([SharedFile canUseSharedFilePath]) {
            NSURL *sharedContainer = [fileManager
                containerURLForSecurityApplicationGroupIdentifier:PDXBUS_GROUP];

            self.urlToSharedFile =
                [sharedContainer URLByAppendingPathComponent:shortFileName];

            DEBUG_LOG_NSString(self.urlToSharedFile.path);

            if (![[NSFileManager defaultManager]
                    fileExistsAtPath:self.urlToSharedFile.path]) {
                // If we are switching over to a shared file path we move the
                // old one over, this is transitional code.
                if ([fileManager fileExistsAtPath:fullPathName]) {
                    NSURL *oldFilePath = [NSURL fileURLWithPath:fullPathName
                                                    isDirectory:NO];

                    @try {
                        NSError *error = nil;
                        [fileManager moveItemAtURL:oldFilePath
                                             toURL:self.urlToSharedFile
                                             error:&error];
                    } @catch (NSException *exception) {
                        ERROR_LOG(@"moveItemAtURL exception: %@ %@\n",
                                  exception.name, exception.reason);
                    }
                }
            }
        } else {
            self.urlToSharedFile =
                [[NSURL alloc] initFileURLWithPath:fullPathName isDirectory:NO];
        }

        if (![[NSFileManager defaultManager]
                fileExistsAtPath:self.urlToSharedFile.path] &&
            initFromBundle) {
            NSRange dot = [shortFileName rangeOfString:@"."];

            if ([shortFileName rangeOfString:@"."].location != NSNotFound) {
                NSString *stem = [shortFileName substringToIndex:dot.location];
                NSString *type =
                    [shortFileName substringFromIndex:dot.location + 1];
                NSBundle *bundle = [NSBundle mainBundle];

                NSString *pathToDefaultPlist = [bundle pathForResource:stem
                                                                ofType:type];
                NSURL *defaultPlist =
                    [[NSURL alloc] initFileURLWithPath:pathToDefaultPlist
                                           isDirectory:NO];

                if (defaultPlist != nil &&
                    ![fileManager copyItemAtURL:defaultPlist
                                          toURL:self.urlToSharedFile
                                          error:&error]) {
                    NSAssert1(0,
                              @"Failed to copy data with error message '%@'.",
                              [error localizedDescription]);
                }
            }
        }
    }

    self.bgGroup = dispatch_group_create();
    self.bgQueue = dispatch_queue_create("org.teleportaloo.pdxbus.files",
                                         DISPATCH_QUEUE_SERIAL);

    return self;
}

- (void)deleteFile {
    dispatch_group_async(self.bgGroup, self.bgQueue, ^{
      @try {
          if (self.urlToSharedFile != nil) {
              NSFileManager *fileManager = [NSFileManager defaultManager];
              [fileManager removeItemAtURL:self.urlToSharedFile error:nil];
          }
      } @catch (NSException *exception) {
          // if this fails don't worry
      }
    });
}

- (NSMutableDictionary *)readFromFile:(NSPropertyListFormat *)format {
#ifdef DEBUGLOGGING
    if (dispatch_group_wait(self.bgGroup, DISPATCH_TIME_NOW) > 0) {
        DEBUG_LOG(@"WAITING FOR DISPATCHES %@", self.shortName);
        dispatch_group_wait(self.bgGroup, DISPATCH_TIME_FOREVER);
    }
#else
    dispatch_group_wait(self.bgGroup, DISPATCH_TIME_FOREVER);
#endif

    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:self.urlToSharedFile.path];
    NSMutableDictionary *result = nil;

    if (data != nil) {
        result = [NSPropertyListSerialization
            propertyListWithData:data
                         options:NSPropertyListMutableContainers
                          format:format
                           error:&error];
        LOG_NSError(error);
    }

    return result;
}

- (void)debugCopy {
    dispatch_group_async(self.bgGroup, self.bgQueue, ^{
      NSFileManager *fileManager = [NSFileManager defaultManager];
      NSString *fullPathName =
          [NSString stringWithFormat:@"debug_%@", self.shortName].fullDocPath;
      NSURL *debugFilePath = [NSURL fileURLWithPath:fullPathName
                                        isDirectory:NO];
      NSError *error = nil;

      @try {
          [fileManager removeItemAtURL:debugFilePath error:&error];
      } @catch (NSException *exception) {
          ERROR_LOG(@"removeItemAtURL exception: %@ %@\n", exception.name,
                    exception.reason);
      }

      @
      try {
          [fileManager copyItemAtURL:self.urlToSharedFile
                               toURL:debugFilePath
                               error:&error];
      } @catch (NSException *exception) {
          ERROR_LOG(@"copyItemAtURL exception: %@ %@\n", exception.name,
                    exception.reason);
      }
    });
}

- (void)writeDictionaryBinary:(NSDictionary *)dict {
    NSDictionary *copy = dict.deepCopy;

    dispatch_group_async(self.bgGroup, self.bgQueue, ^{
      bool written = false;
      NSError *error = nil;

      @try {
          NSData *data = [NSPropertyListSerialization
              dataWithPropertyList:copy
                            format:NSPropertyListBinaryFormat_v1_0
                           options:0
                             error:&error];

          LOG_NSError(error);

          if (data) {
              written = [data writeToFile:self.urlToSharedFile.path
                               atomically:YES];
          }
      } @catch (NSException *exception) {
          ERROR_LOG(@"writeToURL exception: %@ %@\n", exception.name,
                    exception.reason);
      }

      if (!written) {
          ERROR_LOG(@"Failed to write the cache %@\n",
                    [self.urlToSharedFile absoluteString]);
      }

#ifdef DEBUGLOGGING
      else {
          NSDictionary *fileAttributes = [[NSFileManager defaultManager]
              attributesOfItemAtPath:self.urlToSharedFile.path
                               error:nil];

          if (fileAttributes) {
              NSNumber *fileSizeNumber =
                  [fileAttributes objectForKey:NSFileSize];
              DEBUG_LOG(@"%@ size:%llu (%llu K)\n", self.urlToSharedFile.path,
                        fileSizeNumber.unsignedLongLongValue,
                        fileSizeNumber.unsignedLongLongValue / 1024);
              DEBUG_LOG(@"%@ entries:%llu\n", self.urlToSharedFile.path,
                        (unsigned long long)dict.count);
          }

          [self debugCopy];
      }
#endif
    });
}

- (void)writeDictionary:(NSDictionary *)dict {
    NSDictionary *copy = dict.deepCopy;

    dispatch_group_async(self.bgGroup, self.bgQueue, ^{
      bool written = false;
      @try {
          NSError *error = nil;
          written = [copy writeToURL:self.urlToSharedFile error:&error];
          LOG_NSError_info(error, @"writeToURL");
      } @catch (NSException *exception) {
          ERROR_LOG(@"writeToURL exception: %@ %@\n", exception.name,
                    exception.reason);
      }

      if (!written) {
          ERROR_LOG(@"Failed to write the cache %@\n",
                    [self.urlToSharedFile absoluteString]);
          // clear the local cache, as I assume it is corrupted.
          [self deleteFile];
      }

#ifdef DEBUGLOGGING
      else {
          NSDictionary *fileAttributes = [[NSFileManager defaultManager]
              attributesOfItemAtPath:self.urlToSharedFile.path
                               error:nil];

          if (fileAttributes) {
              NSNumber *fileSizeNumber =
                  [fileAttributes objectForKey:NSFileSize];
              DEBUG_LOG(@"%@ size:%llu (%llu K)\n", self.urlToSharedFile.path,
                        fileSizeNumber.unsignedLongLongValue,
                        fileSizeNumber.unsignedLongLongValue / 1024);
              DEBUG_LOG(@"%@ entries:%llu\n", self.urlToSharedFile.path,
                        (unsigned long long)dict.count);
          }

          [self debugCopy];
      }
#endif
    });
}

@end
