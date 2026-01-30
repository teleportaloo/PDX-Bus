//
//  TableViewWithToolbar.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BackgroundTaskContainer.h"
#import "BoxedIcon.h"
#import "DeselectItemDelegate.h"
#import "MapKit/MapKit.h"
#import "ProgressModalView.h"
#import "TaskController.h"
#import "UIBarButtonItem+Auto.h"
#import "ViewControllerBase.h"
#import <IntentsUI/IntentsUI.h>
#import <UIKit/UIKit.h>

#define kDisclaimerCellHeight UITableViewAutomaticDimension

#define kDisclaimerCellId @"disclaimer"
#define kExceptionCellId @"Exception"

#define kNoNetwork NSLocalizedString(@"%@: touch here for info", @"Stop ID and message")
#define kNoNetworkErrorID                                                                          \
    NSLocalizedString(@"(ID %@) %@: touch here for info", @"Stop ID and message")
#define kNoNetworkID                                                                               \
    NSLocalizedString(@"(ID %@) No Network: touch here for info", @"Stop ID and error message")
#define kNetworkMsg                                                                                \
    NSLocalizedString(@"Network error: touch here for info", @"Network error message")

#define ACCESSORY_BUTTON_SIZE 35

#define MakeCellId(X) @ #X
#define MakeCellIdW(X, W) [NSString stringWithFormat:@"%@+%f", @ #X, (float)W]

#define MakeMapRectWithPointAtCenter(X, Y, W, H) MKMapRectMake((X) - (W) / 2, (Y) - (H) / 2, W, H)

// #define kBasicTextViewFontSize    14.0

#define kNoRowSectionTypeFound (-1)

extern NSString *kSimpleId;
extern NSString *kActionCellId;

//--------------------------------------------------------------------------------------------------
//                      Virtual Tables for Cells
//--------------------------------------------------------------------------------------------------
// A TableView can implement the rows as a lookup-table. Each entry is this, a structure of
// selectors that call into the main controller for each of the actions.

typedef struct {
    NSString *reuseId;      // Optional: used for the update selector
    SEL selRegister;        // Optional: Register cell if needed (e.g. NIB)
    SEL selConfigure;       // Dequeue and configure the cell (must have this or selUpdate)
    SEL selUpdate;          // Update the cell, it was dequeued with reuseId
    SEL selSelect;          // Optional
    SEL selHeight;          // Optional
    SEL selWillDisplayCell; // Optional
    SEL selAccessoryTapped; // Optional
    SEL selCanEditRow;      // Optional
    SEL selEditingStyle;    // Optional
    SEL selCanMove;         // Optional
} RowVTable;

typedef const RowVTable *const RowVTablePtrConst;
typedef RowVTablePtrConst *RowVTableTable;

#define CELL_VTABLE_MAP                                                                            \
    -(RowVTableTable)getvTable {                                                                   \
        return &(rowVTable[0]);                                                                    \
    }                                                                                              \
    -(size_t)getvTableSize {                                                                       \
        return sizeof(rowVTable) / sizeof(rowVTable[0]);                                           \
    }                                                                                              \
    static const RowVTable *const rowVTable[] =

// clang-format off
// uncrustify-off

//--------------------------------------------------------------------------------------------------
#define CELL_REG_METHOD(TOK)                                                                       \
    -(void)vt_##TOK##_tableView:(UITableView *)tableView                                           \
                   cellRegister:(RowVTablePtrConst)vTable                                          \
                         offset:(NSInteger)offset

#define CELL_REG_SEL(TOK) @selector(vt_##TOK##_tableView:cellRegister:offset:)
#define SET_CELL_REG_SEL(TOK) .selRegister = CELL_REG_SEL(TOK)

typedef UITableViewCell *(*CELL_REG_IMP)(id, SEL, UITableView *, RowVTablePtrConst,
                                          NSInteger offset);
//--------------------------------------------------------------------------------------------------
#define CELL_CONFIG_METHOD(TOK)                                                                    \
    -(UITableViewCell *)vt_##TOK##_tableView:(UITableView *)tableView                              \
                                    cellAtIP:(NSIndexPath *)indexPath                              \
                                       extra:(id _Nullable )extra                                  \
                                      vTable:(RowVTablePtrConst)vTable                             \
                                      offset:(NSInteger)offset

#define CELL_CONFIG_SEL(TOK) @selector(vt_##TOK##_tableView:cellAtIP:extra:vTable:offset:)
#define SET_CELL_CONFIG_SEL(TOK) .selConfigure = CELL_CONFIG_SEL(TOK)

typedef UITableViewCell *(*CELL_CONFIG_IMP)(id, SEL, UITableView *, NSIndexPath *, id extra,
                                            RowVTablePtrConst vTable, NSInteger offset);
