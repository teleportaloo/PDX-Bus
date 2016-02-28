//
//  AppDelegateMethods.h
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#ifndef __DEBUG_H
#define __DEBUG_H 1

// Often it is useful to have lots of logging, but often not by default on
// the device - slows it down a lot.
#ifdef DEBUGLOGGING

// #define XMLLOGGING 1

#define DEBUG_PRINTF(format, args...) printf(format, ##args)
#define DEBUG_LOG(s, ...)       NSLog(@"<%s:%d> %@", __func__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])
#define DEBUG_LOG_RAW(s, ...)   NSLog(s, ##__VA_ARGS__)

#define DEBUG 1
#define DEBUG_MODE @"debug on"

#else

#define DEBUG_PRINTF(format, args...)
#define DEBUG_LOG(format, args...)
#define DEBUG_LOG_RAW(s, ...)


#undef DEBUG
#define DEBUG_MODE @""

#endif

#define DEBUG_FUNC()   DEBUG_LOG(@"enter")
#define DEBUG_FUNCEX() DEBUG_LOG(@"exit")
#define DEBUG_LOGF(x)  DEBUG_LOG(@"%s: %f", #x, (float)(x))
#define DEBUG_LOGLU(x) DEBUG_LOG(@"%s: %lu",#x, (unsigned long)(x))
#define DEBUG_LOGL(x)  DEBUG_LOG(@"%s: %ld",#x,  (long)(x))
#define DEBUG_LOGS(x)  DEBUG_LOG(@"%s: %@", #x, (x))
#define DEBUG_LOGB(x)  DEBUG_LOG(@"%s: %@", #x, ((x)? @"TRUE" : @"FALSE"))
#define DEBUG_LOGO(x)  DEBUG_LOG(@"%s: %@", #x, (x).debugDescription);
#define DEBUG_LOGR(R)  DEBUG_LOG(@"%s: (%f,%f,%f,%f)", #R, (R).origin.x, (R).origin.y, (R).size.width, (R).size.height);
#define DEBUG_LOGRC(R) DEBUG_LOG(@"%s: retainCount %lu)", #R, (unsigned long)(R).retainCount);


#define ERROR_LOG(s, ...) NSLog(@"**** ERROR **** <%s:%d> %@", __func__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])
#define LOG_PARSE_ERROR(error) if (error) ERROR_LOG(@"Parse error: %@\n", error.description)

// The following define is used to make the app create some arrays and databases
// used for the Rail Stations view and Rail Map Screen - don't ever ship with this
// on as it does some odd logging and creates a database that won't be used.

// #define CREATE_MAX_ARRAYS 1

#ifdef CREATE_MAX_ARRAYS
#define CODE_PRINTF(format, args...) printf(format, ##args)
#define CODE_LOG(format, args...) NSLog(format, ##args)
#else
#define CODE_PRINTF(format, args...)
#define CODE_LOG(format, args...)
#endif

#endif



