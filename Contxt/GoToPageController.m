//
//  GoToPageController.m
//  Contxt
//
//  Created by Young Hoo Kim on 12/17/11.
//  Copyright (c) 2011 Kim Young Hoo. All rights reserved.
//

#import "GoToPageController.h"
#import "WikiStorage.h"
#import "NSString+Page.h"
#import "AppDelegate.h"

@implementation GoToPageController

- (void)dealloc {
    [pages release];
    [filteredPages release];
    [super dealloc];
}

- (NSArray *)pages {
    if (searchField.stringValue.length > 0) {
        return filteredPages;
    } 
    return pages;
}


- (void)awakeFromNib {
    NSMutableArray *pagesArray = [[[NSMutableArray alloc] init] autorelease];
    for (NSString *fileName in [WikiStorage sharedWikiStorage].files) {
        if ([[fileName pathExtension] isEqualToString:@"txt"]) {
            [pagesArray addObject: [fileName pageTitle]];
        }
    }
    pages = [[NSArray alloc] initWithArray:pagesArray];
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    ignoreSelectionChange = YES;
    AppDelegate *appDelegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    int row = 0;
    for (NSString *page in self.pages) {
        if ([page isEqualToString:[appDelegate.currentPage pageTitle]]) {
            [pagesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:YES];
        } else {
            [pagesTableView deselectRow:row];
        }
        row += 1;
    }
    ignoreSelectionChange = NO;
    [searchField becomeFirstResponder];
}

- (void)closeAndOpenWikiPage {
    NSUInteger selectedRow = pagesTableView.selectedRow;
    if (selectedRow == -1) {
        return;
    }
    NSString *page = [self.pages objectAtIndex:selectedRow];
    AppDelegate *appDelegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    [appDelegate openWikiPage:[NSString stringWithFormat:@"%@.txt", page] updateHistory:YES];
    [searchField setStringValue:@""];
    [pagesTableView reloadData];
    [panel close];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command {
    ignoreSelectionChange = YES;
    if ([control isEqual:searchField]) {
        if (command == @selector(moveDown:)) {
            NSUInteger selectedRow = pagesTableView.selectedRow;
            if (selectedRow >= ([self.pages count] - 1)) {
                return NO;
            }
            [pagesTableView deselectRow:selectedRow];
            selectedRow += 1;
            [pagesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:YES];
        }
        if (command == @selector(moveUp:)) {
            NSUInteger selectedRow = pagesTableView.selectedRow;
            if (selectedRow <= 0) {
                return NO;
            }
            [pagesTableView deselectRow:selectedRow];
            selectedRow -= 1;
            [pagesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:YES];            
        }
        if (command == @selector(insertNewline:)) {
            [self closeAndOpenWikiPage];
        }
    } 
    ignoreSelectionChange = NO;
    return NO;
}

- (void)updateSearch:(NSString *)searchString {
    ignoreSelectionChange = YES;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchString]; 
    [filteredPages autorelease];
    filteredPages = [[pages filteredArrayUsingPredicate:predicate] retain];
    [pagesTableView reloadData];
    ignoreSelectionChange = NO;
}


#pragma mark -
#pragma mark NSTableViewDelegate
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    if (ignoreSelectionChange == NO) {
        [self closeAndOpenWikiPage];
    }
}

#pragma mark- 
#pragma mark NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [self.pages count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return [self.pages objectAtIndex:rowIndex];
}

@end
