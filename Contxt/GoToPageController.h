//
//  GoToPageController.h
//  Contxt
//
//  Created by Young Hoo Kim on 12/17/11.
//  Copyright (c) 2011 Kim Young Hoo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GoToPageController : NSObject <NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate> {
    IBOutlet NSPanel *panel;
    IBOutlet NSTableView *pagesTableView;
    IBOutlet NSSearchField *searchField;
    NSArray *pages;
    NSArray *filteredPages;
    
    BOOL ignoreSelectionChange;
}

@property (nonatomic, readonly) NSArray *pages;

- (void)updateSearch:(NSString *)searchString;

@end
