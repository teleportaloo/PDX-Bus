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



#import "SharedFile.h"
#import "DebugLogging.h"


@implementation SharedFile

- (bool)canUseSharedFilePath {
#ifdef PDXBUS_WATCH
    return NO;
    
#else
    return YES;
    
#endif
}

+ (instancetype)fileWithName:(NSString *)shortFileName initFromBundle:(bool)initFromBundle {
    return [[[self class] alloc] initWithFileName:shortFileName initFromBundle:initFromBundle];
}

- (instancetype)initWithFileName:(NSString *)shortFileName initFromBundle:(bool)initFromBundle {
    if ((self = [super init])) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *documentsDirectory = paths.firstObject;
        NSError *error = nil;
        self.shortName = shortFileName;
        
        NSString *fullPathName = [documentsDirectory stringByAppendingPathComponent:shortFileName];
        
        if ([self canUseSharedFilePath]) {
            NSURL *sharedContainer = [fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.teleportaloo.pdxbus"];
            
            self.urlToSharedFile = [sharedContainer URLByAppendingPathComponent:shortFileName];
            
            DEBUG_LOGS(self.urlToSharedFile.path);
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:self.urlToSharedFile.path]) {
                // If we are switching over to a shared file path we move the old one over, this is
                // transitional code.
                if ([fileManager fileExistsAtPath:fullPathName]) {
                    NSURL *oldFilePath = [NSURL fileURLWithPath:fullPathName isDirectory:NO];
                    
                    @try {
                        NSError *error = nil;
                        [fileManager moveItemAtURL:oldFilePath toURL:self.urlToSharedFile error:&error];
                    } @catch (NSException *exception)   {
                        ERROR_LOG(@"moveItemAtURL exception: %@ %@\n", exception.name, exception.reason);
                    }
                }
            }
        } else {
            self.urlToSharedFile = [[NSURL alloc] initFileURLWithPath:fullPathName isDirectory:NO];
        }
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.urlToSharedFile.path] && initFromBundle) {
            NSRange dot = [shortFileName rangeOfString:@"."];
            
            if ([shortFileName rangeOfString:@"."].location != NSNotFound) {
                NSString *stem = [shortFileName substringToIndex:dot.location];
                NSString *type = [shortFileName substringFromIndex:dot.location + 1];
                NSBundle *bundle = [NSBundle mainBundle];
                
                NSString *pathToDefaultPlist = [bundle pathForResource:stem ofType:type];
                NSURL *defaultPlist = [[NSURL alloc] initFileURLWithPath:pathToDefaultPlist isDirectory:NO];
                
                if (defaultPlist != nil && ![fileManager copyItemAtURL:defaultPlist toURL:self.urlToSharedFile error:&error]) {
                    NSAssert1(0, @"Failed to copy data with error message '%@'.", [error localizedDescription]);
                }
            }
        }
    }
    
    return self;
}

- (void)deleteFile {
    @try {
        if (self.urlToSharedFile != nil) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtURL:self.urlToSharedFile error:nil];
        }
    } @catch (NSException *exception)   {
        // if this fails don't worry
    }
}

- (NSMutableDictionary *)readFromFile:(NSPropertyListFormat *)format {
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:self.urlToSharedFile.path];
    NSMutableDictionary *result = nil;
    
    if (data != nil) {
        result = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:format error:&error];
        LOG_NSERROR(error);
    }
    
    return result;
}

- (void)debugCopy {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = paths.firstObject;
    NSString *fullPathName = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"debug_%@", self.shortName]];
    
    @try {
        NSError *error = nil;
        NSURL *debugFilePath = [NSURL fileURLWithPath:fullPathName isDirectory:NO];
        [fileManager copyItemAtURL:self.urlToSharedFile toURL:debugFilePath error:&error];
    } @catch (NSException *exception)   {
        ERROR_LOG(@"copyItemAtURL exception: %@ %@\n", exception.name, exception.reason);
    }
}

- (void)writeDictionaryBinary:(NSDictionary *)dict {
    bool written = false;
    NSError *error = nil;
    
    @try {
        NSData *data = [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
        
        LOG_NSERROR(error);
        
        if (data) {
            written = [data writeToFile:self.urlToSharedFile.path atomically:YES];
        }
    } @catch (NSException *exception)   {
        ERROR_LOG(@"writeToURL exception: %@ %@\n", exception.name, exception.reason);
    }
    
    if (!written) {
        ERROR_LOG(@"Failed to write the cache %@\n", [self.urlToSharedFile absoluteString]);
    }
    
#ifdef DEBUGLOGGING
    else {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.urlToSharedFile.path error:nil];
        
        if (fileAttributes) {
            NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
            DEBUG_LOG(@"%@ size:%llu (%llu K)\n", self.urlToSharedFile.path, fileSizeNumber.unsignedLongLongValue, fileSizeNumber.unsignedLongLongValue / 1024);
            DEBUG_LOG(@"%@ entries:%llu\n", self.urlToSharedFile.path, (unsigned long long)dict.count);
        }
        
        [self debugCopy];
    }
#endif
}

- (void)writeDictionary:(NSDictionary *)dict {
    //
    // Crash logs show that this often crashes here - but it is hard
    // to say why.  This is my attempt to catch that - saving the
    // cache is nice but if it fails we'll catch it and not worry.
    //
    bool written = false;
    
    @try {
        written = [dict writeToURL:self.urlToSharedFile atomically:YES];
    } @catch (NSException *exception)   {
        ERROR_LOG(@"writeToURL exception: %@ %@\n", exception.name, exception.reason);
    }
    
    if (!written) {
        ERROR_LOG(@"Failed to write the cache %@\n", [self.urlToSharedFile absoluteString]);
        // clear the local cache, as I assume it is corrupted.
        [self deleteFile];
    }
    
#ifdef DEBUGLOGGING
    else {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.urlToSharedFile.path error:nil];
        
        if (fileAttributes) {
            NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
            DEBUG_LOG(@"%@ size:%llu (%llu K)\n", self.urlToSharedFile.path, fileSizeNumber.unsignedLongLongValue, fileSizeNumber.unsignedLongLongValue / 1024);
            DEBUG_LOG(@"%@ entries:%llu\n", self.urlToSharedFile.path, (unsigned long long)dict.count);
        }
        
        [self debugCopy];
    }
#endif
}

@end
