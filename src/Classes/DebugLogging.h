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
// #if 0
#define DEBUG_PRINTF(format, args...) printf(format, ##args)
#define DEBUG_LOG(format, args...) NSLog(format, ##args)
#define DEBUG 1

#else

#define DEBUG_PRINTF(format, args...)
#define DEBUG_LOG(format, args...)
#undef DEBUG

#endif

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



