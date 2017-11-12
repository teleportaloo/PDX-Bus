//
//  TripItemCell.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/9/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//

#import "TripItemCell.h"
#import "ViewControllerBase.h"
#import "DebugLogging.h"
#import "StringHelper.h"

@implementation TripItemCell

#define kTextViewFontSize        15.0
#define kTextViewLargeFontSize   20.0
#define kBoldFontName            @"Helvetica-Bold" //@"Arial-BoldMT"
#define kFontName                @"Helvetica"

@dynamic large;
@dynamic formattedBodyText;


- (void)populateBody:(NSString *)body
                mode:(NSString *)mode
                time:(NSString *)time
           leftColor:(UIColor *)col
               route:(NSString *)route
{
    if (col == nil)
    {
        col = [UIColor grayColor];
    }
    
    if (time == nil)
    {
        self.modeLabel.text =  mode; //  @"1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n";
    }
    else
    {
        self.modeLabel.text = [NSString stringWithFormat:@"%@\n%@", mode, time];
    }
    self.modeLabel.textColor = col;
    
    self.formattedBodyText =  body; // @"the quick brown fox jumped over the lazy dog's tail and yelped as he did it.  Yes he did.";
    
    DEBUG_LOG(@"Width: %f\n", self.bodyLabel.bounds.size.width);
    DEBUG_LOG(@"Text: %@\n", body);
    
    self.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", self.modeLabel.text, body];
    
    
    
    [self.routeColorView setRouteColor:route];
    
    //    DEBUG_LOG(@"Route: %@  body %@ r %f g %f b %f\n", route, body, colorStripe.red, colorStripe.green, colorStripe.blue);
    [self update];
    
}

- (NSString *)formattedBodyText
{
    return  _formattedBodyText;
}

- (void)setFormattedBodyText:(NSString *)formattedBodyText
{
    [_formattedBodyText release];
    _formattedBodyText = [formattedBodyText retain];
    self.bodyLabel.attributedText = [self.formattedBodyText formatAttributedStringWithFont:self.bodyFont];
}


- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (bool)large
{
    DEBUG_LOGF([UIApplication sharedApplication].delegate.window.bounds.size.width);
    return LARGE_SCREEN;
}


- (UIFont*)bodyFont
{
    UIFont *font = nil;
    
    if (SMALL_SCREEN)
    {
        font = [UIFont fontWithName:kFontName size:kTextViewFontSize];
    }
    else {
        font = [UIFont fontWithName:kFontName size:kTextViewLargeFontSize];
    }
    
    
    return font;
}

- (UIFont*)boldBodyFont
{
    UIFont *font = nil;
    
    if (SMALL_SCREEN)
    {
        font = [UIFont fontWithName:kBoldFontName size:kTextViewFontSize];
    }
    else
    {
        font = [UIFont fontWithName:kBoldFontName size:kTextViewLargeFontSize];
    }
    
    return font;
}

- (void)update
{
    self.modeLabel.font = self.boldBodyFont;
    self.bodyLabel.attributedText = [self.formattedBodyText formatAttributedStringWithFont:self.bodyFont];
    self.modeLabelWidth.constant = self.large ? 100.0 : 75.0;
}

- (void)layoutSubviews
{
    [self update];
    [super layoutSubviews];
}

- (void)dealloc {
    [_routeColorView release];
    [_modeLabel release];
    [_bodyLabel release];
    [_modeLabelWidth release];
    self.formattedBodyText = nil;
    [super dealloc];
}

+ (UINib*)nib
{
    return [UINib nibWithNibName:@"TripItemCell" bundle:nil];
}
@end