//--------------------------------------------------------------------------------------------------
#define CELL_UPDATE_METHOD(TOK)                                                                    \
    -(void)vt_##TOK##_tableView:(UITableView *)tableView                                           \
                     updateCell:(UITableViewCell *)cell                                            \
                           atIP:(NSIndexPath *)indexPath                                           \
                          extra:(id _Nullable)extra                                                \
                         vTable:(RowVTablePtrConst)vTable                                          \
                         offset:(NSInteger)offset

#define CELL_UPDATE_SEL(TOK) @selector(vt_##TOK##_tableView:updateCell:atIP:extra:vTable:offset:)
#define SET_CELL_UPDATE_SEL(TOK) .selUpdate = CELL_UPDATE_SEL(TOK)

typedef void (*CELL_UPDATE_IMP)(id, SEL, UITableView *, UITableViewCell *, NSIndexPath *,
                                id extra, RowVTablePtrConst vTable, NSInteger offset);
//--------------------------------------------------------------------------------------------------
#define CELL_SELECT_METHOD(TOK)                                                                    \
    -(void)vt_##TOK##_tableView:(UITableView *)tableView                                           \
               didSelectRowAtIP:(NSIndexPath *)indexPath                                           \
                          extra:(id _Nullable)extra                                                \
                         vTable:(RowVTablePtrConst)vTable                                          \
                         offset:(NSInteger)offset

#define CELL_SELECT_SEL(TOK) @selector(vt_##TOK##_tableView:didSelectRowAtIP:extra:vTable:offset:)
#define SET_CELL_SELECT_SEL(TOK) .selSelect = CELL_SELECT_SEL(TOK)

typedef void *(*CELL_SELECT_IMP)(id, SEL, UITableView *, NSIndexPath *,
                                 id extra, RowVTablePtrConst vTable, NSInteger offset);
//--------------------------------------------------------------------------------------------------
#define CELL_HEIGHT_METHOD(TOK)                                                                    \
    -(CGFloat)vt_##TOK##_tableView:(UITableView *)tableView                                        \
                  heightForRowAtIP:(NSIndexPath *)indexPath                                        \
                             extra:(id _Nullable)extra                                             \
                            vTable:(RowVTablePtrConst)vTable                                       \
                            offset:(NSInteger)offset

#define CELL_HEIGHT_SEL(TOK) @selector(vt_##TOK##_tableView:heightForRowAtIP:extra:vTable:offset:)
#define SET_CELL_HEIGHT_SEL(TOK) .selHeight = CELL_HEIGHT_SEL(TOK)

typedef CGFloat (*CELL_HEIGHT_IMP)(id, SEL, UITableView *, NSIndexPath *,
                                   id extra, RowVTablePtrConst vTable, NSInteger offset);
//--------------------------------------------------------------------------------------------------
#define CELL_WILL_DISPLAY_METHOD(TOK)                                                              \
    -(void)vt_##TOK##_tableView:(UITableView *)tableView                                           \
                willDisplayCell:(UITableViewCell *)cell                                            \
                     forRowAtIP:(NSIndexPath *)indexPath                                           \
                          extra:(id _Nullable)extra                                                \
                         vTable:(RowVTablePtrConst)vTable                                          \
                         offset:(NSInteger)offset

