//
//  SharedFile.m
//  PDXBusCore
//
//  Created by Andrew Wallace on 5/15/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "SharedFile.h"
#import "DebugLogging.h"
#import <UIKit/UIKit.h>

@implementation SharedFile

@synthesize urlToSharedFile = _urlToSharedFile;

- (void)dealloc
{
    self.urlToSharedFile = nil;
    
    [super dealloc];
}

- (bool)canUseSharedFilePath
{
    // return NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    return ([fileManager respondsToSelector:@selector(containerURLForSecurityApplicationGroupIdentifier:)]);
}

- (id)initWithFileName:(NSString *)shortFileName initFromBundle:(bool)initFromBundle
{
    
    if ((self = [super init]))
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSError *error = nil;
        
        NSString *fullPathName = [documentsDirectory stringByAppendingPathComponent:shortFileName];
        
        if ([self canUseSharedFilePath])
        {
            NSURL *sharedContainer = [fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.teleportaloo.pdxbus"];
            
            self.urlToSharedFile = [sharedContainer URLByAppendingPathComponent:shortFileName];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:[self.urlToSharedFile path]])
            {
                // If we are switching over to a shared file path we move the old one over, this is
                // transitional code.
                if ([fileManager fileExistsAtPath:fullPathName])
                {
                    NSURL *oldFilePath = [NSURL fileURLWithPath:fullPathName isDirectory:NO];
                    
                    @try {
                        NSError *error = nil;
                        [fileManager moveItemAtURL:oldFilePath toURL:self.urlToSharedFile error:&error];
                    }
                    @catch (NSException *exception)
                    {
                        ERROR_LOG(@"moveItemAtURL exception: %@ %@\n", exception.name, exception.reason );
                    }
                }
            }
        }
        else
        {
            self.urlToSharedFile = [[[NSURL alloc] initFileURLWithPath:fullPathName isDirectory:NO] autorelease];
        }
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[self.urlToSharedFile path]] && initFromBundle)
        {
            NSRange dot = [shortFileName rangeOfString:@"."];
            
            if ([shortFileName rangeOfString:@"."].location != NSNotFound)
            {
                NSString *stem = [shortFileName substringToIndex:dot.location];
                NSString *type = [shortFileName substringFromIndex:dot.location+1];
                
                NSString *pathToDefaultPlist = [[NSBundle mainBundle] pathForResource:stem ofType:type];
                NSURL *defaultPlist = [[NSURL alloc] initFileURLWithPath:pathToDefaultPlist isDirectory:NO];
                if (defaultPlist!=nil && ![fileManager copyItemAtURL:defaultPlist toURL:self.urlToSharedFile  error:&error])
                {
                    NSAssert1(0, @"Failed to copy data with error message '%@'.", [error localizedDescription]);
                }
                
            }
     
        }
    }
    
    return self;
    
}

- (void)deleteFile
{
    @try {
        if (self.urlToSharedFile !=nil)
        {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtURL:self.urlToSharedFile error:nil];
        }
    }
    @catch (NSException *exception) {
        // if this fails don't worry
    }

}

- (void)writeDictionary:(NSDictionary *)dict
{
    //
    // Crash logs show that this often crashes here - but it is hard
    // to say why.  This is my attempt to catch that - saving the
    // cache is nice but if it fails we'll catch it and not worry.
    //
    bool written = false;
    
    @try {
        written = [dict writeToURL:self.urlToSharedFile atomically:YES];
    }
    @catch (NSException *exception)
    {
        ERROR_LOG(@"writeToURL exception: %@ %@\n", exception.name, exception.reason );
    }
    
    if (!written)
    {
        UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Internal error"
                                                           message:@"Could not write to file."
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil] autorelease];
        [alert show];
        
        ERROR_LOG(@"Failed to write the cache %@\n", [self.urlToSharedFile absoluteString]);
        // clear the local cache, as I assume it is corrupted.
        [self deleteFile];
    }
    
}

@end
