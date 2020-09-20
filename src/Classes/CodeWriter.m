//
//  CodeWriter.m
//  PDX Bus
//
//  Created by Andrew Wallace on 3/7/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "CodeWriter.h"

@interface CodeWriter ()

@property NSString *filename;

@end

@implementation CodeWriter

- (instancetype)init {
    if ((self = [super init])) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = paths.firstObject;
        self.filename = [documentsDirectory stringByAppendingPathComponent:@"code.txt"];
    }
    
    return self;
}

+ (void)write:(NSString *)str {
    FILE *fp = fopen([CodeWriter.sharedInstance.filename UTF8String], "a");
    
    fprintf(fp, "%s\n", [str UTF8String]);
    fclose(fp);
}

+ (void)dump {
    NSString *code = [NSString stringWithContentsOfFile:CodeWriter.sharedInstance.filename encoding:NSUTF8StringEncoding error:NULL];
    
    //------------------------------------------------------------------------------"
    NSLog(@"\n//################ Machine Generated Code ######################################\n%@\n//############# End of Machine Generated Code ##################################\n", code);
    
    [[NSFileManager defaultManager] removeItemAtPath:CodeWriter.sharedInstance.filename error:NULL];
}

+ (CodeWriter *)sharedInstance {
    static CodeWriter *singleton = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        singleton = [[CodeWriter alloc] init];
    });
    
    return singleton;
}

@end
