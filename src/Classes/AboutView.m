//
//  About.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AboutView.h"
#import "WebViewController.h"
#import "TriMetXML.h"
#import "WhatsNewView.h"
#import "SupportView.h"
#import "DebugLogging.h"
#import "NSString+Helper.h"
#import "LinkCell.h"
#import "Icons.h"

#import <sys/types.h>
#import <sys/sysctl.h>

enum SECTIONS {
    kSectionIntro=0,
    kSectionWeb,
    kSectionLegal,
    kSectionVersions,
    kSectionMachine,
    kSectionThanks,
    kSections
};

enum INTRO_ROWS {
    kSectionIntroRowIntro=0,
    kSectionIntroRowNew,
    kSectionIntroRows
};

#define kLinkFull   @"LinkF"
#define kLinkMobile @"LinkM"
#define kIcon       @"Icon"
#define kCellText   @"Title"

#define kCellLink   @"pdxbuslink"

@interface AboutView () {
    NSArray<NSDictionary<NSString *, NSString *> *> *_links;
    NSArray<NSDictionary<NSString *, NSString *> *> *_legal;
    NSAttributedString *_thanksText;
    NSAttributedString *_introText;
    NSArray<NSString *> *_versions;
}

@end

@implementation AboutView


#pragma mark Helper functions

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

#pragma mark Table view methods


- (NSString *)platform {
    size_t size;
    
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    
    free(machine);
    return platform;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"About", @"About screen title");
        
#define ATTR(X) [StringHelper formatAttributedString:X font:self.paragraphFont]
        
        NSString *text = [NSString stringWithFormat:
                          NSLocalizedString(
                                            @"Route and departure data provided by permission of #B#bTriMet#b#D.\n\n"
                                            "This app was developed as a volunteer effort to provide a service for #B#bTriMet#b#D riders. The developer has no affiliation with #B#bTriMet#b#D, or Apple.\n\n"
                                            "Lots of #ithanks#i...\n\n"
                                            "...to portlandtransport.com for help and advice;\n\n"
                                            "...to #iScott#i, #iTim#i and #iMike#i for beta testing and suggestions;\n\n"
                                            "...to #iScott#i (again) for lending me his brand new iPad;\n\n"
                                            "...to #iScott#i (again 😃) for feedback on the watch app;\n\n"
                                            "...to #iRob Alan#i for the stylish icon; and\n\n"
                                            "...to CivicApps.org for Awarding PDX Bus the #i#bMost Appealing#b#i and #b#iBest in Show#b#i awards in July 2010.\n\n"
                                            "Special thanks to #R#b#iKen#i#b#D for putting up with all this.\n\n"
                                            "\nCopyright (c) 2008-2020\nAndrew Wallace\n(See legal section above for other copyright owners and attrbutions).",
                                            @"Dedication text")
                          ];
        
        _versions = @[
            [NSString stringWithFormat:@"#DApp: #b#B%@.%@ (%s)", [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"], [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"], __DATE__],
            [NSString stringWithFormat:@"#DType: #b#B%@", UIDevice.currentDevice.model],
            [NSString stringWithFormat:@"#DiOS: #b#B%@", UIDevice.currentDevice.systemVersion],
            [NSString stringWithFormat:@"#DDevice: #b#B%@", self.platform],
            [NSString stringWithFormat:@"#DBuild: #b#B%lu bits %@", sizeof(NSInteger) * 8, DEBUG_MODE]
        ];
        
        _thanksText = FormatTextPara(text);
        
        _introText = FormatTextPara(@"One developer writes #bPDX Bus#b as a #ivolunteer effort#i, with a little help from friends and the local community. He has no affiliation with #b#BTriMet#b#D, but he happens to ride buses and MAX on most days.\n\n"
                                    "This is free because I do it for fun. #i#b#GReally#i#b#D.");
        
        _links = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about-links" ofType:@"plist"]];
        _legal = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about-legal" ofType:@"plist"]];
        
        _hideButton = NO;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [self.table registerNib:[LinkCell nib] forCellReuseIdentifier:kCellLink];
    
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!_hideButton) {
        UIBarButtonItem *info = [[UIBarButtonItem alloc]
                                 initWithTitle:NSLocalizedString(@"Help", @"Help button")
                                 style:UIBarButtonItemStylePlain
                                 target:self action:@selector(infoAction:)];
        
        
        self.navigationItem.rightBarButtonItem = info;
    }
}

