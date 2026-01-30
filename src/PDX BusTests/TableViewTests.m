//
//  TableViewTests.m
//  PDX BusTests
//
//  Created by Andy Wallace on 9/12/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//

#import "../Classes/TableViewControllerWithToolbar.h"
#import <XCTest/XCTest.h>

#define DEBUG_LEVEL_FOR_FILE LogTests

@interface TableViewTests : XCTestCase

@end

@implementation TableViewTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the
    // class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the
    // class.
}

- (void)testCells {
    NSMutableDictionary<NSString *, NSMutableSet *> *debugStore =
        [TableViewControllerWithToolbar debugCellTypeStore];

    size_t size = 0;
    NSInteger nCells = 0;

    NSCountedSet<NSString *> *freq = [NSCountedSet new];

    DEBUG_LOG_long(debugStore.count);

    NSInteger switchStatements = 0;

    for (NSString *key in debugStore) {

        Class cls = NSClassFromString(key);

        TableViewControllerWithToolbar *obj = (TableViewControllerWithToolbar *)[[cls alloc] init];

        DEBUG_LOG(@"Checking cells in %@ - %ld", key, (long)obj.getvTableSize);

        NSMutableDictionary *cells = TableViewControllerWithToolbar.debugCellTypeStore[key];

        size_t vTableSize = [obj getvTableSize];

        XCTAssert(vTableSize < 40,
                  @"vTableSize for %@ seems too big - %ld. Check values are not negative.",
                  key,
                  (long)vTableSize);

        size += vTableSize * sizeof(RowVTablePtrConst);

        int sparse = 0;
        for (int i = 0; i < vTableSize; i++) {
            RowVTablePtrConst item = *(obj.getvTable + i);

            if (item == nil) {
                DEBUG_LOG(@"%@ has nil entry vTable at %d", key, i);
                sparse++;
            }
        }

        DEBUG_LOG(@"%@ has %d nil entries", key, sparse);
        XCTAssert(sparse < 10, @"Table for %@ is suprisingly sparse %d", key, sparse);

        NSInteger localSwitches = 0;

        for (NSNumber *number in cells) {
            NSInteger cellSwitches = 0;

            XCTAssert(number.integerValue < vTableSize,
                      @"%@ cell enum %ld to big (%ld)",
                      key,
                      (long)number.integerValue,
                      (long)obj.getvTableSize);

            if (number.integerValue < vTableSize) {

                NSValue *sels = cells[number];
                RowVTable vTable;
                [sels getValue:&vTable];

                NSString *name = vTable.reuseId;

                RowVTablePtrConst item = *(obj.getvTable + number.integerValue);

                XCTAssert(item != nil,
                          @"%@ is missing row map entry for %@ (%d)",
                          key,
                          name,
                          number.intValue);

// Check that the selectors exist if used, and if not used that it was not defined and ignored
#define CHECK_SEL(X)                                                                               \
    if (item->X) {                                                                                 \
        cellSwitches++;                                                                            \
        [freq addObject:NSStringFromSelector(item->X)];                                            \
        XCTAssert([obj respondsToSelector:item->X],                                                \
                  @"%@ does not respond to %s %@",                                                 \
                  key,                                                                             \
                  #X,                                                                              \
                  NSStringFromSelector(item->X));                                                  \
    } else {                                                                                       \
        XCTAssert(![obj respondsToSelector:vTable.X], @"%@ does respond to %@", key, name);        \
    }

                if (item) {
                    size += sizeof(RowVTable);
                    nCells++;

                    CHECK_SEL(selRegister);
                    CHECK_SEL(selConfigure);
                    CHECK_SEL(selUpdate);
                    CHECK_SEL(selSelect);
                    CHECK_SEL(selHeight);
                    CHECK_SEL(selWillDisplayCell);
                    CHECK_SEL(selAccessoryTapped);
                    CHECK_SEL(selCanEditRow);
                    CHECK_SEL(selEditingStyle);
                    CHECK_SEL(selCanMove);
                }
            }

            localSwitches = MAX(localSwitches, cellSwitches);
        }
        switchStatements += localSwitches;
    }

    NSArray *all = [freq allObjects];

    // Sort by frequency DESC, then alphabetical ASC
    NSArray *sorted = [all sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
      NSUInteger countA = [freq countForObject:a];
      NSUInteger countB = [freq countForObject:b];

      if (countA > countB)
          return NSOrderedAscending; // higher count first
      if (countA < countB)
          return NSOrderedDescending; // lower count last
      return [a compare:b];           // tie-break alphabetically
    }];

    for (NSString *word in sorted) {
        DEBUG_LOG(@"%@ %lu",
                  [word stringByPaddingToLength:90 withString:@" " startingAtIndex:0],
                  (unsigned long)[freq countForObject:word]);
    }

    DEBUG_LOG_long(switchStatements);
    DEBUG_LOG_long(size);
    DEBUG_LOG_long(nCells);
}

@end
