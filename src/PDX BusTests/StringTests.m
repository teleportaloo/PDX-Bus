//
//  StringTests.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 4/26/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../PDXBusCore/src/NSString+Helper.h"

@interface StringTests : XCTestCase

@end

@implementation StringTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_StringEscape_blank
{
    //Build
    NSString *sut = @"";
    
    //Operate
    NSString *result = sut.safeEscapeForMarkUp;
    
    //Assert
    XCTAssertEqualObjects(result, @"");
}


- (void)test_StringEscape_no_escape
{
    //Build
    NSString *sut = @"nothing to see here";
    
    //Operate
    NSString *result = sut.safeEscapeForMarkUp;
    
    //Assert
    XCTAssertEqualObjects(result, @"nothing to see here");
}


- (void)test_StringEscape_start
{
    //Build
    NSString *sut = @"#";
    
    //Operate
    NSString *result = sut.safeEscapeForMarkUp;
    
    //Assert
    XCTAssertEqualObjects(result, @"#h");
}

- (void)test_StringEscape_end
{
    //Build
    NSString *sut = @"1#";
    
    //Operate
    NSString *result = sut.safeEscapeForMarkUp;
    
    //Assert
    XCTAssertEqualObjects(result, @"1#h");
}


- (void)test_StringEscape_middle
{
    //Build
    NSString *sut = @"hello # there";
    
    //Operate
    NSString *result = sut.safeEscapeForMarkUp;
    
    //Assert
    XCTAssertEqualObjects(result, @"hello #h there");
}

- (void)test_StringEscape_lots
{
    //Build
    NSString *sut = @"# hello #### there #";
    
    //Operate
    NSString *result = sut.safeEscapeForMarkUp;
    
    //Assert
    XCTAssertEqualObjects(result, @"#h hello #h#h#h#h there #h");
}

- (void)test_markUpRemoveAtEnd
{
    //Build
    NSString *sut = @"#Ghello there#b";
    
    //Operate
    NSString *result = sut.removeMarkUp;
    
    //Assert
    XCTAssertEqualObjects(result, @"hello there");
    
}

- (void)test_markUpRemoveComplex
{
    //Build
    NSString *sut = @"#0#bhello #ithere ##3 #Lwww.apple.com Apple#T";
    
    //Operate
    NSString *result = sut.removeMarkUp;
    
    //Assert
    XCTAssertEqualObjects(result, @"hello there #3 Apple");
}

- (void)test_markUpRemoveIncomplete
{
    //Build
    NSString *sut = @"#0#bhello #ithere#";
    
    //Operate
    NSString *result = sut.removeMarkUp;
    
    //Assert
    XCTAssertEqualObjects(result, @"hello there");
    
}

- (void)test_markUpRemoveIncompleteLink
{
    //Build
    NSString *sut = @"#Lwww.apple.com Apple";
    
    //Operate
    NSString *result = sut.removeMarkUp;
    
    //Assert
    XCTAssertEqualObjects(result, @"Apple");
}

- (void)test_markUpRemoveLinkWithNoSpace
{
    //Build
    NSString *sut = @"#Lwww.apple.com";
    
    //Operate
    NSString *result = sut.removeMarkUp;
    
    //Assert
    XCTAssertEqualObjects(result, @"");
}

- (void)test_font_attributes_first
{
    //Build
    NSString *sut = @" #bBold";
    
    //Operate
    NSAttributedString *str = [sut attributedStringFromMarkUpWithFont:[UIFont systemFontOfSize:16]];
    
    UIFont *font = [str attribute:NSFontAttributeName atIndex:1 effectiveRange:nil];
    UIFontDescriptor *fontDescriptor = font.fontDescriptor;
    
    //Assert
    XCTAssertEqual(fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold,  UIFontDescriptorTraitBold);
    XCTAssertEqual(fontDescriptor.pointSize, 16);
    XCTAssertEqualObjects(fontDescriptor.postscriptName, @".SFUI-Semibold");
}


- (void)test_font_attributes_second
{
    //Build
    NSString *sut = @" #bbold #b#iitalic";
    
    //Operate
    NSAttributedString *str = [sut attributedStringFromMarkUpWithFont:[UIFont systemFontOfSize:16]];
    
    UIFont *font = [str attribute:NSFontAttributeName atIndex:6 effectiveRange:nil];
    UIFontDescriptor *fontDescriptor = font.fontDescriptor;
    
    //Assert
    XCTAssertEqual(fontDescriptor.symbolicTraits & UIFontDescriptorTraitItalic,  UIFontDescriptorTraitItalic);
    XCTAssertEqual(fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold,    0);
    XCTAssertEqual(fontDescriptor.pointSize, 16);
    XCTAssertEqualObjects(fontDescriptor.postscriptName, @".SFUI-RegularItalic");

}

- (void)test_attribute_colour
{
    //Build
    NSString *sut = @" #OGreen";
    
    //Operate
    NSAttributedString *str = [sut attributedStringFromMarkUpWithFont:[UIFont systemFontOfSize:16]];
    
    UIColor *color = [str attribute:NSForegroundColorAttributeName atIndex:1 effectiveRange:nil];
    
    //Assert
    XCTAssertEqualObjects(color, [UIColor orangeColor]);
}

- (void)test_attribute_rainbow
{
    //Build
    NSString *sut = @" #GG#BB#Nb";
    
    //Operate
    NSAttributedString *str = [sut attributedStringFromMarkUpWithFont:[UIFont systemFontOfSize:16]];
    
    //Assert
    XCTAssertEqualObjects([str attribute:NSForegroundColorAttributeName atIndex:1 effectiveRange:nil], [UIColor greenColor]);
    XCTAssertEqualObjects([str attribute:NSForegroundColorAttributeName atIndex:2 effectiveRange:nil], [UIColor blueColor]);
    XCTAssertEqualObjects([str attribute:NSForegroundColorAttributeName atIndex:3 effectiveRange:nil], [UIColor brownColor]);
}

- (void)test_attribute_link
{
    //Build
    NSString *sut = @"#Lhttp://apple.com Text#T";
    
    //Operate
    NSAttributedString *str = [sut attributedStringFromMarkUpWithFont:[UIFont systemFontOfSize:16]];
    
    //Assert
    XCTAssertEqualObjects(((NSURL *)[str attribute:NSLinkAttributeName atIndex:1 effectiveRange:nil]).absoluteString, @"http://apple.com");
}




@end
