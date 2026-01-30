//
//  AboutViewController.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AboutViewController.h"
#import "DebugLogging.h"
#import "Icons.h"
#import "LinkInfo.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "PDXBus-Swift.h"
#import "SupportViewController.h"
#import "TextViewLinkCell.h"
#import "TriMetXML.h"
#import "UIApplication+Compat.h"
#import "UITableViewCell+Icons.h"
#import "WebViewController.h"
#import "WhatsNewViewController.h"

#import <sys/sysctl.h>
#import <sys/types.h>

enum SECTION_ROWS {
    kSectionIntro,
    kSectionIntroRowIntro,
    kSectionIntroRowNew,
    kSectionIntroRowTip,
    kSectionWeb,
    kSectionLegal,
    kSectionOther,
    kSectionVersions,
    kSectionThanks
};

@interface AboutViewController () {
    NSArray<NSDictionary<NSString *, NSString *> *> *_links;
    NSArray<NSDictionary<NSString *, NSString *> *> *_legal;
    NSArray<NSDictionary<NSString *, NSString *> *> *_other;
    NSString *_thanksText;
    NSString *_introText;
    NSArray<NSString *> *_versions;
}

@end

@implementation AboutViewController

#pragma mark Helper functions

- (UITableViewStyle)style {
    return UITableViewStyleGrouped;
}

#pragma mark Table view methods

- (NSString *)platform {
    size_t size;

    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char *)malloc(size);

    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];

    free(machine);
    return platform;
}

- (void)reloadData {
    [super reloadData];
    [self makeText];
}

- (void)makeText {
    _thanksText = [NSString
        stringWithFormat:NSLocalizedString(
                             @"Route and departure data provided by permission of "
                             @"#B#bTriMet#b#D.\n\n"
                              "This app was developed as a volunteer effort to provide a "
                              "service for #B#bTriMet#b#D riders. The developer has no "
                              "affiliation with #B#bTriMet#b#D, or Apple.\n\n"
                              "Lots of #ithanks#i...\n\n"
                              "...to portlandtransport.com for help and advice;\n\n"
                              "...to #iScott#i, #iTim#i and #iMike#i for beta testing and "
                              "suggestions;\n\n"
                              "...to #iScott#i (again) for lending me his brand new "
                              "iPad;\n\n"
                              "...to #iScott#i (again 😃) for feedback on the watch app;\n\n"
                              "...to #iRob Alan#i for the stylish icon; and\n\n"
                              "...to CivicApps.org for Awarding PDX Bus the #i#bMost "
                              "Appealing#b#i and #b#iBest in Show#b#i awards in July "
                              "2010.\n\n"
                              "Special thanks to #R#b#iKen#i#b#D for putting up with all "
                              "this.\n\n"
                              "\nCopyright (c) 2008-2025\nAndrew Wallace\n(See legal "
                              "section above for other copyright owners and attrbutions).",
                             @"Dedication text")];

    _versions = @[
        [NSString
            stringWithFormat:@"#DApp: #b#B%@.%@ (%s)",
                             [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
                             [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"],
                             __DATE__],
        [NSString stringWithFormat:@"#DType: #b#B%@", UIDevice.currentDevice.model],
        [NSString stringWithFormat:@"#DiOS: #b#B%@", UIDevice.currentDevice.systemVersion],
        [NSString stringWithFormat:@"#DDevice: #b#B%@", self.platform],
        [NSString stringWithFormat:@"#DBuild: #b#B%lu bits %@", sizeof(NSInteger) * 8, DEBUG_MODE]
    ];

    _introText =
        NSLocalizedString(@"One developer writes #bPDX Bus#b as a #ivolunteer effort#i, with "
                          @"a little help from friends and the local community. He has no "
                          @"affiliation with #b#BTriMet#b#D, but he used to ride buses "
                          @"and MAX on most days.\n\n"
                           "This is free because I do it for fun. #i#b#GReally#i#b#D.",
                          @"information");
}

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"About", @"About screen title");

        [self makeText];

        _links =
            [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about-links"
                                                                             ofType:@"plist"]];
        _legal =
            [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about-legal"
                                                                             ofType:@"plist"]];

        _other =
            [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about-other"
                                                                             ofType:@"plist"]];

        _hideButton = NO;
    }

    return self;
}

- (void)viewDidLoad {

    [self clearSectionMaps];

    [self addSectionType:kSectionIntro];
    [self addRowType:kSectionIntroRowIntro];
    [self addRowType:kSectionIntroRowNew];
    [self addRowType:kSectionIntroRowTip];

    [self addSectionType:kSectionWeb];
    [self addRowType:kSectionWeb count:_links.count];

    [self addSectionType:kSectionLegal];
    [self addRowType:kSectionLegal count:_legal.count];
    [self addSectionType:kSectionOther];
    [self addRowType:kSectionOther count:_other.count];

    [self addSectionType:kSectionVersions];
    [self addRowType:kSectionVersions count:_versions.count];

    [self addSectionType:kSectionThanks];
    [self addRowType:kSectionThanks];

    self.tableView.rowHeight = UITableViewAutomaticDimension;

    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (!_hideButton) {
        UIBarButtonItem *info =
            [UIBarButtonItem textButton:NSLocalizedString(@"Help", @"Help button")
                                 target:self
                                 action:@selector(infoAction:)];
        self.navigationItem.rightBarButtonItem = info;
    }
}

