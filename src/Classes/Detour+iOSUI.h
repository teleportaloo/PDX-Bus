//
//  DetourUI.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/5/16.
//  Copyright © 2016 Teleportaloo. All rights reserved.
//

#import "Detour.h"

#define kDetourResuseIdentifier @"Detour"
#define kSystemDetourResuseIdentifier @"SystemAlert"

@interface Detour (iOSUI)

- (NSString*)reuseIdentifer;
- (NSString*)formattedHeader;
- (NSString*)formattedDescription;
- (NSString*)formattedDescriptionWithHeader;
- (NSString*)formattedDescriptionWithoutInfo;
- (void)populateCell:(UITableViewCell *)cell font:(UIFont*)font routeDisclosure:(bool)routeDisclosure;
- (bool)hasInfo;

+ (UILabel *)create_UITextView:(UIFont *)font;

@end
