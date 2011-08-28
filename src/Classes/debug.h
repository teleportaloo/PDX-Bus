//
//  AppDelegateMethods.h
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#ifndef __DEBUG_H
#define __DEBUG_H 1

// Often it is useful to have lots of logging, but often not by default on
// the device - slows it down a lot.
// #ifdef DEBUGLOGGING
#if 0
#define DEBUG_PRINTF(format, args...) printf(format, ##args)
#define DEBUG_LOG(format, args...) NSLog(format, ##args)
#define DEBUG 1

#else

#define DEBUG_PRINTF(format, args...)
#define DEBUG_LOG(format, args...)
#undef DEBUG

#endif

#endif



