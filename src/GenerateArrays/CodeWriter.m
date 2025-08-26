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
#import "../PDXBusCore/src/NSString+DocPath.h"
#import "../CommonCode/TaskDispatch.h"
#import "DebugLogging.h"

@interface CodeWriter ()

@property NSString *filename;
@property NSString *finalFilename;

@end

@implementation CodeWriter

- (instancetype)init {
    if ((self = [super init])) {

        self.filename = @"code.txt".fullDocPath;
    }

    return self;
}

+ (void)file:(NSString *)str {
    CodeWriter.sharedInstance.finalFilename = str;
    [[NSFileManager defaultManager]
        removeItemAtPath:CodeWriter.sharedInstance.filename
                   error:NULL];
}

+ (void)write:(NSString *)str {
    FILE *fp = fopen([CodeWriter.sharedInstance.filename UTF8String], "a");

    int rc = fprintf(fp, "%s\n", [str UTF8String]);
    if (rc < 0) {
        printf("errno=%d, err_msg=\"%s\"\n", errno, strerror(errno));
    }

    fclose(fp);
}

+ (void)moveIntoPlace {
    NSError *error = nil;

    [[NSFileManager defaultManager]
        removeItemAtPath:CodeWriter.sharedInstance.finalFilename
                   error:&error];

    LOG_NSError_info(error, @"removeItemAtPath");

    [[NSFileManager defaultManager]
        moveItemAtPath:CodeWriter.sharedInstance.filename
                toPath:CodeWriter.sharedInstance.finalFilename
                 error:&error];

    LOG_NSError_info(error, @"moveItemAtPath");
}

#define NSLogCode(FORMAT, ...)                                                 \
    printf("%s\n",                                                             \
           [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

+ (void)dump {
    NSError *error = nil;
    NSString *code =
        [NSString stringWithContentsOfFile:CodeWriter.sharedInstance.filename
                                  encoding:NSUTF8StringEncoding
                                     error:&error];

    LOG_NSError(error);

    //------------------------------------------------------------------------------"
    NSLogCode(
        @"\n//################ Machine Generated Code "
        @"######################################\n%@\n//############# End of "
        @"Machine Generated Code ##################################\n",
        code);

    //
}

+ (CodeWriter *)sharedInstance {
    static CodeWriter *singleton = nil;

    DoOnce(^{
      singleton = [[CodeWriter alloc] init];
    });

    return singleton;
}

@end