- (void)infoAction:(id)sender {
    SupportViewController *infoView = [SupportViewController viewController];

    // Push the detail view controller

    infoView.hideButton = YES;

    [self.navigationController pushViewController:infoView animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ([self sectionType:section]) {
    case kSectionThanks:
        return NSLocalizedString(@"Thanks!", @"Thanks section header");

    case kSectionWeb:
        return NSLocalizedString(@"Links", @"Link section header");

    case kSectionLegal:
        return NSLocalizedString(@"Attributions and Legal", @"Section header");

    case kSectionOther:
        return NSLocalizedString(@"My other apps", @"Section header");

    case kSectionVersions:
        return NSLocalizedString(@"Versions", @"Section header");

    case kSectionIntro:
        return NSLocalizedString(@"Welcome to PDX Bus!", @"Section header");
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
                  cellFromDict:(NSDictionary<NSString *, NSString *> *)item {

    LinkInfo *info = item.linkInfo;
    NSString *link = info.valLinkMobile;
    NSString *fullLink = info.valLinkFull;

    if (link == nil || (LARGE_SCREEN && fullLink != nil)) {
        link = fullLink;
    }

    return [LabelLinkCellWithIcon dequeueFrom:tableView
                                   imageNamed:info.valLinkIcon
                                        title:info.valLinkTitle
                                         link:link];
}

- (TextViewLinkCell *)tableView:(UITableView *)tableView paragraphCell:(NSAttributedString *)text {
    TextViewLinkCell *cell =
        [tableView dequeueReusableCellWithIdentifier:TextViewLinkCell.identifier];
    [cell resetForReuse];
    cell.textView.attributedText = text;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [self updateAccessibility:cell];
    return cell;
}

- (void)gotoDict:(NSDictionary<NSString *, NSString *> *)dict {
    LinkInfo *info = dict.linkInfo;
    [WebViewController displayPage:info.valLinkMobile
                              full:info.valLinkFull
                         navigator:self.navigationController
                    itemToDeselect:self
                          whenDone:nil];
}

//--------------------------------------------------------------------------------------------------
//                               Virtual Cell Table
//--------------------------------------------------------------------------------------------------
#define VTABLE_CLASS AboutViewController
//--------------------------------------------------------------------------------------------------
#pragma mark kSectionThanks

TEXT_CELL(kSectionThanks, _thanksText);

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionIntroRowNew

BASIC_CELL_SELECT(kSectionIntroRowNew,
                  NSLocalizedString(@"What's new?", @"Link to what's new"),
                  kIconAppIconAction,
                  UITableViewCellAccessoryDisclosureIndicator) {
    CELL_PUSH([WhatsNewViewController viewController]);
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionIntroRowIntro

TEXT_CELL_SELECT(kSectionIntroRowIntro,
                 _introText,
                 UITableViewCellAccessoryNone,
                 UITableViewCellSelectionStyleBlue) {
    CELL_POP();
}

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionIntroRowTip

CELL_TIP_JAR(kSectionIntroRowTip, basic);

//--------------------------------------------------------------------------------------------------
#define DICTIONARY_CELL(TOK, DICT)                                                                 \
    CELL_CONFIG_METHOD(TOK) {                                                                      \
        return [self tableView:tableView cellFromDict:DICT[indexPath.row]];                        \
    }                                                                                              \
    CELL_SELECT_METHOD(TOK) { [self gotoDict:DICT[indexPath.row]]; }                               \
    STATIC_VTABLE_VCS_H(TOK, auto);

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionWeb

DICTIONARY_CELL(kSectionWeb, _links);

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionLegal

DICTIONARY_CELL(kSectionLegal, _legal);

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionOther

DICTIONARY_CELL(kSectionOther, _other);

//--------------------------------------------------------------------------------------------------
#pragma mark kSectionVersions

MULTI_CELL(kSectionVersions, auto, _versions[indexPath.row], nil);

//--------------------------------------------------------------------------------------------------

CELL_VTABLE_MAP{
    CELL_MAP(kSectionThanks),
    CELL_MAP(kSectionIntroRowNew),
    CELL_MAP(kSectionIntroRowIntro),
    CELL_MAP(kSectionIntroRowTip),
    CELL_MAP(kSectionWeb),
    CELL_MAP(kSectionLegal),
    CELL_MAP(kSectionOther),
    CELL_MAP(kSectionVersions),
};

@end