- (void)infoAction:(id)sender {
    SupportView *infoView = [SupportView viewController];
    
    // Push the detail view controller
    
    infoView.hideButton = YES;
    
    [self.navigationController pushViewController:infoView animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case kSectionThanks:
            return NSLocalizedString(@"Thanks!", @"Thanks section header");
            
        case kSectionWeb:
            return NSLocalizedString(@"Links", @"Link section header");
            
        case kSectionLegal:
            return NSLocalizedString(@"Attributions and Legal", @"Section header");
            
        case kSectionVersions:
            return NSLocalizedString(@"Versions", @"Section header");
            
        case kSectionIntro:
            return NSLocalizedString(@"Welcome to PDX Bus!", @"Section header");
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case kSectionThanks:
            return 1;
            
        case kSectionIntro:
            return kSectionIntroRows;
            
        case kSectionWeb:
            return _links.count;
            
        case kSectionLegal:
            return _legal.count;
            
        case kSectionVersions:
            return _versions.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellFromDict:(NSDictionary<NSString *, NSString *> *)item {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellLink];
    LinkCell *linkCell = (LinkCell *)cell;
    
    NSString *link = item[kLinkMobile];
    NSString *fullLink = item[kLinkFull];
    
    if (link == nil || (LARGE_SCREEN && fullLink!=nil))
    {
        link = fullLink;
    }
    

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    NSString *text = link ? [NSString stringWithFormat:@"%@\n%@",item[kCellText], link]
                          : item[kCellText];
    
    linkCell.textView.attributedText = [text formatAttributedStringWithFont:self.basicFont];
    linkCell.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"Link to %@", @"Accessibility label"), cell.textLabel.text.phonetic];
    return linkCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kSectionThanks:
        case kSectionIntro: {
            if (indexPath.row == kSectionIntroRowIntro) {
                LinkCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellLink];
                cell.textView.attributedText = (indexPath.section == kSectionThanks) ? _thanksText : _introText;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                [self updateAccessibility:cell];
                return cell;
            } else {
                UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:MakeCellId(kSectionHelpRowNew) font:self.paragraphFont];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.font = self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                cell.textLabel.text = NSLocalizedString(@"What's new?", @"Link to what's new");
                cell.imageView.image = [Icons getIcon:kIconAppIconAction];
                return cell;
            }
            
            break;
        }
            
        case kSectionWeb: {
            return [self tableView:tableView cellFromDict:_links[indexPath.row]];
            
            break;
        }
            
        case kSectionLegal: {
            return [self tableView:tableView cellFromDict:_legal[indexPath.row]];
            
            break;
        }
            
        case kSectionVersions: {
            UITableViewCell *cell = [self tableView:tableView multiLineCellWithReuseIdentifier:MakeCellId(kSectionVersions) font:self.basicFont];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.font = self.basicFont; //  [UIFont fontWithName:@"Ariel" size:14];
            cell.textLabel.adjustsFontSizeToFitWidth = NO;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.attributedText = FormatTextBasic((_versions[indexPath.row]));
            // cell.imageView.image = [self getIcon:kIconAppIconAction];
            return cell;
            
            break;
        }
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (void)gotoDict:(NSDictionary<NSString *, NSString *> *)dict {
    [WebViewController displayPage:dict[kLinkMobile]
                              full:dict[kLinkFull]
                         navigator:self.navigationController
                    itemToDeselect:self
                          whenDone:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case kSectionIntro:
            
            if (indexPath.row == kSectionIntroRowIntro) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [self.navigationController pushViewController:[WhatsNewView viewController] animated:YES];
            }
            
            break;
    }
}

@end