#define CELL_WILL_DISPLAY_SEL(TOK)                                                                 \
    @selector(vt_##TOK##_tableView:willDisplayCell:forRowAtIP:extra:vTable:offset:)
#define SET_CELL_WILL_DISPLAY_SEL(TOK) .selWillDisplayCell = CELL_WILL_DISPLAY_SEL(TOK)

typedef UITableViewCell *(*CELL_WILL_DISPLAY_IMP)(
                         id, SEL, UITableView *, UITableViewCell *, NSIndexPath *,
                         id extra, RowVTablePtrConst vTable, NSInteger offset);
//--------------------------------------------------------------------------------------------------
#define CELL_ACCESSORY_METHOD(TOK)                                                                 \
         -(void)vt_##TOK##_tableView:(UITableView *)tableView                                      \
   accessoryButtonTappedForRowWithIP:(NSIndexPath *)indexPath                                      \
                               extra:(id _Nullable)extra                                           \
                              vTable:(RowVTablePtrConst)vTable                                     \
                              offset:(NSInteger)offset

#define CELL_ACCESSORY_SEL(TOK)                                                                    \
    @selector(vt_##TOK##_tableView:accessoryButtonTappedForRowWithIP:extra:vTable:offset:)
#define SET_CELL_ACCESSORY_SEL(TOK) .selAccessoryTapped = CELL_ACCESSORY_SEL(TOK)

typedef void (*CELL_ACCESSORY_IMP)(id, SEL, UITableView *, NSIndexPath *,
                                   id extra, RowVTablePtrConst vTable, NSInteger offset);
//--------------------------------------------------------------------------------------------------
#define CELL_CAN_EDIT_METHOD(TOK)                                                                  \
         -(bool)vt_##TOK##_tableView:(UITableView *)tableView                                      \
                      canEditRowAtIP:(NSIndexPath *)indexPath                                      \
                               extra:(id _Nullable)extra                                           \
                              vTable:(RowVTablePtrConst)vTable                                     \
                              offset:(NSInteger)offset

#define CELL_CAN_EDIT_SEL(TOK)                                                                     \
    @selector(vt_##TOK##_tableView:canEditRowAtIP:extra:vTable:offset:)
#define SET_CELL_CAN_EDIT_SEL(TOK) .selCanEditRow = CELL_CAN_EDIT_SEL(TOK)

typedef bool (*CELL_CAN_EDIT_IMP)(id, SEL, UITableView *, NSIndexPath *,
                                  id extra, RowVTablePtrConst vTable, NSInteger offset);
//--------------------------------------------------------------------------------------------------
#define CELL_EDITING_STYLE_METHOD(TOK)                                                             \
         -(UITableViewCellEditingStyle)vt_##TOK##_tableView:(UITableView *)tableView               \
                                     editingStyleForRowAtIP:(NSIndexPath *)indexPath               \
                                                      extra:(id _Nullable)extra                    \
                                                     vTable:(RowVTablePtrConst)vTable              \
                                                     offset:(NSInteger)offset

#define CELL_EDITING_STYLE_SEL(TOK)                                                                \
    @selector(vt_##TOK##_tableView:editingStyleForRowAtIP:extra:vTable:offset:)
#define SET_CELL_EDITING_STYLE_SEL(TOK) .selEditingStyle = CELL_EDITING_STYLE_SEL(TOK)

typedef UITableViewCellEditingStyle (*CELL_EDITING_STYLE_IMP)(
      id, SEL, UITableView *, NSIndexPath *, id extra, RowVTablePtrConst vTable, NSInteger offset);
//--------------------------------------------------------------------------------------------------
#define CELL_CAN_MOVE_METHOD(TOK)                                                                  \
         -(BOOL)vt_##TOK##_tableView:(UITableView *)tableView                                      \
               canMoveRowAtIndexPath:(NSIndexPath *)indexPath                                      \
                               extra:(id _Nullable)extra                                           \
                              vTable:(RowVTablePtrConst)vTable                                     \
                              offset:(NSInteger)offset
    
#define CELL_CAN_MOVE_SEL(TOK)                                                                     \
    @selector(vt_##TOK##_tableView:canMoveRowAtIndexPath:extra:vTable:offset:)
#define SET_CELL_CAN_MOVE_SEL(TOK) .selCanMove = CELL_CAN_MOVE_SEL(TOK)

typedef BOOL (*CELL_CAN_MOVE_IMP)(id, SEL, UITableView *, NSIndexPath *,
                                  id extra, RowVTablePtrConst vTable, NSInteger offset);
//--------------------------------------------------------------------------------------------------
// clang-format on
// uncrustify-on

// User must define VTABLE_CLASS

#define CELL_VTABLE(TOK) vTable_##TOK

#ifdef DEBUGLOGGING

// When debugging we create a template table of what the methods would be called if we were using
// the standard method names. Then when testing we can see if those methods were defined but not
// used, which will raise an error as they were probably missed from the table.
#define CELL_STATIC_VTABLE(TOK)                                                                    \
    CELL_PUSH_NO_SEL_WARNING;                                                                      \
    __attribute__((constructor)) static void debug_##TOK##_init(void) {                            \
        RowVTable standardvTable = {                                                               \
            .reuseId = @ #TOK,                                                                     \
            SET_CELL_REG_SEL(TOK),                                                                 \
            SET_CELL_CONFIG_SEL(TOK),                                                              \
            SET_CELL_UPDATE_SEL(TOK),                                                              \
            SET_CELL_SELECT_SEL(TOK),                                                              \
            SET_CELL_HEIGHT_SEL(TOK),                                                              \
            SET_CELL_WILL_DISPLAY_SEL(TOK),                                                        \
            SET_CELL_ACCESSORY_SEL(TOK),                                                           \
            SET_CELL_CAN_EDIT_SEL(TOK),                                                            \
            SET_CELL_EDITING_STYLE_SEL(TOK),                                                       \
            SET_CELL_CAN_MOVE_SEL(TOK),                                                            \
        };                                                                                         \
        [TableViewControllerWithToolbar debugRegisterCellType:TOK                                  \
                                            standardSelectors:&standardvTable                      \
                                                      inClass:VTABLE_CLASS.class];                 \
    };                                                                                             \
    CELL_POP_SEL_WARNING;                                                                          \
    static const RowVTable CELL_VTABLE(TOK)

#else
#define CELL_STATIC_VTABLE(TOK) static const RowVTable CELL_VTABLE(TOK)
#endif // DEBUGLOGGING

#define CELL_MAP(TOK) [TOK] = &CELL_VTABLE(TOK)
#define CELL_PUSH(X) [self.navigationController pushViewController:(X) animated:YES]
#define CELL_POP()                                                                                 \
    do {                                                                                           \
        [self.navigationController popViewControllerAnimated:YES];                                 \
    } while (0)

#define CELL_PUSH_NO_SEL_WARNING                                                                   \
    _Pragma("clang diagnostic push");                                                              \
    _Pragma("clang diagnostic ignored \"-Wundeclared-selector\"")

#define CELL_POP_SEL_WARNING _Pragma("clang diagnostic pop")

// These macros define an unused variable just force the comppiler to check that the method exsits

#ifdef DEBUGLOGGING

// Two-level macro expansion is needed
#define CELL_CONCAT2(a, b) a##b
#define CELL_CONCAT(a, b) CELL_CONCAT2(a, b)

#define CELL_CHECK_HEIGHT_SEL(TOK)                                                                 \
    __attribute__((unused)) static SEL CELL_CONCAT(debug_height_, __LINE__) = CELL_HEIGHT_SEL(TOK)
#define CELL_CHECK_UPDATE_SEL(TOK)                                                                 \
    __attribute__((unused)) staticSEL CELL_CONCAT(debug_update_, __LINE__) = CELL_UPDATE_SEL(TOK)
#define CELL_CHECK_REG_SEL(REG)                                                                    \
    SEL __attribute__((unused)) static CELL_CONCAT(debug_reg_, __LINE__) = (REG)

#define CHECK_NO_SEL(F, S)                                                                         \
    CELL_PUSH_NO_SEL_WARNING;                                                                      \
    __attribute__((constructor)) static void CELL_CONCAT(F, __LINE__)(void) {                      \
        [TableViewControllerWithToolbar debugCheckSelMissing:VTABLE_CLASS.class sel:S vtable:nil]; \
    }                                                                                              \
    CELL_POP_SEL_WARNING

#else

#define CELL_CHECK_HEIGHT_SEL(TOK)
#define CELL_CHECK_UPDATE_SEL(TOK)
#define CELL_CHECK_REG_SEL(REG)
#define CHECK_NO_SEL(F, S)

#endif // DEBUGLOGGING

//--------------------------------------------------------------------------------------------------

// Generic cell creation macro that calls a method on the controller with additional
// arguments. This is enough for most cells to be created.
#define CALL_CELL_SELECT(TOK, REUSEID, REG, METHOD, HEIGHT, TEXT, ICON, ACC, SELSTYLE)             \
    CELL_UPDATE_METHOD(TOK) {                                                                      \
        [self METHOD:cell text:(TEXT)icon:(ICON)accessoryType:(ACC)selectionStyle:(SELSTYLE)];     \
    };                                                                                             \
    CELL_PUSH_NO_SEL_WARNING;                                                                      \
    CELL_STATIC_VTABLE(TOK){                                                                       \
        SET_CELL_UPDATE_SEL(TOK),                                                                  \
        SET_CELL_SELECT_SEL(TOK),                                                                  \
        SET_CELL_HEIGHT_SEL(HEIGHT),                                                               \
        .reuseId = (REUSEID),                                                                      \
        .selRegister = (REG),                                                                      \
    };                                                                                             \
    CELL_POP_SEL_WARNING;                                                                          \
    CELL_CHECK_HEIGHT_SEL(HEIGHT);                                                                 \
    CELL_SELECT_METHOD(TOK)

// Generic cell creation macro that calls a method on the controller with additional
// arguments. This is enough for most cells to be created.
#define CALL_CELL(TOK, REUSEID, REG, METHOD, HEIGHT, TEXT, ICON)                                   \
    CELL_UPDATE_METHOD(TOK) {                                                                      \
        [self METHOD:cell                                                                          \
                      text:(TEXT)icon:(ICON)accessoryType:UITableViewCellAccessoryNone             \
            selectionStyle:UITableViewCellSelectionStyleNone];                                     \
    };                                                                                             \
    CELL_STATIC_VTABLE(TOK){                                                                       \
        SET_CELL_UPDATE_SEL(TOK),                                                                  \
        SET_CELL_HEIGHT_SEL(HEIGHT),                                                               \
        .reuseId = (REUSEID),                                                                      \
        .selRegister = (REG),                                                                      \
    };

// A cell with no selector but a height and a config method. e.g. make a segement.
#define CREATE_CELL_WITH_CONFIG(TOK, REG, HEIGHT)                                                  \
    CELL_PUSH_NO_SEL_WARNING;                                                                      \
    CELL_STATIC_VTABLE(TOK){                                                                       \
        SET_CELL_CONFIG_SEL(TOK),                                                                  \
        SET_CELL_HEIGHT_SEL(HEIGHT),                                                               \
        .selRegister = (REG),                                                                      \
    };                                                                                             \
    CELL_POP_SEL_WARNING;                                                                          \
    CELL_CHECK_HEIGHT_SEL(HEIGHT);                                                                 \
    CELL_CHECK_REG_SEL(REG);                                                                       \
    CELL_CONFIG_METHOD(TOK)

//--------------------------------------------------------------------------------------------------
// A single line cell with a boxed icon that will change the text to attibuted text
#define MARKUP_CELL_SELECT(TOK, HEIGHT, TEXT, ICON, ACC)                                           \
    CALL_CELL_SELECT(TOK,                                                                          \
                     @"markup",                                                                    \
                     nil,                                                                          \
                     markupCell,                                                                   \
                     HEIGHT,                                                                       \
                     TEXT,                                                                         \
                     ICON,                                                                         \
                     ACC,                                                                          \
                     UITableViewCellSelectionStyleBlue)

// A large texted multi line cell with a boxed icon that will change the text to attributed text.
#define MULTI_CELL_SELECT(TOK, HEIGHT, TEXT, ICON, ACC, SELSTYLE)                                  \
    CALL_CELL_SELECT(TOK, @"multi", nil, multiLine, auto, TEXT, ICON, ACC, SELSTYLE)

// A large texted multi line cell with a boxed icon that will change the text to attributed text.
#define MULTI_CELL(TOK, HEIGHT, TEXT, ICON)                                                        \
    CALL_CELL(TOK, @"multi", nil, multiLine, auto, TEXT, ICON)

// A small texted multi line cell with a boxed icon that will change the text to attributed text.
#define PARA_CELL_SELECT(TOK, HEIGHT, TEXT, ICON, ACC, SELSTYLE)                                   \
    CALL_CELL_SELECT(TOK, @"para", nil, paraLine, auto, TEXT, ICON, ACC, SELSTYLE)

// A small texted multi line cell with a boxed icon that will change the text to attributed text.
#define PARA_CELL(TOK, TEXT, ICON) CALL_CELL(TOK, nil, nil, paraLine, auto, TEXT, ICON)

// A cell with a text view that will allow for links and stop IDs.
#define TEXT_CELL_SELECT(TOK, TEXT, ACC, SELSTYLE)                                                 \
    CALL_CELL_SELECT(TOK,                                                                          \
                     kTextViewLinkCellId,                                                          \
                     CELL_REG_SEL(TextViewLinkCell),                                               \
                     textCell,                                                                     \
                     auto,                                                                         \
                     TEXT,                                                                         \
                     nil,                                                                          \
                     ACC,                                                                          \
                     SELSTYLE)

#define TEXT_CELL(TOK, TEXT)                                                                       \
    CALL_CELL(TOK, kTextViewLinkCellId, CELL_REG_SEL(TextViewLinkCell), textCell, auto, TEXT, nil)

// A simple one-line cell with no markup and basic heights, color is mode aware text.
#define BASIC_CELL_SELECT(TOK, TEXT, ICON, ACC)                                                    \
    CALL_CELL_SELECT(TOK,                                                                          \
                     kSimpleId,                                                                    \
                     nil,                                                                          \
                     simpleCell,                                                                   \
                     basic,                                                                        \
                     TEXT,                                                                         \
                     ICON,                                                                         \
                     ACC,                                                                          \
                     UITableViewCellSelectionStyleBlue)

// A simple one-line cell with no markup and basic heights and no selection method needed
#define BASIC_CELL(TOK, TEXT, ICON) CALL_CELL(TOK, kSimpleId, nil, simpleCell, basic, TEXT, ICON)

// A narrow cell with grey text - used for the list of actions on an arrival or trip.
#define ACTION_CELL_SELECT(TOK, TEXT, ICON, ACC)                                                   \
    CALL_CELL_SELECT(TOK,                                                                          \
                     kActionCellId,                                                                \
                     nil,                                                                          \
                     actionCell,                                                                   \
                     narrow,                                                                       \
                     TEXT,                                                                         \
                     ICON,                                                                         \
                     ACC,                                                                          \
                     UITableViewCellSelectionStyleBlue)

// Complete link cell all-in one, will call the named link,
#define LINK_CELL(TOK, ICON, TITLE, NAMED_LINK)                                                    \
    CELL_CONFIG_METHOD(TOK) {                                                                      \
        LabelLinkCellWithIcon *cell = [LabelLinkCellWithIcon new];                                 \
        [cell updateWithBoxedIcon:ICON title:TITLE namedLink:NAMED_LINK alwaysSelectable:YES];     \
        return cell;                                                                               \
    }                                                                                              \
    CELL_STATIC_VTABLE(TOK) {                                                                      \
        SET_CELL_CONFIG_SEL(TOK), SET_CELL_SELECT_SEL(LabelLinkCellWithIcon),                      \
            SET_CELL_HEIGHT_SEL(auto),                                                             \
    }

// An link cell that does's really have a link - you provide the selector.
#define LINK_CELL_SELECT(TOK, ICON, TEXT)                                                          \
    CELL_CONFIG_METHOD(TOK) {                                                                      \
        LabelLinkCellWithIcon *cell = [LabelLinkCellWithIcon new];                                 \
        [cell updateWithBoxedIcon:ICON title:TEXT namedLink:nil alwaysSelectable:YES];             \
        return cell;                                                                               \
    }                                                                                              \
    CELL_PUSH_NO_SEL_WARNING;                                                                      \
    CELL_STATIC_VTABLE(TOK){                                                                       \
        SET_CELL_CONFIG_SEL(TOK),                                                                  \
        SET_CELL_SELECT_SEL(TOK),                                                                  \
        SET_CELL_HEIGHT_SEL(auto),                                                                 \
    };                                                                                             \
    CELL_POP_SEL_WARNING;                                                                          \
    CELL_SELECT_METHOD(TOK)

// The tip jar cell
#define CELL_TIP_JAR(TOK, height)                                                                  \
    CELL_STATIC_VTABLE(TOK){                                                                       \
        SET_CELL_CONFIG_SEL(tipJar),                                                               \
        SET_CELL_SELECT_SEL(tipJar),                                                               \
        SET_CELL_HEIGHT_SEL(height),                                                               \
    };

// Standard disclaimer cell
#define DISCLAIMER_CELL(TOK, XML, NONE)                                                            \
    CELL_CONFIG_METHOD(TOK) { return [self disclaimerCell:(XML) noResults:(NONE)]; }               \
    CELL_STATIC_VTABLE(TOK) {                                                                      \
        SET_CELL_CONFIG_SEL(TOK), SET_CELL_SELECT_SEL(disclaimer), SET_CELL_HEIGHT_SEL(auto),      \
    }

//--------------------------------------------------------------------------------------------------
// Create Virtual Table.
// TOK - is for VTable name, config method and select method
// HEIGHT is for height
#define STATIC_VTABLE_VCS_H(TOK, HEIGHT)                                                           \
    CELL_STATIC_VTABLE(TOK){                                                                       \
        SET_CELL_CONFIG_SEL(TOK),                                                                  \
        SET_CELL_SELECT_SEL(TOK),                                                                  \
        SET_CELL_HEIGHT_SEL(HEIGHT),                                                               \
    };                                                                                             \
    CHECK_NO_SEL(update, CELL_UPDATE_SEL(TOK));                                                    \
    CHECK_NO_SEL(reg, CELL_REG_SEL(TOK));                                                          \
    CHECK_NO_SEL(will, CELL_WILL_DISPLAY_SEL(TOK));                                                \
    CHECK_NO_SEL(can, CELL_CAN_EDIT_SEL(TOK));                                                     \
    CHECK_NO_SEL(edit, CELL_EDITING_STYLE_SEL(TOK));                                               \
    CHECK_NO_SEL(move, CELL_CAN_MOVE_SEL(TOK));                                                    \
    CHECK_NO_SEL(acc, CELL_ACCESSORY_SEL(TOK))

// Create Virtual Table.
// TOK - is for VTable name, config method and select method
// HEIGHT is for height
#define STATIC_VTABLE_VUS_H(TOK, HEIGHT)                                                           \
    CELL_STATIC_VTABLE(TOK){                                                                       \
        SET_CELL_UPDATE_SEL(TOK),                                                                  \
        SET_CELL_SELECT_SEL(TOK),                                                                  \
        SET_CELL_HEIGHT_SEL(HEIGHT),                                                               \
    };                                                                                             \
    CHECK_NO_SEL(update, CELL_CONFIG_SEL(TOK));                                                    \
    CHECK_NO_SEL(reg, CELL_REG_SEL(TOK));                                                          \
    CHECK_NO_SEL(will, CELL_WILL_DISPLAY_SEL(TOK));                                                \
    CHECK_NO_SEL(can, CELL_CAN_EDIT_SEL(TOK));                                                     \
    CHECK_NO_SEL(edit, CELL_EDITING_STYLE_SEL(TOK));                                               \
    CHECK_NO_SEL(move, CELL_CAN_MOVE_SEL(TOK));                                                    \
    CHECK_NO_SEL(acc, CELL_ACCESSORY_SEL(TOK))

// Create Virtual Table.
// TOK - is for vTable name, config method name
// HEIGHT is for height
// debug build checks there was not a select methid defined but unused.
#define STATIC_VTABLE_VC_H(TOK, HEIGHT)                                                            \
    CELL_STATIC_VTABLE(TOK){                                                                       \
        SET_CELL_CONFIG_SEL(TOK),                                                                  \
        SET_CELL_HEIGHT_SEL(HEIGHT),                                                               \
    };                                                                                             \
    CHECK_NO_SEL(select, CELL_SELECT_SEL(TOK));                                                    \
    CHECK_NO_SEL(update, CELL_UPDATE_SEL(TOK));                                                    \
    CHECK_NO_SEL(reg, CELL_REG_SEL(TOK));                                                          \
    CHECK_NO_SEL(will, CELL_WILL_DISPLAY_SEL(TOK));                                                \
    CHECK_NO_SEL(can, CELL_CAN_EDIT_SEL(TOK));                                                     \
    CHECK_NO_SEL(edit, CELL_EDITING_STYLE_SEL(TOK));                                               \
    CHECK_NO_SEL(move, CELL_CAN_MOVE_SEL(TOK));                                                    \
    CHECK_NO_SEL(acc, CELL_ACCESSORY_SEL(TOK))
//--------------------------------------------------------------------------------------------------

@class MKMapView;
@class Detour;
@class DetourTableViewCell;
@class Route;

@interface TableViewControllerWithToolbar<FilteredItemType>
    : ViewControllerBase <UITableViewDelegate,
                          UITableViewDataSource,
                          UISearchResultsUpdating,
                          UISearchControllerDelegate,
                          DeselectItemDelegate,
                          MKMapViewDelegate,
                          UISearchBarDelegate,
                          INUIAddVoiceShortcutViewControllerDelegate> {
    bool _reloadOnAppear;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, readonly) UITableViewStyle style;
@property (nonatomic, readonly) CGFloat basicRowHeight;
@property (nonatomic, readonly) CGFloat narrowRowHeight;
@property (nonatomic, readonly, copy) NSMutableArray *topViewData;
@property (nonatomic, readonly) CGFloat mapCellHeight;
@property (nonatomic, strong) NSMutableArray<FilteredItemType> *searchableItems;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) MKMapView *mapView;
@property bool backgroundRefresh;
@property bool enableSearch;

// Methods for storing an integer type for each row and
// section These can be used by tables to simplify the
// calculation of the structure of the table.   Not all tables
// need to use this but refactoring will make it simpler.
- (void)clearSectionMaps;
- (NSInteger)sectionType:(NSInteger)section;
- (NSInteger)rowType:(NSIndexPath *)index;
- (NSInteger)addSectionType:(NSInteger)type;
- (NSInteger)addSectionTypeWithRow:(NSInteger)type;
- (NSInteger)addRowType:(NSInteger)type;
- (NSInteger)addRowType:(NSInteger)type count:(NSInteger)count;
- (NSInteger)addRowTypes:(NSArray *)array;
- (NSInteger)sections;
- (void)clearSection:(NSInteger)section;
- (NSInteger)addRowType:(NSInteger)type forSectionType:(NSInteger)sectionType;
- (NSInteger)rowsInSection:(NSInteger)section;
- (NSInteger)rowsInLastSection;
- (NSInteger)firstSectionOfType:(NSInteger)type;
- (NSInteger)firstRowOfType:(NSInteger)type inSection:(NSInteger)section;
- (NSIndexPath *)firstIndexPathOfSectionType:(NSInteger)sectionType rowType:(NSInteger)rowType;
- (void)removeRowAtIndexPath:(NSIndexPath *)index;

- (void)showTipJar;

// Other methods
- (CGFloat)leftInset;
- (void)finishWithMapView;
- (UITableViewCell *)getMapCell:(NSString *)id
               withUserLocation:(bool)userLocation
                     completion:(void (^)(MKMapView *map))completion;
- (void)updateAnnotations:(MKMapView *)map;
- (UITableViewCell *)tableView:(UITableView *)tableView
       cellWithReuseIdentifier:(NSString *)resuseIdentifier;

// clang-format off
// uncrustify-off

#define CELL_CREATION_METHOD(X)                                                                    \
- (UITableViewCell *)X:(UITableViewCell *__nonnull)cell                                            \
                  text:(NSString *__nonnull)text                                                   \
                  icon:(BoxedIcon *__nullable)icon                                                 \
        accessoryType:(UITableViewCellAccessoryType)accType                                        \
        selectionStyle:(UITableViewCellSelectionStyle)selStyle

// clang-format on
// uncrustify-on

CELL_CREATION_METHOD(multiLine);
CELL_CREATION_METHOD(paraLine);

- (DetourTableViewCell *)detourCell:(Detour *)det
                              route:(Route *)route
                          indexPath:(NSIndexPath *)indexPath;

- (DetourTableViewCell *)detourCell:(Detour *)det
                              route:(Route *)route
                          indexPath:(NSIndexPath *)indexPath
                         showHeader:(bool)includeHeader
                          showRoute:(bool)showRoute;

- (UITableViewCell *)disclaimerCell:(TriMetXML *)xml noResults:(NSString *)noResults;

CELL_SELECT_METHOD(disclaimer);

- (UITableViewCell *)baseCell:(UITableViewCell *)cell
                    accessory:(UITableViewCellAccessoryType)accType
                    selection:(UITableViewCellSelectionStyle)selStyle;

- (void)addStreetcarTextToDisclaimerCell:(UITableViewCell *)cell
                                    text:(NSString *)text
                        trimetDisclaimer:(bool)trimetDisclaimer;
- (void)updateDisclaimerAccessibility:(UITableViewCell *)cell;
- (void)addTextToDisclaimerCell:(UITableViewCell *)cell text:(NSString *)text;
- (void)addTextToDisclaimerCell:(UITableViewCell *)cell
                           text:(NSString *)text
                          lines:(NSInteger)numberOfLines;
- (void)noNetworkDisclaimerCell:(UITableViewCell *)cell;
- (UITableViewCell *)disclaimerCell:(UITableView *)tableView;
- (void)recreateNewTable;
- (void)updateAccessibility:(UITableViewCell *)cell;
- (bool)canCallTriMet;
- (void)callTriMet;
- (NSMutableArray<FilteredItemType> *)filteredData:(UITableView *)table;
- (NSString *)stringToFilter:(NSObject *)i;
- (id)filteredObject:(id)i searchString:(NSString *)searchText index:(NSInteger)index;
- (void)iOS7workaroundPromptGap;
- (void)clearSelection;

- (void)detourAction:(Detour *)detour
          buttonType:(NSInteger)buttonType
           indexPath:(NSIndexPath *)ip
       reloadSection:(bool)reloadSection;
- (void)detourToggle:(Detour *)detour indexPath:(NSIndexPath *)ip reloadSection:(bool)reloadSection;
- (void)safeScrollToTop;

- (void)tableView:(UITableView *)table
    siriAlertsForRoute:(NSString *)routeName
           routeNumner:(NSString *)routeNumber;

// Virtual table calls
- (RowVTableTable)getvTable;
- (size_t)getvTableSize;
- (NSInteger)tableView:(UITableView *)tableView
          vTableOffset:(NSIndexPath *)indexPath
              extraOut:(id __autoreleasing *)extra;

+ (void)debugRegisterCellType:(NSInteger)type
            standardSelectors:(RowVTablePtrConst)sels
                      inClass:(Class)cls;
+ (NSMutableDictionary *)debugCellTypeStore;
+ (void)debugCheckSelMissing:(Class)cls sel:(SEL)selector vtable:(RowVTablePtrConst)vTable;
- (void)debugCheckCells;

CELL_HEIGHT_METHOD(basic);
CELL_HEIGHT_METHOD(narrow);
CELL_HEIGHT_METHOD(auto);
CELL_HEIGHT_METHOD(SegmentCell);
CELL_HEIGHT_METHOD(mapCell);
CELL_HEIGHT_METHOD(CellTextField);

CELL_CAN_EDIT_METHOD(yes);
CELL_SELECT_METHOD(LabelLinkCellWithIcon);
CELL_EDITING_STYLE_METHOD(delete);
CELL_EDITING_STYLE_METHOD(insert);

CELL_CAN_MOVE_METHOD(yes);

CELL_CONFIG_METHOD(default);
CELL_ACCESSORY_METHOD(default);
CELL_CAN_MOVE_METHOD(default);
CELL_SELECT_METHOD(default);
CELL_WILL_DISPLAY_METHOD(default);
CELL_CAN_EDIT_METHOD(default);
CELL_EDITING_STYLE_METHOD(default);
CELL_HEIGHT_METHOD(default);

CELL_CONFIG_METHOD(tipJar);
CELL_SELECT_METHOD(tipJar);

CELL_CREATION_METHOD(textCell);
CELL_CREATION_METHOD(markupCell);
CELL_CREATION_METHOD(simpleCell);
CELL_CREATION_METHOD(actionCell);

CELL_REG_METHOD(TextViewLinkCell);
CELL_REG_METHOD(DetourTableViewCell);
CELL_REG_METHOD(PickerCell);
CELL_REG_METHOD(DatePickerCell);

@end
