//
//  DebugLogging.h
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#ifndef __DEBUG_H
#define __DEBUG_H 1

#import <Foundation/Foundation.h>

enum
{
    kLogSettings            = 0x00001,
    kLogNetworking          = 0x00002,
    kLogXML                 = 0x00004,
    kLogParsing             = 0x00008,
    kLogTask                = 0x00010,
    kLogUserInterface       = 0x00020,
    kLogDataManagement      = 0x00040,
    kLogTests               = 0x00080,
    kLogTestFiles           = 0x00100,
    kLogIntents             = 0x00200,
    kLogAlarms              = 0x00400,
    kLogWeb                 = 0x00800
};


// #define PROFILING

// Often it is useful to have lots of logging, but often not by default on
// the device - slows it down a lot.
#ifdef DEBUGLOGGING

@interface DebugLogging : NSObject

@property (nonatomic) NSUInteger logLevel;
@property (nonatomic) NSString *logLevelString;

+ (instancetype)sharedInstance;

@end


// The test data accesses TestData.plist which is copied over to the debug version.
// It contains an array of URLs to use per class, the URLs will be used in order and then
// starts all over again.
// #define XML_TEST_DATA "System-wide Detours"
// #define XML_TEST_DATA "Departure"
// #define XML_TEST_DATA "Streetcar Messages"
// #define XML_TEST_DATA "KML"
// #define XML_TEST_DATA "Complex Streetcar Messages"

#define DEBUG_ON_FOR_FILE              ((DebugLogging.sharedInstance.logLevel & DEBUG_LEVEL_FOR_FILE))
#define DEBUG_AND(X)                   (DEBUG_ON_FOR_FILE) ? ((X)) : (FALSE)
#define DEBUG_PRINTF(format, args ...) if (DEBUG_ON_FOR_FILE) { printf("<%04x>",DEBUG_LEVEL_FOR_FILE); printf(format, ## args); }
#define DEBUG_LOG(s, ...)              if (DEBUG_ON_FOR_FILE) { NSLog(@"<%04x-%s:%d> %@", DEBUG_LEVEL_FOR_FILE, __func__, __LINE__, [NSString stringWithFormat:(s), ## __VA_ARGS__]); }
#define DEBUG_LOG_RAW(s, ...)          if (DEBUG_ON_FOR_FILE) { NSLog(s, ## __VA_ARGS__); }
#define DEBUG                          1
#define DEBUG_MODE                     [NSString stringWithFormat:@"(debug on for %@)",DebugLogging.sharedInstance.logLevelString]
#define DEBUG_BREAK                    raise(SIGINT)
#define DEBUG_LOG_MAYBE(C, s, ...)     if (DEBUG_ON_FOR_FILE && (C)) { NSLog(@"<%04x-%s:%d> %@", DEBUG_LEVEL_FOR_FILE,__func__, __LINE__, [NSString stringWithFormat:(s), ## __VA_ARGS__]); }
#define DEBUG_TEST_WARNING(s, ...)      if (DEBUG_ON_FOR_FILE) { NSLog(@"<%04x-%s:%d> *** TEST WARNING %@", DEBUG_LEVEL_FOR_FILE, __func__, __LINE__, [NSString stringWithFormat:(s), ## __VA_ARGS__]); }
#define DEBUG_LOG_ASYNC(D)              dispatch_async(dispatch_get_main_queue(), ^{ D; })

#else // ifdef DEBUGLOGGING

#define DEBUG_ON_FOR_FILE              (FALSE)
#define DEBUG_AND(X)                   (FALSE)
#define DEBUG_PRINTF(format, args ...)
#define DEBUG_LOG(format, args ...)
#define DEBUG_LOG_RAW(s, ...)
#define DEBUG_LOG_MAYBE(C, s, ...)
#define DEBUG_TEST_WARNING(s, ...)
#define DEBUG_LOG_ASYNC(D)


#undef DEBUG
#define DEBUG_MODE @""

