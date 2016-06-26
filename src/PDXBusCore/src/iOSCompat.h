//
//  iOSCompat.h
//  PDXBusCore
//
//  Created by Andrew Wallace on 2/29/16.
//  Copyright © 2016 Teleportaloo. All rights reserved.
//

#ifndef iOSCompat_h
#define iOSCompat_h

#define compatSetIfExists(O,S,V) if ([O respondsToSelector:@selector(S)]) { [O S V]; }
#define compatCallIfExists(O,S)  if ([O respondsToSelector:@selector(S)]) { [O S]; }

#endif /* iOSCompat_h */