#endif // ifdef DEBUGLOGGING

#define DEBUG_CLASS(x)         DEBUG_LOG(@"class of %s is %@", #x, NSStringFromClass((x).class))
#define DEBUG_FUNC()           DEBUG_LOG(@"enter")
#define DEBUG_HERE()           DEBUG_LOG(@"here")
#define DEBUG_CASE(x)          DEBUG_LOG(@"Case    %s: %lu",#x, (unsigned long)(x))
#define DEBUG_DEFAULT(x)       DEBUG_LOG(@"Default %s: %lu",#x, (unsigned long)(x))

#define DEBUG_FUNCEX()         DEBUG_LOG(@"exit")
#define DEBUG_LOGF(x)          DEBUG_LOG(@"%s: %f", #x, (float)(x))
#define DEBUG_LOGD(x)          DEBUG_LOG(@"%s: %f", #x, (double)(x))
#define DEBUG_LOGLU(x)         DEBUG_LOG(@"%s: %lu",#x, (unsigned long)(x))
#define DEBUG_LOGLX(x)         DEBUG_LOG(@"%s: %lx",#x, (unsigned long)(x))
#define DEBUG_LOGL(x)          DEBUG_LOG(@"%s: %ld",#x,  (long)(x))
#define DEBUG_LOGS(x)          DEBUG_LOG(@"%s: %@", #x, (x))
#define DEBUG_LOGB(x)          DEBUG_LOG(@"%s: %@", #x, ((x) ? @"TRUE" : @"FALSE"))
#define DEBUG_LOGO(x)          DEBUG_LOG(@"%s: %@", #x, ((x) != nil) ? (x).debugDescription : @"nil");
#define DEBUG_LOGR(R)          DEBUG_LOG(@"%s: (%f,%f,%f,%f)", #R, (R).origin.x, (R).origin.y, (R).size.width, (R).size.height);
#define DEBUG_LOGPT(P)         DEBUG_LOG(@"%s: (%f,%f)", #P, (P).x, (P).y);
#define DEBUG_LOGDATE(D)       DEBUG_LOG(@"%s: %@", #D,  [NSDateFormatter localizedStringFromDate:D dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]);

#define DEBUG_LOGRC(R)
#define DEBUG_LOGIP(I)         DEBUG_LOG(@"%s: section %d row %d", #I, (int)((I).section), (int)((I).row));
#define DEBUG_LOGP(P)          DEBUG_LOG(@"%s: %p", #P, (void *)P)
#define DEBUG_LOGC(X)          DEBUG_LOG(@"%s: %s", #X, object_getClassName(X))

#define ERROR_LOG(s, ...)      { NSLog(@"**** ERROR **** <%s:%d> %@", __func__, __LINE__, [NSString stringWithFormat:(s), ## __VA_ARGS__]); }
#define LOG_PARSE_ERROR(error) if (error) ERROR_LOG(@"Parse error: %@\n", error.debugDescription)
#define LOG_NSERROR(error)     if (error) ERROR_LOG(@"NSError: %@\n", error.description)
#define NSSTR_FUNC             [NSString stringWithUTF8String:__func__]

// This can be used for trivial profiling - it will show the accumilated time in
// a function.

#ifdef PROFILING
#ifndef PDXBUS_WATCH
#import <QuartzCore/QuartzCore.h>

#define PROFILING_ENTER_FUNCTION double startTime = CACurrentMediaTime();
#define PROFILING_EXIT_FUNCTION             \
    static double inHere;                   \
    double endTime = CACurrentMediaTime();  \
    inHere += (endTime - startTime);        \
    DEBUG_LOGD(inHere);
#else
#define PROFILING_ENTER_FUNCTION
#define PROFILING_EXIT_FUNCTION
#endif

#else
#define PROFILING_ENTER_FUNCTION
#define PROFILING_EXIT_FUNCTION
#endif
#endif // ifndef __DEBUG_H
